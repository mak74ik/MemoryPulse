import AppKit
import Darwin
import Foundation
import SwiftUI

@MainActor
public final class SystemMonitor: ObservableObject {
    public static let shared = SystemMonitor()

    @Published public var snapshot: MemorySnapshot = MemorySnapshot()
    @Published public var processes: [ProcessItem] = []
    @Published public var isRefreshing: Bool = false
    @Published public var lastPurgeFreedBytes: UInt64? = nil
    @Published public var totalCpuUsage: Double = 0.0

    private var timer: Timer?
    private var lastCpuTimes: [pid_t: (time: UInt64, timestamp: Date)] = [:]
    private var prevCpuTicks: (user: UInt32, sys: UInt32, idle: UInt32, nice: UInt32)?
    private var timebase: mach_timebase_info = {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        return tb
    }()

    private init() {
        refreshAll()
        startPolling()
    }

    public func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAll()
            }
        }
    }

    public func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    public func refreshAll() {
        updateTotalCpu()
        snapshot = fetchMemorySnapshot()
        processes = fetchProcesses()
    }

    // MARK: - Total Host CPU Load
    public func updateTotalCpu() {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return }

        let user = cpuLoad.cpu_ticks.0
        let sys = cpuLoad.cpu_ticks.1
        let idle = cpuLoad.cpu_ticks.2
        let nice = cpuLoad.cpu_ticks.3

        if let prev = prevCpuTicks {
            let deltaUser = user >= prev.user ? user - prev.user : 0
            let deltaSys = sys >= prev.sys ? sys - prev.sys : 0
            let deltaIdle = idle >= prev.idle ? idle - prev.idle : 0
            let deltaNice = nice >= prev.nice ? nice - prev.nice : 0
            let total = deltaUser + deltaSys + deltaIdle + deltaNice
            if total > 0 {
                let busy = deltaUser + deltaSys + deltaNice
                totalCpuUsage = min(max((Double(busy) / Double(total)) * 100.0, 0.0), 100.0)
            }
        }
        prevCpuTicks = (user, sys, idle, nice)
    }

    // MARK: - Darwin VM Memory Statistics
    public func fetchMemorySnapshot() -> MemorySnapshot {
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let hostPort = mach_host_self()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStat = vm_statistics64_data_t()

        let kerr = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }

        var pageSize: vm_size_t = 0
        host_page_size(hostPort, &pageSize)

        guard kerr == KERN_SUCCESS, pageSize > 0 else {
            return MemorySnapshot(totalBytes: totalRAM)
        }

        let uPageSize = UInt64(pageSize)
        let activeBytes = UInt64(vmStat.active_count) * uPageSize
        let inactiveBytes = UInt64(vmStat.inactive_count) * uPageSize
        let wiredBytes = UInt64(vmStat.wire_count) * uPageSize
        let freeBytes = UInt64(vmStat.free_count) * uPageSize
        let compressedBytes = UInt64(vmStat.compressor_page_count) * uPageSize

        // Memory pressure level via Darwin sysctl
        var pressureVal: Int32 = 1
        var pressureSize = MemoryLayout<Int32>.size
        var pressureLevel: MemoryPressureLevel = .normal
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureVal, &pressureSize, nil, 0) == 0 {
            switch pressureVal {
            case 2: pressureLevel = .warning
            case 4: pressureLevel = .critical
            default: pressureLevel = .normal
            }
        }

        // Swap statistics
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var swapUsedBytes: UInt64 = 0
        var swapTotalBytes: UInt64 = 0
        if sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0) == 0 {
            swapUsedBytes = UInt64(max(0, swapUsage.xsu_used))
            swapTotalBytes = UInt64(max(0, swapUsage.xsu_total))
        }

        return MemorySnapshot(
            totalBytes: totalRAM,
            activeBytes: activeBytes,
            inactiveBytes: inactiveBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            freeBytes: freeBytes,
            swapUsedBytes: swapUsedBytes,
            swapTotalBytes: swapTotalBytes,
            pressureLevel: pressureLevel
        )
    }

    // MARK: - Process Inspection via libproc & AppKit
    public func fetchProcesses() -> [ProcessItem] {
        var items: [ProcessItem] = []
        let runningApps = NSWorkspace.shared.runningApplications
        var appByPid: [pid_t: NSRunningApplication] = [:]
        for app in runningApps {
            appByPid[app.processIdentifier] = app
        }

        // 1. Get all system PIDs
        let maxPids = 2048
        var pids = [pid_t](repeating: 0, count: maxPids)
        let bytesUsed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(MemoryLayout<pid_t>.size * maxPids))
        guard bytesUsed > 0 else { return [] }
        let pidCount = Int(bytesUsed) / MemoryLayout<pid_t>.size

        let now = Date()
        var currentCpuTimes: [pid_t: (time: UInt64, timestamp: Date)] = [:]
        let cpuCoreCount = Double(max(1, ProcessInfo.processInfo.activeProcessorCount))

        for i in 0..<pidCount {
            let pid = pids[i]
            if pid <= 0 { continue }

            var taskInfo = proc_taskinfo()
            let infoSize = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, infoSize)
            guard result == infoSize else { continue }

            let residentMemory = UInt64(taskInfo.pti_resident_size)
            // Filter out 0 byte or zombie entries
            if residentMemory == 0 { continue }

            // Precise Apple Silicon & Intel CPU percentage calculation
            let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
            var cpuPct: Double = 0.0
            if let prev = lastCpuTimes[pid] {
                let deltaTicks = totalTime > prev.time ? totalTime - prev.time : 0
                let deltaNanos = Double(deltaTicks) * Double(timebase.numer) / Double(max(1, timebase.denom))
                let wallDelta = now.timeIntervalSince(prev.timestamp)
                let wallNanos = wallDelta * 1_000_000_000.0
                if wallNanos > 0 {
                    cpuPct = min(max((deltaNanos / wallNanos) * 100.0, 0.0), 100.0 * cpuCoreCount)
                }
            }
            currentCpuTimes[pid] = (time: totalTime, timestamp: now)

            // Name & Icon
            var name = ""
            var icon: NSImage? = nil
            var isGUI = false
            var bundleId: String? = nil
            var appPath: String? = nil
            var arch: String? = nil

            if let app = appByPid[pid] {
                isGUI = (app.activationPolicy == .regular)
                name = app.localizedName ?? ""
                icon = app.icon
                bundleId = app.bundleIdentifier
                appPath = app.bundleURL?.path
                arch = (app.executableArchitecture == NSBundleExecutableArchitectureARM64) ? "ARM64" : "x86_64"
            }

            if name.isEmpty {
                var nameBuf = [CChar](repeating: 0, count: 256)
                _ = proc_name(pid, &nameBuf, 256)
                name = String(cString: nameBuf)
            }

            if name.isEmpty {
                name = "Process \(pid)"
            }

            items.append(
                ProcessItem(
                    id: pid,
                    name: name,
                    bundleIdentifier: bundleId,
                    icon: icon,
                    residentMemoryBytes: residentMemory,
                    cpuPercentage: cpuPct,
                    isGUIApp: isGUI,
                    appPath: appPath,
                    architecture: arch
                )
            )
        }

        self.lastCpuTimes = currentCpuTimes

        // Sort primarily by memory descending
        return items.sorted { $0.residentMemoryBytes > $1.residentMemoryBytes }
    }

    // MARK: - Process Termination
    @discardableResult
    public func terminateProcess(pid: pid_t, force: Bool) -> Bool {
        // Trigger Apple Haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)

        if let app = NSRunningApplication(processIdentifier: pid) {
            if force {
                let ok = app.forceTerminate()
                if ok {
                    refreshAll()
                    return true
                }
            } else {
                let ok = app.terminate()
                if ok {
                    refreshAll()
                    return true
                }
            }
        }

        // Fallback to POSIX kill signal
        let sig = force ? SIGKILL : SIGTERM
        let res = kill(pid, sig)
        refreshAll()
        return (res == 0)
    }

    // MARK: - Terminate all inactive user apps
    public func terminateInactiveApps() -> Int {
        var closedCount = 0
        let myPid = ProcessInfo.processInfo.processIdentifier
        let activeAppPid = NSWorkspace.shared.frontmostApplication?.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            if app.activationPolicy == .regular &&
               app.processIdentifier != myPid &&
               app.processIdentifier != activeAppPid &&
               !app.isHidden {
                if app.terminate() {
                    closedCount += 1
                }
            }
        }
        refreshAll()
        return closedCount
    }
}

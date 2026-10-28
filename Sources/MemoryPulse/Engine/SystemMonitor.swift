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

    private var timer: Timer?
    private var lastCpuTimes: [pid_t: (time: UInt64, timestamp: Date)] = [:]

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
        snapshot = fetchMemorySnapshot()
        processes = fetchProcesses()
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

            // CPU percentage calculation
            let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
            var cpuPct: Double = 0.0
            if let prev = lastCpuTimes[pid] {
                let timeDelta = Double(totalTime.saturatingSubtract(prev.time)) / 1_000_000_000.0 // nanoseconds
                let wallDelta = now.timeIntervalSince(prev.timestamp)
                if wallDelta > 0.001 {
                    cpuPct = min(max((timeDelta / wallDelta) * 100.0, 0.0), 1000.0)
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

private extension UInt64 {
    func saturatingSubtract(_ other: UInt64) -> UInt64 {
        return self > other ? self - other : 0
    }
}

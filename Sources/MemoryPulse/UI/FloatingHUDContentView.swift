import AppKit
import SwiftUI

public enum ProcessSortField: String, CaseIterable, Identifiable {
    case memory = "memory"
    case cpu = "cpu"
    case name = "name"

    public var id: String { rawValue }
}

public enum ProcessFilterCategory: String, CaseIterable, Identifiable {
    case apps = "apps"
    case all = "all"
    case heavy = "heavy"

    public var id: String { rawValue }
}

public struct FloatingHUDContentView: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @ObservedObject var l10n = L10n.shared

    @AppStorage("skip_kill_confirmation") private var skipKillConfirmation: Bool = false
    @State private var dontAskAgainChecked: Bool = false
    @State private var pendingProcessToTerminate: ProcessItem? = nil

    @State private var searchText = ""
    @State private var filterCategory: ProcessFilterCategory = .apps
    @State private var sortField: ProcessSortField = .memory
    @State private var isAscending: Bool = false
    @State private var isPurging: Bool = false
    @State private var isSpinningRefresh: Bool = false
    @State private var bannerText: String? = nil

    public init() {}

    private var filteredAndSortedProcesses: [ProcessItem] {
        var list = monitor.processes

        // 1. Filter category
        switch filterCategory {
        case .apps:
            list = list.filter { $0.isGUIApp }
        case .all:
            break
        case .heavy:
            list = list.filter { $0.residentMemoryBytes >= 300 * 1024 * 1024 }
        }

        // 2. Search query
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                String($0.id).contains(q) ||
                ($0.bundleIdentifier?.lowercased().contains(q) ?? false)
            }
        }

        // 3. Sorting
        switch sortField {
        case .memory:
            list.sort { isAscending ? $0.residentMemoryBytes < $1.residentMemoryBytes : $0.residentMemoryBytes > $1.residentMemoryBytes }
        case .cpu:
            list.sort { isAscending ? $0.cpuPercentage < $1.cpuPercentage : $0.cpuPercentage > $1.cpuPercentage }
        case .name:
            list.sort {
                let comp = $0.name.localizedCaseInsensitiveCompare($1.name)
                return isAscending ? comp == .orderedAscending : comp == .orderedDescending
            }
        }

        return list
    }

    public var body: some View {
        ZStack {
            // Liquid Glass Ambient Backdrop with subtle breathing lights
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.10))
                    .blur(radius: 130)
                    .offset(x: -260, y: -180)

                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .blur(radius: 150)
                    .offset(x: 240, y: 200)

                VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (With spacious 78pt offset for macOS Traffic Lights)
                HStack(spacing: 12) {
                    // Traffic lights clear spacer
                    Color.clear.frame(width: 78, height: 32)

                    HStack(spacing: 8) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("MemoryPulse")
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                            Text(l10n.appSubtitle)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Right Controls Bar
                    HStack(spacing: 10) {
                        // Language Switcher (RU / EN)
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                if l10n.currentLanguage == .ru {
                                    l10n.currentLanguage = .en
                                } else {
                                    l10n.currentLanguage = .ru
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))
                                Text(l10n.isRu ? "RU" : "EN")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .help("Сменить язык / Switch Language")

                        // Memory Pressure Status Pill
                        HStack(spacing: 5) {
                            Circle()
                                .fill(monitor.snapshot.pressureLevel.color)
                                .frame(width: 7, height: 7)
                            Text(monitor.snapshot.pressureLevel.localized(isRu: l10n.isRu))
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(monitor.snapshot.pressureLevel.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(monitor.snapshot.pressureLevel.color.opacity(0.25), lineWidth: 0.5)
                        )
                        .cornerRadius(12)

                        // Dedicated Refresh Button with 360 Spin
                        Button {
                            triggerRefresh()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .rotationEffect(.degrees(isSpinningRefresh ? 360 : 0))
                                .padding(7)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(l10n.refreshTooltip)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                }
                .padding(.trailing, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)

                Divider()

                // Top Metrics Cards (RAM, Total CPU, Cache, Wired, Free, Swap)
                HStack(spacing: 9) {
                    MemoryStatCard(
                        title: l10n.metricUsed,
                        value: monitor.snapshot.format(monitor.snapshot.usedBytes),
                        subtitle: "\(Int(monitor.snapshot.usedPercentage))% \(l10n.metricUsedSub)",
                        icon: "chart.pie.fill",
                        tintColor: .blue
                    )

                    MemoryStatCard(
                        title: l10n.isRu ? "Нагрузка CPU" : "Total CPU",
                        value: String(format: "%.1f%%", monitor.totalCpuUsage),
                        subtitle: l10n.isRu ? "Все ядра системы" : "All system cores",
                        icon: "bolt.fill",
                        tintColor: monitor.totalCpuUsage > 30.0 ? .orange : .cyan
                    )

                    MemoryStatCard(
                        title: l10n.metricCache,
                        value: monitor.snapshot.format(monitor.snapshot.inactiveBytes),
                        subtitle: l10n.metricCacheSub,
                        icon: "shippingbox.fill",
                        tintColor: .cyan
                    )

                    MemoryStatCard(
                        title: l10n.metricWired,
                        value: monitor.snapshot.format(monitor.snapshot.wiredBytes),
                        subtitle: l10n.metricWiredSub,
                        icon: "lock.shield.fill",
                        tintColor: .purple
                    )

                    MemoryStatCard(
                        title: l10n.metricFree,
                        value: monitor.snapshot.format(monitor.snapshot.freeBytes),
                        subtitle: l10n.metricFreeSub,
                        icon: "sparkles",
                        tintColor: .green
                    )

                    if monitor.snapshot.swapTotalBytes > 0 {
                        MemoryStatCard(
                            title: l10n.metricSwap,
                            value: monitor.snapshot.format(monitor.snapshot.swapUsedBytes),
                            subtitle: "\(monitor.snapshot.format(monitor.snapshot.swapTotalBytes)) max",
                            icon: "externaldrive.fill",
                            tintColor: monitor.snapshot.swapUsedBytes > (512 * 1024 * 1024) ? .orange : .secondary
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Toolbar Controls Bar
                HStack(spacing: 12) {
                    // Search bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))

                        TextField(l10n.searchPlaceholder, text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .frame(maxWidth: 240)

                    // Filter category buttons
                    HStack(spacing: 4) {
                        filterButton(title: l10n.filterApps, category: .apps)
                        filterButton(title: l10n.filterAll, category: .all)
                        filterButton(title: l10n.filterHeavy, category: .heavy)
                    }
                    .padding(3)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(9)

                    Spacer()

                    // Apple Glowing Sort Pills ("Загораются" при выборе)
                    HStack(spacing: 6) {
                        Text(l10n.isRu ? "Сортировка:" : "Sort:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        sortPill(title: l10n.sortMemory, icon: "memorychip", field: .memory)
                        sortPill(title: l10n.sortCPU, icon: "bolt.fill", field: .cpu)
                        sortPill(title: l10n.sortName, icon: "textformat.abc", field: .name)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                Divider()

                // List Column Headers (Strict alignment with rows)
                HStack(spacing: 12) {
                    Text("\(l10n.headerProcess) (\(filteredAndSortedProcesses.count))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 160, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 42) // offset by icon + space

                    Text(l10n.isRu ? "CPU" : "CPU")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 75, alignment: .trailing)

                    Text(l10n.isRu ? "ПАМЯТЬ" : "RAM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 85, alignment: .trailing)

                    Text(l10n.headerActions)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.02))

                // Scrollable Process List
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if filteredAndSortedProcesses.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text(l10n.emptySearch)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 220)
                        } else {
                            ForEach(filteredAndSortedProcesses) { item in
                                ProcessRowView(item: item, totalMemory: monitor.snapshot.totalBytes) {
                                    handleRequestTerminate(item: item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }

                Divider()

                // Bottom Floating Action Dock
                HStack(spacing: 12) {
                    if let banner = bannerText {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.green)
                            Text(banner)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(7)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()

                    // Quit Inactive Apps
                    Button {
                        let count = monitor.terminateInactiveApps()
                        showBanner(l10n.isRu ? "Закрыто фоновых программ: \(count)" : "Closed background apps: \(count)")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.app")
                            Text(l10n.quitBackground)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    // Purge Cache Button with subtle glow
                    Button {
                        triggerPurge()
                    } label: {
                        HStack(spacing: 6) {
                            if isPurging {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "leaf.arrow.circlepath")
                            }
                            Text(isPurging ? l10n.purgingProgress : l10n.purgeButton)
                                .lineLimit(1)
                        }
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(isPurging)
                    .shadow(color: Color.blue.opacity(0.25), radius: 6, y: 2)
                    .keyboardShortcut("k", modifiers: .command)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.03))
            }

            // Confirmation Modal Sheet
            if let pending = pendingProcessToTerminate {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        if let icon = pending.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 44, height: 44)
                                .cornerRadius(9)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.isRu ? "Завершить процесс «\(pending.name)»?" : "Quit process “\(pending.name)” ?")
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(2)

                            Text(l10n.isRu
                                ? "Несохраненные данные могут быть потеряны. Память: \(pending.formattedMemory), PID: \(pending.id)."
                                : "Unsaved data may be lost. RAM: \(pending.formattedMemory), PID: \(pending.id).")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Checkbox "Больше не спрашивать"
                    Toggle(isOn: $dontAskAgainChecked) {
                        Text(l10n.isRu ? "Больше не спрашивать при закрытии" : "Don't ask again")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Action buttons
                    HStack(spacing: 10) {
                        Button(l10n.isRu ? "Отмена" : "Cancel") {
                            withAnimation(.spring(response: 0.25)) {
                                pendingProcessToTerminate = nil
                            }
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button(role: .destructive) {
                            confirmTerminate(item: pending, force: true)
                        } label: {
                            Text(l10n.isRu ? "Завершить принудительно" : "Force Quit")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            confirmTerminate(item: pending, force: false)
                        } label: {
                            Text(l10n.isRu ? "Завершить" : "Quit")
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(20)
                .frame(width: 440)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThickMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 24, y: 12)
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .frame(minWidth: 780, idealWidth: 840, minHeight: 520, idealHeight: 600)
    }

    // MARK: - Termination Logic
    private func handleRequestTerminate(item: ProcessItem) {
        if skipKillConfirmation {
            monitor.terminateProcess(pid: item.id, force: false)
            showBanner(l10n.isRu ? "Процесс \(item.name) завершен" : "Process \(item.name) quit")
        } else {
            dontAskAgainChecked = false
            withAnimation(.spring(response: 0.25)) {
                pendingProcessToTerminate = item
            }
        }
    }

    private func confirmTerminate(item: ProcessItem, force: Bool) {
        if dontAskAgainChecked {
            skipKillConfirmation = true
        }
        monitor.terminateProcess(pid: item.id, force: force)
        withAnimation(.spring(response: 0.25)) {
            pendingProcessToTerminate = nil
        }
        showBanner(l10n.isRu ? "Процесс \(item.name) завершен" : "Process \(item.name) terminated")
    }

    // MARK: - Glowing Apple Sort Pill Component
    @ViewBuilder
    private func sortPill(title: String, icon: String, field: ProcessSortField) -> some View {
        let isSelected = (sortField == field)

        Button {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                if sortField == field {
                    isAscending.toggle()
                } else {
                    sortField = field
                    isAscending = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .transition(.scale)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    if isSelected {
                        // Apple Illuminated Glow Background
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.28),
                                Color.cyan.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: Color.cyan.opacity(0.3), radius: 5, x: 0, y: 1)
                    } else {
                        Color.primary.opacity(0.04)
                            .cornerRadius(8)
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Button
    @ViewBuilder
    private func filterButton(title: String, category: ProcessFilterCategory) -> some View {
        let isSelected = (filterCategory == category)

        Button {
            withAnimation(.spring(response: 0.3)) {
                filterCategory = category
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(
                    isSelected
                        ? Color.primary.opacity(0.12)
                        : Color.clear
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions
    private func triggerRefresh() {
        withAnimation(.linear(duration: 0.6)) {
            isSpinningRefresh = true
        }
        monitor.refreshAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSpinningRefresh = false
        }
    }

    private func showBanner(_ text: String) {
        withAnimation(.spring()) {
            bannerText = text
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                bannerText = nil
            }
        }
    }

    private func triggerPurge() {
        guard !isPurging else { return }
        isPurging = true

        Task {
            let res = await MemoryPurgeEngine.shared.purgeMemory()
            withAnimation(.spring()) {
                isPurging = false
                if res.freedBytes > 0 {
                    let formatted = monitor.snapshot.format(res.freedBytes)
                    showBanner(l10n.isRu ? "Освобождено \(formatted) памяти!" : "Purged \(formatted) of RAM!")
                } else {
                    showBanner(l10n.isRu ? "Кэш системы оптимизирован!" : "Darwin kernel cache optimized!")
                }
            }
        }
    }
}

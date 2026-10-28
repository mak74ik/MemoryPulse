import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @ObservedObject var l10n = L10n.shared
    @State private var isPurging = false
    @State private var purgeMessage: String? = nil

    public var onOpenFullWindow: () -> Void

    public init(onOpenFullWindow: @escaping () -> Void) {
        self.onOpenFullWindow = onOpenFullWindow
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)

                    Text("MemoryPulse")
                        .font(.system(size: 14, weight: .bold))
                }

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(l10n.isRu ? "Выйти из программы" : "Quit MemoryPulse")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // Circular Memory Ring Gauge
            HStack(spacing: 16) {
                MemoryRingGauge(
                    percentage: monitor.snapshot.usedPercentage,
                    pressureLevel: monitor.snapshot.pressureLevel,
                    size: 100
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(monitor.snapshot.format(monitor.snapshot.usedBytes))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(l10n.isRu ? "из" : "of") \(monitor.snapshot.format(monitor.snapshot.totalBytes)) \(l10n.isRu ? "памяти" : "RAM")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Divider().padding(.vertical, 2)

                    HStack(spacing: 6) {
                        Text("\(l10n.isRu ? "Кэш" : "Cache"):")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(monitor.snapshot.format(monitor.snapshot.inactiveBytes))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 6) {
                        Text("\(l10n.isRu ? "Свободно" : "Free"):")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(monitor.snapshot.format(monitor.snapshot.freeBytes))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(monitor.snapshot.pressureLevel.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)

            // Purge feedback banner
            if let msg = purgeMessage {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.green)
                    Text(msg)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
                .transition(.scale.combined(with: .opacity))
            }

            // Quick Purge Button (Apple Action Style)
            Button {
                triggerPurge()
            } label: {
                HStack(spacing: 8) {
                    if isPurging {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "leaf.arrow.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    Text(isPurging ? l10n.purgingProgress : l10n.purgeButton)
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(9)
                .shadow(color: Color.blue.opacity(0.25), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(isPurging)
            .padding(.horizontal, 14)

            Divider()
                .padding(.horizontal, 14)

            // Top Memory Consumers
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(l10n.isRu ? "Главные потребители" : "Top Consumers")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Text(l10n.sortMemory)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)

                let topHogs = Array(monitor.processes.filter { $0.isGUIApp }.prefix(3))
                if topHogs.isEmpty {
                    Text(l10n.isRu ? "Нет активных приложений" : "No active user apps")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                } else {
                    VStack(spacing: 2) {
                        ForEach(topHogs) { item in
                            ProcessRowView(item: item, totalMemory: monitor.snapshot.totalBytes) { force in
                                monitor.terminateProcess(pid: item.id, force: force)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }

            Divider()
                .padding(.horizontal, 14)

            // Footer Navigation
            HStack {
                Button {
                    let closed = monitor.terminateInactiveApps()
                    if closed > 0 {
                        purgeMessage = l10n.isRu ? "Закрыто приложений: \(closed)" : "Closed apps: \(closed)"
                    }
                } label: {
                    Label(l10n.isRu ? "Закрыть фон" : "Quit Background", systemImage: "xmark.app")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button {
                    onOpenFullWindow()
                } label: {
                    HStack(spacing: 4) {
                        Text(l10n.isRu ? "Диспетчер" : "Task Studio")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 10))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 320)
        .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow))
    }

    private func triggerPurge() {
        guard !isPurging else { return }
        isPurging = true
        purgeMessage = nil

        Task {
            let result = await MemoryPurgeEngine.shared.purgeMemory()
            withAnimation(.spring()) {
                isPurging = false
                if result.freedBytes > 0 {
                    let freedStr = monitor.snapshot.format(result.freedBytes)
                    purgeMessage = "\(l10n.isRu ? "Освобождено:" : "Purged:") \(freedStr)!"
                } else {
                    purgeMessage = l10n.isRu ? "Кэш оптимизирован!" : "Cache optimized!"
                }
            }

            try? await Task.sleep(nanoseconds: 3_500_000_000)
            withAnimation {
                if purgeMessage != nil {
                    purgeMessage = nil
                }
            }
        }
    }
}

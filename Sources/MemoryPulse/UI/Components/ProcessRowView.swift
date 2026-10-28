import AppKit
import SwiftUI

public struct ProcessRowView: View {
    public let item: ProcessItem
    public let totalMemory: UInt64
    public let onTerminate: (Bool) -> Void // Bool is force

    @ObservedObject private var l10n = L10n.shared
    @State private var isHovering = false

    public init(item: ProcessItem, totalMemory: UInt64, onTerminate: @escaping (Bool) -> Void) {
        self.item = item
        self.totalMemory = totalMemory
        self.onTerminate = onTerminate
    }

    private var memoryFraction: Double {
        guard totalMemory > 0 else { return 0.0 }
        return Double(item.residentMemoryBytes) / Double(totalMemory)
    }

    public var body: some View {
        HStack(spacing: 12) {
            // App Icon with soft squircle shadow
            if let nsImage = item.icon {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .cornerRadius(7)
                    .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1.5)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 30, height: 30)

                    Image(systemName: item.isGUIApp ? "app.dashed" : "gearshape.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // Name & Architecture & PID
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let arch = item.architecture {
                        Text(arch == "ARM64" ? " Silicon" : "Intel")
                            .font(.system(size: 8.5, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(arch == "ARM64" ? Color.purple.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundColor(arch == "ARM64" ? Color.purple : Color.orange)
                            .cornerRadius(4)
                    }

                    if item.isGUIApp {
                        Text(l10n.isRu ? "Приложение" : "App")
                            .font(.system(size: 8.5, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.blue.opacity(0.14))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    Text("PID: \(item.id)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))

                    if let path = item.appPath {
                        Text(path)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // CPU Badge
            if item.cpuPercentage > 0.3 {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text(String(format: "%.1f%%", item.cpuPercentage))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    item.cpuPercentage > 15.0
                        ? Color.red.opacity(0.15)
                        : Color.orange.opacity(0.14)
                )
                .foregroundColor(item.cpuPercentage > 15.0 ? Color.red : Color.orange)
                .cornerRadius(6)
            }

            // Memory Usage Progress & Value
            VStack(alignment: .trailing, spacing: 3) {
                Text(item.formattedMemory)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 3.5)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * CGFloat(memoryFraction * 4.5), 3), height: 3.5)
                    }
                }
                .frame(width: 64, height: 3.5)
            }
            .frame(width: 80, alignment: .trailing)

            // Action Buttons
            HStack(spacing: 6) {
                // Gentle Quit
                Button {
                    onTerminate(false)
                } label: {
                    Text(l10n.quitGentle)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(l10n.isRu ? "Завершить приложение штатно" : "Quit application gracefully")

                // Force Quit
                Button {
                    onTerminate(true)
                } label: {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.red)
                        .padding(5)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(l10n.forceQuit)
            }
            .opacity(isHovering ? 1.0 : 0.65)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isHovering ? Color.primary.opacity(0.08) : Color.clear, lineWidth: 0.5)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        // Right-Click Context Menu
        .contextMenu {
            if let path = item.appPath {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                } label: {
                    Label(l10n.ctxShowInFinder, systemImage: "folder")
                }
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(item.id)", forType: .string)
            } label: {
                Label(l10n.ctxCopyPID, systemImage: "number")
            }

            if let path = item.appPath {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                } label: {
                    Label(l10n.ctxCopyPath, systemImage: "doc.on.doc")
                }
            }

            Divider()

            Button(role: .destructive) {
                onTerminate(false)
            } label: {
                Label(l10n.quitGentle, systemImage: "xmark.circle")
            }

            Button(role: .destructive) {
                onTerminate(true)
            } label: {
                Label(l10n.forceQuit, systemImage: "bolt.fill")
            }
        }
    }
}

import AppKit
import SwiftUI

public struct ProcessRowView: View {
    public let item: ProcessItem
    public let totalMemory: UInt64
    public let onSelectTerminate: () -> Void

    @ObservedObject private var l10n = L10n.shared
    @State private var isHovering = false

    public init(item: ProcessItem, totalMemory: UInt64, onSelectTerminate: @escaping () -> Void) {
        self.item = item
        self.totalMemory = totalMemory
        self.onSelectTerminate = onSelectTerminate
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
                    .frame(width: 28, height: 28)
                    .cornerRadius(6.5)
                    .shadow(color: Color.black.opacity(0.18), radius: 2.5, y: 1)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 28, height: 28)

                    Image(systemName: item.isGUIApp ? "app.dashed" : "gearshape.2.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            // Name & Architecture & PID (Guaranteed no letter wrapping)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let arch = item.architecture {
                        Text(arch == "ARM64" ? " Silicon" : "Intel")
                            .font(.system(size: 8.5, weight: .bold))
                            .lineLimit(1)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(arch == "ARM64" ? Color.purple.opacity(0.14) : Color.orange.opacity(0.14))
                            .foregroundColor(arch == "ARM64" ? Color.purple : Color.orange)
                            .cornerRadius(4)
                    }

                    if item.isGUIApp {
                        Text(l10n.isRu ? "App" : "App")
                            .font(.system(size: 8.5, weight: .bold))
                            .lineLimit(1)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    Text("PID: \(item.id)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.75))
                        .lineLimit(1)

                    if let path = item.appPath {
                        Text(path)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .frame(minWidth: 160, maxWidth: .infinity, alignment: .leading)

            // CPU Column (Always visible, accurately measured)
            HStack(spacing: 3) {
                if item.cpuPercentage >= 1.0 {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8.5))
                }

                Text(String(format: "%.1f%%", item.cpuPercentage))
                    .font(.system(size: 11, weight: item.cpuPercentage >= 1.0 ? .bold : .regular, design: .rounded))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                item.cpuPercentage >= 15.0
                    ? Color.red.opacity(0.15)
                    : (item.cpuPercentage >= 1.0 ? Color.orange.opacity(0.14) : Color.clear)
            )
            .foregroundColor(
                item.cpuPercentage >= 15.0
                    ? Color.red
                    : (item.cpuPercentage >= 1.0 ? Color.orange : Color.secondary.opacity(0.85))
            )
            .cornerRadius(5)
            .frame(width: 75, alignment: .trailing)

            // Memory Usage Column
            VStack(alignment: .trailing, spacing: 3) {
                Text(item.formattedMemory)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 3)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * CGFloat(memoryFraction * 4.5), 3), height: 3)
                    }
                }
                .frame(width: 60, height: 3)
            }
            .frame(width: 85, alignment: .trailing)

            // Action Column (Clear, unmistakable "Завершить" button)
            HStack {
                Button {
                    onSelectTerminate()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                        Text(l10n.quitGentle)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(l10n.isRu ? "Завершить процесс" : "Quit process")
            }
            .frame(width: 95, alignment: .trailing)
            .opacity(isHovering ? 1.0 : 0.7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
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
                onSelectTerminate()
            } label: {
                Label(l10n.quitGentle, systemImage: "xmark.circle")
            }
        }
    }
}

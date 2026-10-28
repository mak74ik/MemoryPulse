import AppKit
import Foundation

public struct ProcessItem: Identifiable, Sendable {
    public let id: pid_t
    public let name: String
    public let bundleIdentifier: String?
    public let icon: NSImage?
    public let residentMemoryBytes: UInt64
    public let cpuPercentage: Double
    public let isGUIApp: Bool
    public let appPath: String?
    public let architecture: String?

    public init(
        id: pid_t,
        name: String,
        bundleIdentifier: String? = nil,
        icon: NSImage? = nil,
        residentMemoryBytes: UInt64,
        cpuPercentage: Double = 0.0,
        isGUIApp: Bool = false,
        appPath: String? = nil,
        architecture: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.icon = icon
        self.residentMemoryBytes = residentMemoryBytes
        self.cpuPercentage = cpuPercentage
        self.isGUIApp = isGUIApp
        self.appPath = appPath
        self.architecture = architecture
    }

    public var formattedMemory: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(residentMemoryBytes))
    }
}

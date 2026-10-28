import Foundation
import SwiftUI

public enum MemoryPressureLevel: String, Sendable {
    case normal = "В норме"
    case warning = "Умеренная нагрузка"
    case critical = "Критическая"

    public func localized(isRu: Bool) -> String {
        switch self {
        case .normal: return isRu ? "В норме" : "Nominal"
        case .warning: return isRu ? "Умеренная нагрузка" : "Moderate"
        case .critical: return isRu ? "Критическая" : "Critical"
        }
    }

    public var color: Color {
        switch self {
        case .normal:
            return Color(red: 0.15, green: 0.85, blue: 0.55) // Apple Emerald Green
        case .warning:
            return Color(red: 1.0, green: 0.65, blue: 0.15)  // Amber Orange
        case .critical:
            return Color(red: 1.0, green: 0.25, blue: 0.35)  // Coral Red
        }
    }

    public var systemIcon: String {
        switch self {
        case .normal: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "flame.fill"
        }
    }
}

public struct MemorySnapshot: Sendable {
    public let totalBytes: UInt64
    public let activeBytes: UInt64
    public let inactiveBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    public let freeBytes: UInt64
    public let swapUsedBytes: UInt64
    public let swapTotalBytes: UInt64
    public let pressureLevel: MemoryPressureLevel

    public init(
        totalBytes: UInt64 = 0,
        activeBytes: UInt64 = 0,
        inactiveBytes: UInt64 = 0,
        wiredBytes: UInt64 = 0,
        compressedBytes: UInt64 = 0,
        freeBytes: UInt64 = 0,
        swapUsedBytes: UInt64 = 0,
        swapTotalBytes: UInt64 = 0,
        pressureLevel: MemoryPressureLevel = .normal
    ) {
        self.totalBytes = totalBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.freeBytes = freeBytes
        self.swapUsedBytes = swapUsedBytes
        self.swapTotalBytes = swapTotalBytes
        self.pressureLevel = pressureLevel
    }

    /// Used memory = Active + Wired + Compressed
    public var usedBytes: UInt64 {
        return activeBytes + wiredBytes + compressedBytes
    }

    /// Available memory = Free + Inactive (which macOS reclaims on demand)
    public var availableBytes: UInt64 {
        return freeBytes + inactiveBytes
    }

    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        let pct = Double(usedBytes) / Double(totalBytes) * 100.0
        return min(max(pct, 0.0), 100.0)
    }

    public func format(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

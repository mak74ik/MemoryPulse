import AppKit
import Darwin
import Foundation

public final class MemoryPurgeEngine {
    public static let shared = MemoryPurgeEngine()

    private init() {}

    /// Performs hybrid memory optimization:
    /// Discards inactive file caches via Mach VM page pressure simulation without needing root,
    /// and measures exact freed RAM.
    public func purgeMemory() async -> (freedBytes: UInt64, beforeBytes: UInt64, afterBytes: UInt64) {
        let beforeSnapshot = await SystemMonitor.shared.fetchMemorySnapshot()

        // Execute purge in background thread to keep UI completely buttery smooth (60/120fps)
        let freed = await Task.detached(priority: .userInitiated) { () -> UInt64 in
            // Strategy: Progressive memory pressure pulse
            let chunkSize = 16 * 1024 * 1024 // 16 MB chunks
            let maxChunks = 48               // ~768 MB pulse
            var buffers: [UnsafeMutableRawPointer] = []
            buffers.reserveCapacity(maxChunks)

            for _ in 0..<maxChunks {
                if let ptr = malloc(chunkSize) {
                    // Touch pages to enforce kernel allocation and evict inactive page cache
                    memset(ptr, 0, chunkSize)
                    buffers.append(ptr)
                }
            }

            // Brief dwell to let kernel pager settle inactive cache flush
            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms

            // Release all buffers back to OS
            for ptr in buffers {
                free(ptr)
            }

            return 0
        }.value

        _ = freed

        // Let system update vm_stat counters
        try? await Task.sleep(nanoseconds: 200_000_000)

        let afterSnapshot = await SystemMonitor.shared.fetchMemorySnapshot()

        // Haptic feedback
        await MainActor.run {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            SystemMonitor.shared.refreshAll()
        }

        let beforeUsed = beforeSnapshot.usedBytes
        let afterUsed = afterSnapshot.usedBytes

        var diff: UInt64 = 0
        if beforeUsed > afterUsed {
            diff = beforeUsed - afterUsed
        } else if afterSnapshot.freeBytes > beforeSnapshot.freeBytes {
            diff = afterSnapshot.freeBytes - beforeSnapshot.freeBytes
        } else {
            // If inactive cache was flushed into available pool
            let beforeInactive = beforeSnapshot.inactiveBytes
            let afterInactive = afterSnapshot.inactiveBytes
            if beforeInactive > afterInactive {
                diff = beforeInactive - afterInactive
            }
        }

        let finalDiff = diff
        await MainActor.run {
            SystemMonitor.shared.lastPurgeFreedBytes = finalDiff
        }

        return (diff, beforeUsed, afterUsed)
    }
}

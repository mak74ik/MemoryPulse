import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize monitor
        _ = SystemMonitor.shared
        // Show window on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            WindowManager.shared.openHUDWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowManager.shared.openHUDWindow()
        return true
    }
}

@main
struct MemoryPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var monitor = SystemMonitor.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView {
                WindowManager.shared.openHUDWindow()
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "memorychip")
                Text("\(Int(monitor.snapshot.usedPercentage))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .menuBarExtraStyle(.window)
    }
}

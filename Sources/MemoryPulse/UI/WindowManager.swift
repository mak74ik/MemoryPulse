import AppKit
import SwiftUI

@MainActor
public final class WindowManager: NSObject, NSWindowDelegate {
    public static let shared = WindowManager()

    private var hudWindow: NSWindow?

    private override init() {
        super.init()
    }

    public func openHUDWindow() {
        if let window = hudWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = FloatingHUDContentView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.contentViewController = hostingController
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: 680, height: 460)
        window.delegate = self

        self.hudWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        // Keeps window reference clean or lets it reopen
    }
}

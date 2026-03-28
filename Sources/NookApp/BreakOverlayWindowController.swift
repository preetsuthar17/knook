import AppKit
import NookKit
import SwiftUI

@MainActor
final class BreakOverlayWindowController {
    private var window: NSWindow?
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    func show(session: BreakSession) {
        let window = window ?? makeWindow()

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window.setFrame(screenFrame, display: true)

        let blurView = NSVisualEffectView(frame: screenFrame)
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.appearance = NSAppearance(named: .darkAqua)
        blurView.autoresizingMask = [.width, .height]

        let hostingView = NSHostingView(rootView: BreakOverlayView(model: model, session: session))
        hostingView.frame = screenFrame
        hostingView.autoresizingMask = [.width, .height]

        blurView.addSubview(hostingView)
        window.contentView = blurView
        window.alphaValue = 0
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        self.window = window

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                window.orderOut(nil)
            }
        })
    }

    var isVisible: Bool {
        window?.isVisible == true
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return window
    }
}

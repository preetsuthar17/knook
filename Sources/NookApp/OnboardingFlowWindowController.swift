import AppKit
import SwiftUI

@MainActor
final class OnboardingFlowWindowController {
    private var window: NSWindow?

    func show(onFinish: @escaping @MainActor (TimeInterval, TimeInterval) -> Void) {
        let window = window ?? makeWindow()

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window.setFrame(screenFrame, display: true)

        let blurView = NSVisualEffectView(frame: screenFrame)
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.appearance = NSAppearance(named: .darkAqua)
        blurView.autoresizingMask = [.width, .height]

        let flowView = OnboardingFlowView { workInterval, breakDuration in
            onFinish(workInterval, breakDuration)
        }
        let hostingView = NSHostingView(rootView: flowView)
        hostingView.frame = screenFrame
        hostingView.autoresizingMask = [.width, .height]

        blurView.addSubview(hostingView)
        window.contentView = blurView
        window.alphaValue = 0
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        self.window = window

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.6
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
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

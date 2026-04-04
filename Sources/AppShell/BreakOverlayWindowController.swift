import AppKit
import Core
import SwiftUI

@MainActor
final class BreakOverlayWindowController {
    private var window: NSWindow?
    private var isDismissing = false
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    func show(session: BreakSession) {
        if isDismissing, let window {
            OverlayWindowHelper.cancelAnimations(on: window)
            window.orderOut(nil)
            isDismissing = false
        }
        let window = window ?? OverlayWindowHelper.makeFullscreenWindow()
        self.window = window
        OverlayWindowHelper.presentOverlay(
            in: window,
            rootView: BreakOverlayView(model: model, session: session),
            fadeDuration: 0.5,
            timingFunction: .easeOut
        )
    }

    func hide() {
        guard let window else { return }
        isDismissing = true
        OverlayWindowHelper.dismissOverlay(window)
    }

    var isVisible: Bool {
        window?.isVisible == true
    }
}

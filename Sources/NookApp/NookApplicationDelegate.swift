import AppKit

@MainActor
final class NookApplicationDelegate: NSObject, NSApplicationDelegate {
    static var didFinishLaunchingHandler: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.didFinishLaunchingHandler?()
    }

    static func configureAppIcon(bundleURL: URL = Bundle.main.bundleURL) {
        guard shouldApplyRuntimeIcon(bundleURL: bundleURL),
              let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
              let iconImage = NSImage(contentsOf: iconURL)
        else {
            return
        }

            iconImage.size = NSSize(width: 128, height: 128)
            NSApplication.shared.applicationIconImage = iconImage
    }

    nonisolated static func shouldApplyRuntimeIcon(bundleURL: URL) -> Bool {
        bundleURL.pathExtension != "app"
    }
}

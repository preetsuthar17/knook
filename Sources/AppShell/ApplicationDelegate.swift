import AppKit
@preconcurrency import Combine
import SwiftUI

@MainActor
final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    let model: AppModel

    private let updateManager: any UpdateManaging
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?
    private var lastCloseDate: Date = .distantPast
    private var lastMenuBarContent: MenuBarLabelContent?

    override init() {
        let resolvedUpdateManager = GitHubReleaseUpdateManager()
        self.updateManager = resolvedUpdateManager
        self.model = AppModel(updateManager: resolvedUpdateManager)
        super.init()
    }

    init(
        model: AppModel,
        updateManager: any UpdateManaging
    ) {
        self.updateManager = updateManager
        self.model = model
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.configureAppIcon()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp])
        }

        let pop = NSPopover()
        pop.behavior = .applicationDefined
        pop.animates = false
        pop.contentViewController = NSHostingController(
            rootView: PopoverContentView(
                model: model,
                dismiss: { [weak self] in self?.closePopover() }
            )
        )
        popover = pop

        model.$appState
            .combineLatest(model.$launchPhase, model.$updateState)
            .sink { [weak self] appState, launchPhase, updateState in
                let content = MenuBarLabelFormatter.content(
                    launchPhase: launchPhase,
                    state: appState,
                    showsUpdateBadge: updateState.isAvailable
                )
                self?.updateStatusBarButton(content: content)
            }
            .store(in: &cancellables)

        model.handleAppDidFinishLaunching()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if Date().timeIntervalSince(lastCloseDate) < 0.25 { return }

        if popover.isShown {
            closePopover()
        } else {
            openPopover(relativeTo: button)
        }
    }

    private func openPopover(relativeTo button: NSStatusBarButton) {
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        installEventMonitor()
    }

    private func closePopover() {
        guard popover.isShown else { return }
        popover.performClose(nil)
        lastCloseDate = Date()
        removeEventMonitor()
    }

    private func installEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self else { return }
            if let button = self.statusItem.button,
               let buttonWindow = button.window
            {
                let localRect = button.convert(button.bounds, to: nil)
                let screenRect = buttonWindow.convertToScreen(localRect)
                let clickScreenPoint: NSPoint
                if let eventWindow = event.window {
                    clickScreenPoint = eventWindow.convertToScreen(
                        NSRect(origin: event.locationInWindow, size: .zero)
                    ).origin
                } else {
                    clickScreenPoint = event.locationInWindow
                }
                if screenRect.contains(clickScreenPoint) { return }
            }
            self.closePopover()
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func updateStatusBarButton(content: MenuBarLabelContent) {
        guard let button = statusItem.button else { return }
        guard content != lastMenuBarContent else { return }
        defer { lastMenuBarContent = content }

        let symbolImage = NSImage(
            systemSymbolName: content.symbolName,
            accessibilityDescription: content.accessibilityLabel
        )
        symbolImage?.isTemplate = true
        button.image = content.showsUpdateBadge ? badgedMenuBarImage(from: symbolImage) : symbolImage
        if let countdown = content.countdownText {
            button.title = countdown
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
        }
    }

    private func badgedMenuBarImage(from baseImage: NSImage?) -> NSImage? {
        guard let baseImage else { return nil }

        let badgeSize = NSSize(width: 7, height: 7)
        let image = NSImage(size: baseImage.size)
        image.lockFocus()
        defer { image.unlockFocus() }

        baseImage.draw(in: NSRect(origin: .zero, size: baseImage.size))

        let badgeRect = NSRect(
            x: max(baseImage.size.width - badgeSize.width - 1, 0),
            y: max(baseImage.size.height - badgeSize.height - 1, 0),
            width: badgeSize.width,
            height: badgeSize.height
        )
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()

        return image
    }

    static func configureAppIcon(bundleURL: URL = Bundle.main.bundleURL) {
        guard shouldApplyRuntimeIcon(bundleURL: bundleURL),
              let iconURL = resourceBundle.url(forResource: "AppIcon", withExtension: "png"),
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

    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle.main
        #endif
    }
}

@testable import AppShell
import Core
import XCTest

@MainActor
final class ApplicationDelegateTests: XCTestCase {
    func testUsesRuntimeIconOutsideAppBundle() {
        let bundleURL = URL(fileURLWithPath: "/tmp/knook", isDirectory: true)

        XCTAssertTrue(ApplicationDelegate.shouldApplyRuntimeIcon(bundleURL: bundleURL))
    }

    func testSkipsRuntimeIconInsideAppBundle() {
        let bundleURL = URL(fileURLWithPath: "/Applications/knook.app", isDirectory: true)

        XCTAssertFalse(ApplicationDelegate.shouldApplyRuntimeIcon(bundleURL: bundleURL))
    }

    func testUsesInjectedModelInstance() {
        let updateManager = NullUpdateManager()
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        try? store.save(.default)
        let model = AppModel(
            settingsStore: store,
            updateManager: updateManager,
            startsTimer: false,
            observesSystemEvents: false
        )

        let delegate = ApplicationDelegate(model: model, updateManager: updateManager)

        XCTAssertTrue(delegate.model === model)
    }
}

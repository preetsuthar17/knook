import Foundation
@preconcurrency import Combine
import Core
@testable import AppShell
import XCTest

@MainActor
final class AppModelUpdateTests: XCTestCase {
    private final class MockUpdateManager: UpdateManaging {
        private let stateSubject = CurrentValueSubject<UpdateState, Never>(.idle)
        private(set) var checkForUpdatesCallCount = 0
        private(set) var installAvailableUpdateCallCount = 0

        var statePublisher: AnyPublisher<UpdateState, Never> {
            stateSubject.eraseToAnyPublisher()
        }

        func emit(_ state: UpdateState) {
            stateSubject.send(state)
        }

        func checkForUpdates() {
            checkForUpdatesCallCount += 1
        }

        func installAvailableUpdate() {
            installAvailableUpdateCallCount += 1
        }
    }

    func testAvailableUpdatePublishesBannerState() {
        let updateManager = MockUpdateManager()
        let model = AppModel(
            settingsStore: try! makeStore(),
            updateManager: updateManager,
            startsTimer: false,
            observesSystemEvents: false
        )

        let releaseURL = URL(string: "https://example.com/releases/tag/v0.2.0")
        updateManager.emit(.available(version: "0.2.0", releaseURL: releaseURL))

        XCTAssertEqual(model.updateState, .available(version: "0.2.0", releaseURL: releaseURL))
    }

    func testDismissUpdateNoticeHidesBannerWithoutCallingUpdater() {
        let updateManager = MockUpdateManager()
        let model = AppModel(
            settingsStore: try! makeStore(),
            updateManager: updateManager,
            startsTimer: false,
            observesSystemEvents: false
        )

        updateManager.emit(.available(version: "0.2.0", releaseURL: nil))
        model.dismissUpdateNotice()

        XCTAssertEqual(model.updateState, .idle)
        XCTAssertEqual(updateManager.installAvailableUpdateCallCount, 0)
        XCTAssertEqual(updateManager.checkForUpdatesCallCount, 0)
    }

    func testInstallAvailableUpdateRoutesToUpdater() {
        let updateManager = MockUpdateManager()
        let model = AppModel(
            settingsStore: try! makeStore(),
            updateManager: updateManager,
            startsTimer: false,
            observesSystemEvents: false
        )

        updateManager.emit(.available(version: "0.2.0", releaseURL: nil))
        model.installAvailableUpdate()

        XCTAssertEqual(model.updateState, .installing)
        XCTAssertEqual(updateManager.installAvailableUpdateCallCount, 1)
    }

    func testCheckForUpdatesRoutesToUpdater() {
        let updateManager = MockUpdateManager()
        let model = AppModel(
            settingsStore: try! makeStore(),
            updateManager: updateManager,
            startsTimer: false,
            observesSystemEvents: false
        )

        model.checkForUpdates()

        XCTAssertEqual(updateManager.checkForUpdatesCallCount, 1)
    }

    private func makeStore() throws -> SettingsStore {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let store = SettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        try store.save(.default)
        return store
    }
}

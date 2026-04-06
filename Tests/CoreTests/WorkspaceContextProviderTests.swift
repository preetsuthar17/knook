import Foundation
@testable import Core
import XCTest

final class WorkspaceContextProviderTests: XCTestCase {
    private final class MockWorkspaceContextProvider: WorkspaceContextProviding {
        var currentSnapshot: WorkspaceContextSnapshot

        init(currentSnapshot: WorkspaceContextSnapshot) {
            self.currentSnapshot = currentSnapshot
        }

        func snapshot() -> WorkspaceContextSnapshot {
            currentSnapshot
        }
    }

    func testFullscreenPauseProviderReflectsFullscreenSnapshots() {
        let workspaceContextProvider = MockWorkspaceContextProvider(
            currentSnapshot: WorkspaceContextSnapshot(
                frontmostApplicationBundleIdentifier: "com.apple.Keynote",
                isFrontmostApplicationFullscreenFocused: true
            )
        )
        let provider = FullscreenPauseConditionProvider(
            workspaceContextProvider: workspaceContextProvider
        )

        XCTAssertTrue(provider.isPaused(at: Date()))
    }

    func testFullscreenPauseProviderIgnoresNonFullscreenSnapshots() {
        let workspaceContextProvider = MockWorkspaceContextProvider(
            currentSnapshot: WorkspaceContextSnapshot(
                frontmostApplicationBundleIdentifier: "com.apple.Safari",
                isFrontmostApplicationFullscreenFocused: false
            )
        )
        let provider = FullscreenPauseConditionProvider(
            workspaceContextProvider: workspaceContextProvider
        )

        XCTAssertFalse(provider.isPaused(at: Date()))
    }

    // MARK: - isNearFullscreen

    private let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)

    func testFullscreenWindowDetected() {
        let bounds = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        XCTAssertTrue(WorkspaceContextProvider.isNearFullscreen(bounds: bounds, within: screenFrame))
    }

    func testFullscreenWindowWithSmallDeltaDetected() {
        let bounds = CGRect(x: 0, y: 0, width: 1722, height: 1112)
        XCTAssertTrue(WorkspaceContextProvider.isNearFullscreen(bounds: bounds, within: screenFrame))
    }

    func testMaximizedWindowNotDetected() {
        // Maximized window: full width but ~25px shorter (menu bar gap)
        let bounds = CGRect(x: 0, y: 25, width: 1728, height: 1092)
        XCTAssertFalse(WorkspaceContextProvider.isNearFullscreen(bounds: bounds, within: screenFrame))
    }

    func testMaximizedWindowWithDockNotDetected() {
        // Maximized window with dock visible: shorter and narrower
        let bounds = CGRect(x: 80, y: 25, width: 1648, height: 1092)
        XCTAssertFalse(WorkspaceContextProvider.isNearFullscreen(bounds: bounds, within: screenFrame))
    }

    func testZeroScreenFrameReturnsFalse() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertFalse(WorkspaceContextProvider.isNearFullscreen(bounds: bounds, within: .zero))
    }

    // MARK: - MicrophoneActivePauseConditionProvider

    private final class MockMicrophoneStateChecker: MicrophoneStateChecking, @unchecked Sendable {
        var active: Bool
        init(active: Bool) { self.active = active }
        func isMicrophoneActive() -> Bool { active }
    }

    func testMicrophoneProviderReturnsTrueWhenMicIsActive() {
        let checker = MockMicrophoneStateChecker(active: true)
        let provider = MicrophoneActivePauseConditionProvider(stateChecker: checker)
        XCTAssertTrue(provider.isPaused(at: Date()))
    }

    func testMicrophoneProviderReturnsFalseWhenMicIsInactive() {
        let checker = MockMicrophoneStateChecker(active: false)
        let provider = MicrophoneActivePauseConditionProvider(stateChecker: checker)
        XCTAssertFalse(provider.isPaused(at: Date()))
    }

    func testMicrophoneProviderReflectsStateChanges() {
        let checker = MockMicrophoneStateChecker(active: false)
        let provider = MicrophoneActivePauseConditionProvider(stateChecker: checker)
        XCTAssertFalse(provider.isPaused(at: Date()))
        checker.active = true
        XCTAssertTrue(provider.isPaused(at: Date()))
    }

    func testSmartPauseSettingsDecodesWithoutMicrophoneKey() throws {
        let json = """
        {"pauseDuringFullscreenFocus": true}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SmartPauseSettings.self, from: json)
        XCTAssertTrue(decoded.pauseDuringFullscreenFocus)
        XCTAssertFalse(decoded.pauseDuringMicrophoneActive)
    }
}

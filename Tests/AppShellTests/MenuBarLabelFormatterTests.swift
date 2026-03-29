import Foundation
@testable import Core
@testable import AppShell
import XCTest

final class MenuBarLabelFormatterTests: XCTestCase {
    func testUsesBreakCountdownDuringActiveBreak() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let activeBreak = BreakSession(
            kind: .micro,
            startedAt: now,
            scheduledEnd: now.addingTimeInterval(20),
            message: "Rest your eyes",
            backgroundStyle: .dawn,
            skipAvailableAfter: now
        )
        let state = AppState(
            now: now,
            nextBreakDate: nil,
            activeBreak: activeBreak,
            isPaused: false,
            pauseReason: nil,
            statusText: "Short Break in progress (00:20 left)"
        )

        let content = MenuBarLabelFormatter.content(launchPhase: .ready, state: state)

        XCTAssertEqual(content.symbolName, "pause.circle.fill")
        XCTAssertEqual(content.countdownText, "00:20")
    }

    func testUsesNextBreakCountdownWhenScheduleIsActive() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let state = AppState(
            now: now,
            nextBreakDate: now.addingTimeInterval(5 * 60),
            activeBreak: nil,
            isPaused: false,
            pauseReason: nil,
            statusText: "Next break in 05:00"
        )

        let content = MenuBarLabelFormatter.content(launchPhase: .ready, state: state)

        XCTAssertEqual(content.symbolName, "hourglass")
        XCTAssertEqual(content.countdownText, "05:00")
    }

    func testKeepsWorkCountdownSymbolNearBreakStart() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let state = AppState(
            now: now,
            nextBreakDate: now.addingTimeInterval(45),
            activeBreak: nil,
            isPaused: false,
            pauseReason: nil,
            statusText: "Next break in 00:45"
        )

        let content = MenuBarLabelFormatter.content(launchPhase: .ready, state: state)

        XCTAssertEqual(content.symbolName, "hourglass")
        XCTAssertEqual(content.countdownText, "00:45")
    }

    func testUsesPausedIconWithoutFrozenTimer() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let state = AppState(
            now: now,
            nextBreakDate: now.addingTimeInterval(5 * 60),
            activeBreak: nil,
            isPaused: true,
            pauseReason: "Full-Screen Focus",
            statusText: "Paused by Full-Screen Focus"
        )

        let content = MenuBarLabelFormatter.content(launchPhase: .ready, state: state)

        XCTAssertEqual(content.symbolName, "pause.fill")
        XCTAssertNil(content.countdownText)
    }

    func testCarriesUpdateBadgeStateIntoMenuBarContent() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let state = AppState(
            now: now,
            nextBreakDate: now.addingTimeInterval(5 * 60),
            activeBreak: nil,
            isPaused: false,
            pauseReason: nil,
            statusText: "Next break in 05:00"
        )

        let content = MenuBarLabelFormatter.content(
            launchPhase: .ready,
            state: state,
            showsUpdateBadge: true
        )

        XCTAssertTrue(content.showsUpdateBadge)
        XCTAssertEqual(content.symbolName, "hourglass")
    }
}

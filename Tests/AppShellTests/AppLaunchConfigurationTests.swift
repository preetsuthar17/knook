@testable import AppShell
import XCTest

final class AppLaunchConfigurationTests: XCTestCase {
    func testPrefersKnookEnvironmentOverrides() {
        let configuration = AppLaunchConfiguration(environment: [
            "KNOOK_FORCE_ONBOARDING": "1",
            "KNOOK_WORK": "15",
            "KNOOK_BREAK": "7",
            "NOOK_FORCE_ONBOARDING": "0",
            "NOOK_WORK": "30",
            "NOOK_BREAK": "14",
        ])

        XCTAssertTrue(configuration.forceOnboarding)
        XCTAssertEqual(configuration.workIntervalOverride, 15)
        XCTAssertEqual(configuration.breakDurationOverride, 7)
    }

    func testFallsBackToLegacyNookEnvironmentOverrides() {
        let configuration = AppLaunchConfiguration(environment: [
            "NOOK_FORCE_ONBOARDING": "true",
            "NOOK_WORK": "20",
            "NOOK_BREAK": "5",
        ])

        XCTAssertTrue(configuration.forceOnboarding)
        XCTAssertEqual(configuration.workIntervalOverride, 20)
        XCTAssertEqual(configuration.breakDurationOverride, 5)
    }
}

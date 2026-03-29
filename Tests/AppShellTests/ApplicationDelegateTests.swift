@testable import AppShell
import XCTest

final class ApplicationDelegateTests: XCTestCase {
    func testUsesRuntimeIconOutsideAppBundle() {
        let bundleURL = URL(fileURLWithPath: "/tmp/knook", isDirectory: true)

        XCTAssertTrue(ApplicationDelegate.shouldApplyRuntimeIcon(bundleURL: bundleURL))
    }

    func testSkipsRuntimeIconInsideAppBundle() {
        let bundleURL = URL(fileURLWithPath: "/Applications/knook.app", isDirectory: true)

        XCTAssertFalse(ApplicationDelegate.shouldApplyRuntimeIcon(bundleURL: bundleURL))
    }
}

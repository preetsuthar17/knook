import Foundation
@testable import AppShell
import XCTest

@MainActor
final class GitHubReleaseUpdateManagerTests: XCTestCase {
    private final class MockReleaseFetcher: GitHubReleaseFetching, @unchecked Sendable {
        var result: Result<GitHubRelease, Error>

        init(result: Result<GitHubRelease, Error>) {
            self.result = result
        }

        func fetchLatestRelease() async throws -> GitHubRelease {
            try result.get()
        }
    }

    private struct MockBrewPathProvider: BrewPathProviding {
        let path: String?

        func brewPath() -> String? {
            path
        }
    }

    private final class MockExternalUpdateHandler: ExternalUpdateHandling, @unchecked Sendable {
        private(set) var terminalCommands: [String] = []
        private(set) var openedURLs: [URL] = []

        func openTerminal(with command: String) throws {
            terminalCommands.append(command)
        }

        func openURL(_ url: URL) {
            openedURLs.append(url)
        }
    }

    private struct StubError: LocalizedError {
        let description: String

        var errorDescription: String? {
            description
        }
    }

    func testNewerGitHubReleasePublishesAvailableState() async {
        let releaseURL = URL(string: "https://github.com/preetsuthar17/knook/releases/tag/v0.1.2")!
        let manager = makeManager(
            fetcher: MockReleaseFetcher(result: .success(.init(
                version: "v0.1.2",
                releaseURL: releaseURL,
                isDraft: false,
                isPrerelease: false
            )))
        )

        await manager.checkForUpdatesForTesting()

        XCTAssertEqual(manager.currentState, .available(version: "0.1.2", releaseURL: releaseURL))
    }

    func testSameVersionClearsToIdle() async {
        let manager = makeManager(
            fetcher: MockReleaseFetcher(result: .success(.init(
                version: "v0.1.1",
                releaseURL: URL(string: "https://github.com/preetsuthar17/knook/releases/tag/v0.1.1")!,
                isDraft: false,
                isPrerelease: false
            )))
        )

        await manager.checkForUpdatesForTesting()

        XCTAssertEqual(manager.currentState, .idle)
    }

    func testPrereleaseIsIgnored() async {
        let manager = makeManager(
            fetcher: MockReleaseFetcher(result: .success(.init(
                version: "v0.2.0-beta.1",
                releaseURL: URL(string: "https://github.com/preetsuthar17/knook/releases/tag/v0.2.0-beta.1")!,
                isDraft: false,
                isPrerelease: true
            )))
        )

        await manager.checkForUpdatesForTesting()

        XCTAssertEqual(manager.currentState, .idle)
    }

    func testMalformedFetchFailurePublishesErrorState() async {
        let manager = makeManager(
            fetcher: MockReleaseFetcher(result: .failure(StubError(description: "Bad payload")))
        )

        await manager.checkForUpdatesForTesting()

        guard case let .error(message) = manager.currentState else {
            return XCTFail("Expected error state")
        }
        XCTAssertTrue(message.contains("Bad payload"))
    }

    func testVersionComparisonStripsLeadingV() {
        XCTAssertTrue(GitHubReleaseUpdateManager.isVersion("v0.1.2", newerThan: "0.1.1"))
        XCTAssertFalse(GitHubReleaseUpdateManager.isVersion("0.1.2", newerThan: "0.1.2"))
        XCTAssertFalse(GitHubReleaseUpdateManager.isVersion("0.1.0", newerThan: "0.1.1"))
    }

    func testInstallAvailableUpdateUsesHomebrewCommandWhenBrewExists() async {
        let releaseURL = URL(string: "https://github.com/preetsuthar17/knook/releases/tag/v0.1.2")!
        let externalHandler = MockExternalUpdateHandler()
        let manager = makeManager(
            fetcher: MockReleaseFetcher(result: .success(.init(
                version: "v0.1.2",
                releaseURL: releaseURL,
                isDraft: false,
                isPrerelease: false
            ))),
            brewPathProvider: MockBrewPathProvider(path: "/opt/homebrew/bin/brew"),
            externalHandler: externalHandler
        )

        await manager.checkForUpdatesForTesting()

        manager.installAvailableUpdate()

        XCTAssertEqual(
            externalHandler.terminalCommands,
            [GitHubReleaseUpdateManager.homebrewUpdateCommand(using: "/opt/homebrew/bin/brew")]
        )
        XCTAssertTrue(externalHandler.openedURLs.isEmpty)
    }

    func testInstallAvailableUpdateOpensReleasePageWhenBrewIsMissing() async {
        let releaseURL = URL(string: "https://github.com/preetsuthar17/knook/releases/tag/v0.1.2")!
        let externalHandler = MockExternalUpdateHandler()
        let manager = makeManager(
            fetcher: MockReleaseFetcher(result: .success(.init(
                version: "v0.1.2",
                releaseURL: releaseURL,
                isDraft: false,
                isPrerelease: false
            ))),
            brewPathProvider: MockBrewPathProvider(path: nil),
            externalHandler: externalHandler
        )

        await manager.checkForUpdatesForTesting()

        manager.installAvailableUpdate()

        XCTAssertTrue(externalHandler.terminalCommands.isEmpty)
        XCTAssertEqual(externalHandler.openedURLs, [releaseURL])
    }

    private func makeManager(
        fetcher: any GitHubReleaseFetching,
        brewPathProvider: any BrewPathProviding = MockBrewPathProvider(path: nil),
        externalHandler: any ExternalUpdateHandling = MockExternalUpdateHandler()
    ) -> GitHubReleaseUpdateManager {
        return GitHubReleaseUpdateManager(
            releaseFetcher: fetcher,
            brewPathProvider: brewPathProvider,
            externalHandler: externalHandler,
            currentVersion: "0.1.1",
            automaticCheckInterval: 0,
            userDefaults: .standard,
            startsAutomaticChecks: false
        )
    }
}

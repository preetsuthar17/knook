import AppKit
@preconcurrency import Combine
import Foundation

enum UpdateState: Equatable {
    case idle
    case available(version: String, releaseURL: URL?)
    case installing
    case error(String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    var versionString: String? {
        if case let .available(version, _) = self {
            return version
        }
        return nil
    }

    var releasePageURL: URL? {
        if case let .available(_, releaseURL) = self {
            return releaseURL
        }
        return nil
    }

    var errorMessage: String? {
        if case let .error(message) = self {
            return message
        }
        return nil
    }
}

@MainActor
protocol UpdateManaging: AnyObject {
    var statePublisher: AnyPublisher<UpdateState, Never> { get }
    func checkForUpdates()
    func installAvailableUpdate()
}

@MainActor
final class NullUpdateManager: UpdateManaging {
    private let stateSubject = CurrentValueSubject<UpdateState, Never>(.idle)

    var statePublisher: AnyPublisher<UpdateState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func checkForUpdates() {
        stateSubject.send(.error("Update checks are unavailable for this build."))
    }

    func installAvailableUpdate() {
        stateSubject.send(.error("Update checks are unavailable for this build."))
    }
}

struct GitHubRelease: Equatable {
    let version: String
    let releaseURL: URL
    let isDraft: Bool
    let isPrerelease: Bool
}

protocol GitHubReleaseFetching: Sendable {
    func fetchLatestRelease() async throws -> GitHubRelease
}

protocol BrewPathProviding: Sendable {
    func brewPath() -> String?
}

protocol ExternalUpdateHandling: Sendable {
    func openTerminal(with command: String) throws
    func openURL(_ url: URL)
}

struct URLSessionGitHubReleaseFetcher: GitHubReleaseFetching {
    private let session: URLSession
    private let apiURL: URL

    init(
        session: URLSession = .shared,
        apiURL: URL = URL(string: "https://api.github.com/repos/preetsuthar17/knook/releases/latest")!
    ) {
        self.session = session
        self.apiURL = apiURL
    }

    func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("knook", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubReleaseError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw GitHubReleaseError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(GitHubLatestReleaseResponse.self, from: data)

        guard !decoded.tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GitHubReleaseError.missingTag
        }

        return GitHubRelease(
            version: decoded.tagName,
            releaseURL: decoded.htmlURL,
            isDraft: decoded.draft,
            isPrerelease: decoded.prerelease
        )
    }
}

struct DefaultBrewPathProvider: BrewPathProviding {
    func brewPath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
        ]

        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}

struct SystemExternalUpdateHandler: ExternalUpdateHandling {
    func openTerminal(with command: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e", "tell application \"Terminal\" to activate",
            "-e", "tell application \"Terminal\" to do script \(Self.appleScriptStringLiteral(command))",
        ]
        try process.run()
    }

    func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private static func appleScriptStringLiteral(_ string: String) -> String {
        "\"\(string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}

@MainActor
final class GitHubReleaseUpdateManager: UpdateManaging {
    private static let lastUpdateCheckDateKey = "io.github.preetsuthar17.knook.lastUpdateCheckDate"

    private let stateSubject = CurrentValueSubject<UpdateState, Never>(.idle)
    private let releaseFetcher: any GitHubReleaseFetching
    private let brewPathProvider: any BrewPathProviding
    private let externalHandler: any ExternalUpdateHandling
    private let currentVersion: String
    private let releasePageFallbackURL: URL
    private let automaticCheckInterval: TimeInterval
    private let userDefaults: UserDefaults
    private let nowProvider: () -> Date

    private var automaticCheckTimer: Timer?
    private var checkTask: Task<Void, Never>?
    private var availableRelease: GitHubRelease?

    var currentState: UpdateState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<UpdateState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init(
        releaseFetcher: any GitHubReleaseFetching = URLSessionGitHubReleaseFetcher(),
        brewPathProvider: any BrewPathProviding = DefaultBrewPathProvider(),
        externalHandler: any ExternalUpdateHandling = SystemExternalUpdateHandler(),
        currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0",
        releasePageFallbackURL: URL = URL(string: "https://github.com/preetsuthar17/knook/releases/latest")!,
        automaticCheckInterval: TimeInterval = 86_400,
        userDefaults: UserDefaults = .standard,
        nowProvider: @escaping () -> Date = Date.init,
        startsAutomaticChecks: Bool = true
    ) {
        self.releaseFetcher = releaseFetcher
        self.brewPathProvider = brewPathProvider
        self.externalHandler = externalHandler
        self.currentVersion = currentVersion
        self.releasePageFallbackURL = releasePageFallbackURL
        self.automaticCheckInterval = automaticCheckInterval
        self.userDefaults = userDefaults
        self.nowProvider = nowProvider

        if startsAutomaticChecks {
            performAutomaticCheckIfDue()
            scheduleAutomaticChecks()
        }
    }

    func checkForUpdates() {
        startUpdateCheck(trigger: .manual)
    }

    func checkForUpdatesForTesting() async {
        await performUpdateCheck(trigger: .manual)
    }

    func installAvailableUpdate() {
        guard let availableRelease else {
            stateSubject.send(.error("No update is currently available."))
            return
        }

        if let brewPath = brewPathProvider.brewPath() {
            do {
                try externalHandler.openTerminal(with: Self.homebrewUpdateCommand(using: brewPath))
                stateSubject.send(.installing)
            } catch {
                stateSubject.send(.error("Could not open Terminal for the Homebrew update. \(error.localizedDescription)"))
            }
            return
        }

        externalHandler.openURL(availableRelease.releaseURL)
        publishAvailableRelease(availableRelease)
    }

    private func performAutomaticCheckIfDue() {
        guard automaticCheckInterval > 0 else { return }

        let lastCheckDate = userDefaults.object(forKey: Self.lastUpdateCheckDateKey) as? Date
        guard lastCheckDate == nil || nowProvider().timeIntervalSince(lastCheckDate!) >= automaticCheckInterval else {
            return
        }

        startUpdateCheck(trigger: .automatic)
    }

    private func scheduleAutomaticChecks() {
        guard automaticCheckInterval > 0 else { return }

        let pollingInterval = min(automaticCheckInterval, 3_600)
        automaticCheckTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performAutomaticCheckIfDue()
            }
        }
    }

    private func startUpdateCheck(trigger: UpdateCheckTrigger) {
        userDefaults.set(nowProvider(), forKey: Self.lastUpdateCheckDateKey)
        checkTask?.cancel()
        checkTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performUpdateCheck(trigger: trigger)
        }
    }

    private func performUpdateCheck(trigger: UpdateCheckTrigger) async {
        do {
            let release = try await releaseFetcher.fetchLatestRelease()
            handleFetchedRelease(release)
        } catch is CancellationError {
            return
        } catch {
            handleFailedReleaseFetch(error, trigger: trigger)
        }
    }

    private func handleFetchedRelease(_ release: GitHubRelease) {
        guard !release.isDraft, !release.isPrerelease else {
            availableRelease = nil
            stateSubject.send(.idle)
            return
        }

        let normalizedRemoteVersion = Self.normalizedVersion(release.version)
        if Self.isVersion(normalizedRemoteVersion, newerThan: currentVersion) {
            let normalizedRelease = GitHubRelease(
                version: normalizedRemoteVersion,
                releaseURL: release.releaseURL,
                isDraft: release.isDraft,
                isPrerelease: release.isPrerelease
            )
            availableRelease = normalizedRelease
            publishAvailableRelease(normalizedRelease)
        } else {
            availableRelease = nil
            stateSubject.send(.idle)
        }
    }

    private func handleFailedReleaseFetch(_ error: any Error, trigger: UpdateCheckTrigger) {
        availableRelease = nil
        let prefix = trigger == .manual ? "Could not check for updates." : "Automatic update check failed."
        stateSubject.send(.error("\(prefix) \(error.localizedDescription)"))
    }

    private func publishAvailableRelease(_ release: GitHubRelease) {
        stateSubject.send(.available(version: release.version, releaseURL: release.releaseURL))
    }

    static func normalizedVersion(_ version: String) -> String {
        version.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^[vV]"#, with: "", options: .regularExpression)
    }

    static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let left = versionComponents(from: lhs)
        let right = versionComponents(from: rhs)
        let maxCount = max(left.count, right.count)

        for index in 0..<maxCount {
            let leftComponent = index < left.count ? left[index] : 0
            let rightComponent = index < right.count ? right[index] : 0

            if leftComponent != rightComponent {
                return leftComponent > rightComponent
            }
        }

        return false
    }

    static func homebrewUpdateCommand(using brewPath: String) -> String {
        let quotedBrewPath = shellQuoted(brewPath)
        return "\(quotedBrewPath) tap preetsuthar17/tap && \(quotedBrewPath) update && (\(quotedBrewPath) upgrade --cask knook || \(quotedBrewPath) install --cask knook); printf '\\nRelaunch knook after Homebrew finishes if it replaced the running app.\\n'"
    }

    private static func versionComponents(from version: String) -> [Int] {
        normalizedVersion(version)
            .split(separator: ".")
            .map { component in
                let digits = component.prefix { $0.isNumber }
                return Int(digits) ?? 0
            }
    }

    private static func shellQuoted(_ string: String) -> String {
        "'\(string.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
    }
}

private enum UpdateCheckTrigger {
    case automatic
    case manual
}

private enum GitHubReleaseError: LocalizedError {
    case invalidResponse
    case unexpectedStatusCode(Int)
    case missingTag

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "GitHub returned an invalid response."
        case let .unexpectedStatusCode(statusCode):
            return "GitHub returned HTTP \(statusCode)."
        case .missingTag:
            return "The latest GitHub release is missing a version tag."
        }
    }
}

private struct GitHubLatestReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft
        case prerelease
    }
}

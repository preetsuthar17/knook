import Foundation

struct AppLaunchConfiguration: Sendable, Equatable {
    let forceOnboarding: Bool
    /// Override work interval in seconds (e.g. KNOOK_WORK=10 for 10s)
    let workIntervalOverride: TimeInterval?
    /// Override break duration in seconds (e.g. KNOOK_BREAK=5 for 5s)
    let breakDurationOverride: TimeInterval?

    init(forceOnboarding: Bool = false, workIntervalOverride: TimeInterval? = nil, breakDurationOverride: TimeInterval? = nil) {
        self.forceOnboarding = forceOnboarding
        self.workIntervalOverride = workIntervalOverride
        self.breakDurationOverride = breakDurationOverride
    }

    init(environment: [String: String]) {
        self.forceOnboarding = Self.parseBoolean(
            environment["KNOOK_FORCE_ONBOARDING"] ?? environment["NOOK_FORCE_ONBOARDING"]
        )
        self.workIntervalOverride = Self.parseSeconds(
            environment["KNOOK_WORK"] ?? environment["NOOK_WORK"]
        )
        self.breakDurationOverride = Self.parseSeconds(
            environment["KNOOK_BREAK"] ?? environment["NOOK_BREAK"]
        )
    }

    static let current = AppLaunchConfiguration(environment: ProcessInfo.processInfo.environment)

    private static func parseBoolean(_ rawValue: String?) -> Bool {
        guard let normalized = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return false
        }

        switch normalized {
        case "1", "true", "yes":
            return true
        default:
            return false
        }
    }

    private static func parseSeconds(_ rawValue: String?) -> TimeInterval? {
        guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              let value = TimeInterval(raw), value > 0 else {
            return nil
        }
        return value
    }
}

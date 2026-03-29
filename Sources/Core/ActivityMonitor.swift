import AppKit
import Foundation

public protocol ActivityMonitoring: Sendable {
    var idleSeconds: TimeInterval { get }
}

public final class ActivityMonitor: ActivityMonitoring, @unchecked Sendable {
    public init() {}

    public var idleSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)
    }
}

public extension Notification.Name {
    static let knookSystemWillSleep = NSWorkspace.willSleepNotification
    static let knookSystemDidWake = NSWorkspace.didWakeNotification
}

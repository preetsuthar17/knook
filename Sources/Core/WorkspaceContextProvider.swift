import AppKit
import CoreAudio
import CoreGraphics
import Foundation

public struct WorkspaceContextSnapshot: Sendable, Equatable {
    public var frontmostApplicationBundleIdentifier: String?
    public var isFrontmostApplicationFullscreenFocused: Bool

    public init(
        frontmostApplicationBundleIdentifier: String?,
        isFrontmostApplicationFullscreenFocused: Bool
    ) {
        self.frontmostApplicationBundleIdentifier = frontmostApplicationBundleIdentifier
        self.isFrontmostApplicationFullscreenFocused = isFrontmostApplicationFullscreenFocused
    }
}

public protocol WorkspaceContextProviding: AnyObject {
    func snapshot() -> WorkspaceContextSnapshot
}

public final class WorkspaceContextProvider: WorkspaceContextProviding {
    private let workspace: NSWorkspace
    private let screenFrames: () -> [CGRect]
    private let windowInfoProvider: () -> [[String: Any]]

    public init(
        workspace: NSWorkspace = .shared,
        screenFrames: @escaping () -> [CGRect] = { NSScreen.screens.map(\.frame) },
        windowInfoProvider: @escaping () -> [[String: Any]] = {
            (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
        }
    ) {
        self.workspace = workspace
        self.screenFrames = screenFrames
        self.windowInfoProvider = windowInfoProvider
    }

    public func snapshot() -> WorkspaceContextSnapshot {
        guard let frontmostApplication = workspace.frontmostApplication else {
            return WorkspaceContextSnapshot(
                frontmostApplicationBundleIdentifier: nil,
                isFrontmostApplicationFullscreenFocused: false
            )
        }

        let bundleIdentifier = frontmostApplication.bundleIdentifier
        let processIdentifier = frontmostApplication.processIdentifier
        let fullscreenFocused = hasFullscreenWindow(
            processIdentifier: processIdentifier,
            screenFrames: screenFrames(),
            windowInfo: windowInfoProvider()
        )

        return WorkspaceContextSnapshot(
            frontmostApplicationBundleIdentifier: bundleIdentifier,
            isFrontmostApplicationFullscreenFocused: fullscreenFocused
        )
    }

    private func hasFullscreenWindow(
        processIdentifier: pid_t,
        screenFrames: [CGRect],
        windowInfo: [[String: Any]]
    ) -> Bool {
        guard !screenFrames.isEmpty else { return false }

        return windowInfo.contains { window in
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == processIdentifier,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let alpha = window[kCGWindowAlpha as String] as? Double,
                  alpha > 0.05,
                  let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary)
            else {
                return false
            }

            return screenFrames.contains { screenFrame in
                Self.isNearFullscreen(bounds: bounds, within: screenFrame)
            }
        }
    }

    static func isNearFullscreen(bounds: CGRect, within screenFrame: CGRect) -> Bool {
        guard screenFrame.width > 0, screenFrame.height > 0 else { return false }

        // Compare dimensions rather than positions to avoid AppKit↔CG coordinate
        // mismatches. A true fullscreen window matches the full screen size (including
        // the menu bar area), while a maximized window is 24+ px shorter.
        let maxDelta: CGFloat = 12.0
        return abs(bounds.width - screenFrame.width) <= maxDelta &&
            abs(bounds.height - screenFrame.height) <= maxDelta
    }
}

public final class FullscreenPauseConditionProvider: PauseConditionProvider, @unchecked Sendable {
    public let name = "Full-Screen Focus"
    private let workspaceContextProvider: any WorkspaceContextProviding

    public init(workspaceContextProvider: any WorkspaceContextProviding) {
        self.workspaceContextProvider = workspaceContextProvider
    }

    public func isPaused(at date: Date) -> Bool {
        _ = date
        return workspaceContextProvider.snapshot().isFrontmostApplicationFullscreenFocused
    }
}

public protocol MicrophoneStateChecking: Sendable {
    func isMicrophoneActive() -> Bool
}

public final class MicrophoneActivePauseConditionProvider: PauseConditionProvider, @unchecked Sendable {
    public let name = "Active Microphone"
    private let stateChecker: MicrophoneStateChecking

    public init(stateChecker: MicrophoneStateChecking = CoreAudioMicrophoneChecker()) {
        self.stateChecker = stateChecker
    }

    public func isPaused(at date: Date) -> Bool {
        _ = date
        return stateChecker.isMicrophoneActive()
    }
}

public final class CoreAudioMicrophoneChecker: MicrophoneStateChecking, @unchecked Sendable {
    public init() {}

    public func isMicrophoneActive() -> Bool {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        ) == noErr, deviceID != kAudioDeviceUnknown else {
            return false
        }

        var isRunning: UInt32 = 0
        var runningSize = UInt32(MemoryLayout<UInt32>.size)
        var runningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectGetPropertyData(
            deviceID, &runningAddress, 0, nil, &runningSize, &isRunning
        ) == noErr else {
            return false
        }

        return isRunning != 0
    }
}

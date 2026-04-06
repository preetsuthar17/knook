import Core
import SwiftUI

struct MenuBarLabelContent: Equatable {
    var symbolName: String
    var countdownText: String?
    var accessibilityLabel: String
    var showsUpdateBadge: Bool
}

enum MenuBarLabelFormatter {
    static func content(
        launchPhase: AppLaunchPhase,
        state: AppState,
        showsUpdateBadge: Bool = false
    ) -> MenuBarLabelContent {
        guard launchPhase == .ready else {
            return MenuBarLabelContent(
                symbolName: "pause.fill",
                countdownText: nil,
                accessibilityLabel: "knook",
                showsUpdateBadge: showsUpdateBadge
            )
        }

        if let activeBreak = state.activeBreak {
            return MenuBarLabelContent(
                symbolName: "pause.circle.fill",
                countdownText: state.countdownText,
                accessibilityLabel: "\(activeBreak.kind.title) in progress",
                showsUpdateBadge: showsUpdateBadge
            )
        }

        if state.isPaused {
            return MenuBarLabelContent(
                symbolName: "pause.fill",
                countdownText: state.pauseReason,
                accessibilityLabel: state.pauseReason ?? "Paused",
                showsUpdateBadge: showsUpdateBadge
            )
        }

        if state.nextBreakDate != nil {
            return MenuBarLabelContent(
                symbolName: "hourglass",
                countdownText: state.countdownText,
                accessibilityLabel: "Next break countdown",
                showsUpdateBadge: showsUpdateBadge
            )
        }

        return MenuBarLabelContent(
            symbolName: "pause.fill",
            countdownText: nil,
            accessibilityLabel: state.statusText,
            showsUpdateBadge: showsUpdateBadge
        )
    }
}

struct MenuBarLabelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let content = MenuBarLabelFormatter.content(
            launchPhase: model.launchPhase,
            state: model.appState,
            showsUpdateBadge: model.updateState.isAvailable
        )

        HStack(spacing: 12) {
            Image(systemName: content.symbolName)

            if let countdownText = content.countdownText {
                Text(countdownText)
                    .monospacedDigit()
            }
        }
        .help(model.appState.statusText)
        .accessibilityLabel(content.accessibilityLabel)
    }
}

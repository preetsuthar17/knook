import AppKit
import NookKit
import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if model.menuBarMode == .setup {
            setupMenu
        } else {
            activeMenu
        }
    }

    private var setupMenu: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nook")
                .font(.title3.weight(.semibold))

            Text("Start with the recommended setup or adjust it before you begin.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            Button("Start Using Nook") {
                model.dismissStarterSetupWithDefaults()
            }
            .keyboardShortcut(.defaultAction)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var activeMenu: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.appState.activeBreak?.kind.title ?? "Nook")
                .font(.title3.weight(.semibold))

            Text(model.appState.statusText)
                .font(.callout)
                .foregroundStyle(.secondary)

            if let nextBreakDate = model.appState.nextBreakDate, model.appState.activeBreak == nil {
                LabeledContent("Next break", value: nextBreakDate.formatted(date: .omitted, time: .shortened))
                LabeledContent(
                    "Countdown",
                    value: max(nextBreakDate.timeIntervalSince(model.appState.now), 0).countdownString
                )
            }

            if model.appState.activeBreak != nil, let countdownText = model.appState.countdownText {
                LabeledContent(
                    "Remaining",
                    value: countdownText
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button("Start Break Now") {
                    model.startBreakNow()
                }
                .keyboardShortcut("b")

                Button("Postpone 5 Minutes") {
                    model.postpone(minutes: 5)
                }

                Button("Postpone 15 Minutes") {
                    model.postpone(minutes: 15)
                }

                Button(model.appState.isPaused ? "Resume Reminders" : "Pause Reminders") {
                    model.pauseOrResume()
                }

                if model.appState.activeBreak != nil {
                    Button("Skip Current Break") {
                        model.skipCurrentBreak()
                    }

                    Button("End Break Early") {
                        model.endBreakEarly()
                    }
                }

                Button("Open Settings") {
                    if #available(macOS 14, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}

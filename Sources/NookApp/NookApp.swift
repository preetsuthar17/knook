import SwiftUI

@main
struct NookApp: App {
    @NSApplicationDelegateAdaptor(NookApplicationDelegate.self) private var appDelegate
    @StateObject private var model: AppModel

    init() {
        NookApplicationDelegate.configureAppIcon()
        let model = AppModel()
        _model = StateObject(wrappedValue: model)
        NookApplicationDelegate.didFinishLaunchingHandler = { [weak model] in
            model?.handleAppDidFinishLaunching()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(model: model)
        } label: {
            menuBarLabel
        }

        Settings {
            SettingsView(model: model)
        }
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if let countdownText = model.appState.countdownText, model.launchPhase == .ready {
            Text(countdownText)
                .monospacedDigit()
        } else {
            MenuBarIcon()
        }
    }
}

private struct MenuBarIcon: View {
    var body: some View {
        Image(systemName: "pause.fill")
    }
}

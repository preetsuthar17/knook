import Core
import SwiftUI

enum AppVersion {
    static let current: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.9"
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case breaks = "Breaks"
    case schedule = "Schedule"
    case appearance = "Appearance"
    case wellness = "Wellness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "gearshape.fill"
        case .breaks: "clock.fill"
        case .schedule: "calendar"
        case .appearance: "paintbrush.fill"
        case .wellness: "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: .blue
        case .breaks: .orange
        case .schedule: .green
        case .appearance: .purple
        case .wellness: .pink
        }
    }
}

private struct SidebarIcon: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background {
                RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                    .fill(color.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                    )
            }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            VStack {
                List(SettingsTab.allCases, selection: $selectedTab) { tab in
                    Label {
                        Text(tab.rawValue)
                    } icon: {
                        SidebarIcon(systemImage: tab.icon, color: tab.color)
                    }
                    .tag(tab)
                }
                .listStyle(.sidebar)

                Spacer()

                Text("v\(AppVersion.current)")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 12)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 180, max: 200)
        } detail: {
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsPane(model: model)
                case .breaks:
                    BreaksSettingsPane(model: model)
                case .schedule:
                    ScheduleSettingsPane(model: model)
                case .appearance:
                    AppearanceSettingsPane(model: model)
                case .wellness:
                    WellnessSettingsPane(model: model)
                }
            }
            .frame(minWidth: 380, idealWidth: 420)
        }
        .toolbar(content: { ToolbarItem { EmptyView() } })
        .toolbar(.hidden)
    }
}

private struct GeneralSettingsPane: View {
    @ObservedObject var model: AppModel

    private var idleMinutes: Binding<Double> {
        Binding(
            get: { model.settings.scheduleSettings.idleResetThreshold / 60 },
            set: { newValue in
                model.settings.scheduleSettings.idleResetThreshold = newValue * 60
                model.saveSettings()
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { model.settings.scheduleSettings.launchAtLogin },
                    set: { newValue in
                        model.settings.scheduleSettings.launchAtLogin = newValue
                        model.saveSettings()
                    }
                ))
            } footer: {
                Text("Launch knook automatically when you log in.")
            }

            Section {
                Toggle("Pause during fullscreen apps", isOn: Binding(
                    get: { model.settings.smartPauseSettings.pauseDuringFullscreenFocus },
                    set: { newValue in
                        model.settings.smartPauseSettings.pauseDuringFullscreenFocus = newValue
                        model.saveSettings()
                    }
                ))

                Toggle("Pause during calls", isOn: Binding(
                    get: { model.settings.smartPauseSettings.pauseDuringMicrophoneActive },
                    set: { newValue in
                        model.settings.smartPauseSettings.pauseDuringMicrophoneActive = newValue
                        model.saveSettings()
                    }
                ))
            } footer: {
                Text("Automatically pause break reminders during fullscreen apps or when your microphone is in use.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Idle reset threshold")
                        Spacer()
                        Text("\(Int(idleMinutes.wrappedValue)) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: idleMinutes, in: 1...15, step: 1)
                }
            } footer: {
                Text("Reset the break timer after this much idle time.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

private struct BreaksSettingsPane: View {
    @ObservedObject var model: AppModel

    private var workMinutes: Binding<Double> {
        Binding(
            get: { model.settings.breakSettings.workInterval / 60 },
            set: { newValue in
                model.settings.breakSettings.workInterval = newValue * 60
                model.saveSettings()
            }
        )
    }

    private var breakSeconds: Binding<Double> {
        Binding(
            get: { model.settings.breakSettings.microBreakDuration },
            set: { newValue in
                model.settings.breakSettings.microBreakDuration = newValue
                model.saveSettings()
            }
        )
    }

    private var longBreakMinutes: Binding<Double> {
        Binding(
            get: { model.settings.breakSettings.longBreakDuration / 60 },
            set: { newValue in
                model.settings.breakSettings.longBreakDuration = newValue * 60
                model.saveSettings()
            }
        )
    }

    private var longBreakCadence: Binding<Int> {
        Binding(
            get: { model.settings.breakSettings.longBreakCadence },
            set: { newValue in
                model.settings.breakSettings.longBreakCadence = newValue
                model.saveSettings()
            }
        )
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Work duration")
                        Spacer()
                        Text("\(Int(workMinutes.wrappedValue)) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: workMinutes, in: 10...90, step: 5)
                }
            } footer: {
                Text("How long you work before a break reminder appears.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Break duration")
                        Spacer()
                        Text("\(Int(breakSeconds.wrappedValue)) sec")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: breakSeconds, in: 10...120, step: 5)
                }
            } footer: {
                Text("How long the break overlay stays on screen.")
            }

            Section {
                Picker("Skip policy", selection: Binding(
                    get: { model.settings.breakSettings.skipPolicy },
                    set: { newValue in
                        model.settings.breakSettings.skipPolicy = newValue
                        model.saveSettings()
                    }
                )) {
                    ForEach(SkipPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Allow ending breaks early", isOn: Binding(
                    get: { model.settings.breakSettings.allowEarlyEnd },
                    set: { newValue in
                        model.settings.breakSettings.allowEarlyEnd = newValue
                        model.saveSettings()
                    }
                ))
            } footer: {
                Text("Casual: skip anytime. Balanced: skip after 8 seconds. Hardcore: no skipping.")
            }

            Section {
                Toggle("Long breaks", isOn: Binding(
                    get: { model.settings.breakSettings.longBreaksEnabled },
                    set: { newValue in
                        model.settings.breakSettings.longBreaksEnabled = newValue
                        model.saveSettings()
                    }
                ))

                if model.settings.breakSettings.longBreaksEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Long break duration")
                            Spacer()
                            Text("\(Int(longBreakMinutes.wrappedValue)) min")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: longBreakMinutes, in: 1...15, step: 1)
                    }

                    Stepper(value: longBreakCadence, in: 2...10) {
                        HStack {
                            Text("Every")
                            Text("\(longBreakCadence.wrappedValue) breaks")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text("Periodically take a longer break instead of a micro break.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Breaks")
    }
}

private struct AppearanceSettingsPane: View {
    @ObservedObject var model: AppModel

    private static func previewSound(_ sound: BreakSound) {
        switch sound {
        case .none: break
        case .breeze: NSSound(named: "Submarine")?.play()
        case .glass: NSSound(named: "Glass")?.play()
        case .hero: NSSound(named: "Hero")?.play()
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Break sound", selection: Binding(
                    get: { model.settings.breakSettings.selectedSound },
                    set: { newValue in
                        model.settings.breakSettings.selectedSound = newValue
                        model.saveSettings()
                        Self.previewSound(newValue)
                    }
                )) {
                    ForEach(BreakSound.allCases) { sound in
                        Text(sound.rawValue.capitalized).tag(sound)
                    }
                }
            } footer: {
                Text("Sound played when a break starts.")
            }

            Section {
                let selected = model.settings.breakSettings.backgroundStyle
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(BreakBackgroundStyle.allCases) { style in
                        let isSelected = style == selected
                        Button {
                            model.settings.breakSettings.backgroundStyle = style
                            model.saveSettings()
                        } label: {
                            VStack(spacing: 6) {
                                BreakBackgroundView(style: style)
                                    .frame(height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                                    )

                                Text(style.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(isSelected ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Background style")
            } footer: {
                Text("Visual theme for the break overlay.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance")
    }
}

private struct ScheduleSettingsPane: View {
    @ObservedObject var model: AppModel

    private var hasOfficeHours: Bool {
        !model.settings.scheduleSettings.officeHours.isEmpty
    }

    private var hasSuggestions: Bool {
        model.activityLogStore.hasEnoughData()
    }

    var body: some View {
        Form {
            Section {
                if hasOfficeHours {
                    ForEach(model.settings.scheduleSettings.officeHours) { rule in
                        HStack {
                            Text(weekdayName(rule.weekday))
                                .frame(width: 50, alignment: .leading)
                            Text("\(formatTime(rule.startMinutes)) \u{2013} \(formatTime(rule.endMinutes))")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Clear office hours") {
                        model.clearOfficeHours()
                    }
                } else if hasSuggestions {
                    Text("knook has learned your work pattern.")
                        .foregroundStyle(.secondary)

                    Button("Apply suggested hours") {
                        model.applySuggestedOfficeHours()
                    }
                } else {
                    Text("knook is learning when you work. Check back in a few days.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Office Hours")
            } footer: {
                Text("When office hours are set, break reminders only run during those times.")
            }
        }
        .formStyle(.grouped)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else { return "?" }
        return symbols[weekday - 1]
    }

    private func formatTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = h
        components.minute = m
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

private struct WellnessSettingsPane: View {
    @ObservedObject var model: AppModel

    private var postureMinutes: Binding<Double> {
        Binding(
            get: { model.settings.wellnessSettings.posture.interval / 60 },
            set: { newValue in
                model.settings.wellnessSettings.posture.interval = newValue * 60
                model.saveSettings()
            }
        )
    }

    private var blinkMinutes: Binding<Double> {
        Binding(
            get: { model.settings.wellnessSettings.blink.interval / 60 },
            set: { newValue in
                model.settings.wellnessSettings.blink.interval = newValue * 60
                model.saveSettings()
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Posture reminders", isOn: Binding(
                    get: { model.settings.wellnessSettings.posture.isEnabled },
                    set: { newValue in
                        model.settings.wellnessSettings.posture.isEnabled = newValue
                        model.saveSettings()
                    }
                ))

                if model.settings.wellnessSettings.posture.isEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Interval")
                            Spacer()
                            Text("\(Int(postureMinutes.wrappedValue)) min")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: postureMinutes, in: 5...60, step: 5)
                    }

                    Picker("Delivery", selection: Binding(
                        get: { model.settings.wellnessSettings.posture.deliveryStyle },
                        set: { newValue in
                            model.settings.wellnessSettings.posture.deliveryStyle = newValue
                            model.saveSettings()
                        }
                    )) {
                        Text("Panel").tag(WellnessDeliveryStyle.panel)
                        Text("Notification").tag(WellnessDeliveryStyle.notification)
                    }
                    .pickerStyle(.segmented)
                }
            } footer: {
                Text("Gentle reminders to check your posture.")
            }

            Section {
                Toggle("Blink reminders", isOn: Binding(
                    get: { model.settings.wellnessSettings.blink.isEnabled },
                    set: { newValue in
                        model.settings.wellnessSettings.blink.isEnabled = newValue
                        model.saveSettings()
                    }
                ))

                if model.settings.wellnessSettings.blink.isEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Interval")
                            Spacer()
                            Text("\(Int(blinkMinutes.wrappedValue)) min")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: blinkMinutes, in: 5...30, step: 5)
                    }

                    Picker("Delivery", selection: Binding(
                        get: { model.settings.wellnessSettings.blink.deliveryStyle },
                        set: { newValue in
                            model.settings.wellnessSettings.blink.deliveryStyle = newValue
                            model.saveSettings()
                        }
                    )) {
                        Text("Panel").tag(WellnessDeliveryStyle.panel)
                        Text("Notification").tag(WellnessDeliveryStyle.notification)
                    }
                    .pickerStyle(.segmented)
                }
            } footer: {
                Text("Reminders to blink and rest your eyes.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Wellness")
    }
}

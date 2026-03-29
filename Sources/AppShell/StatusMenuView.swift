import AppKit
import Core
import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var model: AppModel
    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if shouldShowUpdateBanner {
                updateBanner
                Divider().padding(.vertical, 4)
            }

            if model.menuBarMode == .setup {
                setupMenu
            } else {
                activeMenu
            }
        }
    }

    @ViewBuilder
    private var updateBanner: some View {
        switch model.updateState {
        case let .available(version, releaseURL):
            VStack(alignment: .leading, spacing: 10) {
                Text("knook \(version) is available")
                    .font(.headline)

                Text("Update with Homebrew or open the latest GitHub release if Homebrew is unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button("Update") {
                        model.installAvailableUpdate()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Later") {
                        model.dismissUpdateNotice()
                    }
                    .buttonStyle(.bordered)

                    if let releaseURL {
                        Link("View Release", destination: releaseURL)
                            .font(.footnote)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
        case let .error(message):
            VStack(alignment: .leading, spacing: 8) {
                Text("Update check failed")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button("Try Again") {
                        model.checkForUpdates()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Dismiss") {
                        model.dismissUpdateNotice()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
        default:
            EmptyView()
        }
    }

    private var shouldShowUpdateBanner: Bool {
        switch model.updateState {
        case .available, .error:
            true
        default:
            false
        }
    }

    private var setupMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Start with the recommended setup or adjust it before you begin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider().padding(.vertical, 4)

            PopoverMenuRow(title: "Start Using knook", systemImage: "play.fill") {
                model.dismissStarterSetupWithDefaults()
                dismiss()
            }

            PopoverMenuRow(title: "Check for Updates", systemImage: "arrow.down.circle") {
                model.checkForUpdates()
                dismiss()
            }

            Divider().padding(.vertical, 4)

            PopoverMenuRow(title: "Quit", systemImage: "power", isLast: true) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 8)
    }

    private var activeMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.appState.statusText)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider().padding(.vertical, 4)

            PopoverMenuRow(title: "Start Break Now", systemImage: "cup.and.saucer") {
                model.startBreakNow()
                dismiss()
            }

            PopoverMenuRow(title: "Postpone 5 Minutes", systemImage: "clock.arrow.circlepath") {
                model.postpone(minutes: 5)
                dismiss()
            }

            PopoverMenuRow(title: "Postpone 15 Minutes", systemImage: "clock.arrow.circlepath") {
                model.postpone(minutes: 15)
                dismiss()
            }

            PopoverMenuRow(
                title: model.appState.isPaused ? "Resume Reminders" : "Pause Reminders",
                systemImage: model.appState.isPaused ? "play.circle" : "pause.circle"
            ) {
                model.pauseOrResume()
                dismiss()
            }

            if model.appState.activeBreak != nil {
                PopoverMenuRow(title: "Skip Current Break", systemImage: "forward.end") {
                    model.skipCurrentBreak()
                    dismiss()
                }

                PopoverMenuRow(title: "End Break Early", systemImage: "stop.circle") {
                    model.endBreakEarly()
                    dismiss()
                }
            }

            PopoverMenuRow(title: "Open Settings", systemImage: "gearshape") {
                model.openSettings()
                dismiss()
            }

            PopoverMenuRow(title: "Check for Updates", systemImage: "arrow.down.circle") {
                model.checkForUpdates()
                dismiss()
            }

            Divider().padding(.vertical, 4)

            PopoverMenuRow(title: "Quit", systemImage: "power", isLast: true) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 8)
    }
}

private struct PopoverMenuRow: View {
    let title: String
    let systemImage: String?
    let isLast: Bool
    let action: () -> Void
    @State private var isHovered = false

    init(title: String, systemImage: String? = nil, isLast: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isLast = isLast
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                        .frame(width: 20)
                }
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isHovered ? .white : .black)
        .background(isHovered ? Color.accentColor : .clear)
        .clipShape(MenuRowShape(topRadius: 4, bottomRadius: isLast ? 12 : 4))
        .onHover { isHovered = $0 }
    }
}

private struct MenuRowShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let tr = topRadius
        let br = bottomRadius
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tr, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + tr), radius: tr)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - br, y: rect.maxY), radius: br)
        path.addLine(to: CGPoint(x: rect.minX + br, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - br), radius: br)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tr))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + tr, y: rect.minY), radius: tr)
        path.closeSubpath()
        return path
    }
}

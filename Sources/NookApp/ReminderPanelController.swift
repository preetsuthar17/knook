import AppKit
import SwiftUI

@MainActor
final class ReminderPanelController {
    private var panel: NSPanel?
    private weak var model: AppModel?

    init(model: AppModel) {
        self.model = model
    }

    func show(nextBreakDate: Date) {
        let panel = panel ?? makePanel()
        panel.contentView = NSHostingView(rootView: ReminderPanelView(nextBreakDate: nextBreakDate, model: model))
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
    }

    var isVisible: Bool {
        panel?.isVisible == true
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        panel.setFrameOrigin(NSPoint(x: frame.maxX - 360, y: frame.maxY - 220))
        return panel
    }
}

private struct ReminderPanelView: View {
    let nextBreakDate: Date
    let model: AppModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Almost time")
                .font(.headline)
            Text("Your next break starts at \(nextBreakDate.formatted(date: .omitted, time: .shortened)).")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Start now") {
                    model?.startBreakNow()
                }

                Button("+5 min") {
                    model?.postpone(minutes: 5)
                }

                Button("Skip") {
                    model?.skipCurrentBreak()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(8)
    }
}

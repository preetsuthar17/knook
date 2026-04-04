import Core
import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var model: AppModel
    let session: BreakSession
    @State private var contentVisible = false

    private var remainingText: String {
        model.appState.countdownText ?? "00:00"
    }

    var body: some View {
        ZStack {
            BreakBackgroundView(style: session.backgroundStyle)

            VStack(spacing: 20) {
                Text(session.kind.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Text(session.message)
                    .font(.system(size: 42, weight: .semibold))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 600)

                Text("Break ends in \(remainingText)")
                    .font(.system(size: 17, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 14) {
                    if model.settings.breakSettings.allowEarlyEnd {
                        Button("End Early") {
                            model.endBreakEarly()
                        }
                        .buttonStyle(OverlayButtonStyle(filled: true))
                    }

                    Button("Skip") {
                        model.skipCurrentBreak()
                    }
                    .buttonStyle(OverlayButtonStyle(filled: false))
                }
                .padding(.top, 8)
            }
            .offset(y: contentVisible ? 0 : 20)
            .opacity(contentVisible ? 1 : 0)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                contentVisible = true
            }
        }
    }
}

private struct RGB {
    let r: Double, g: Double, b: Double

    func blend(to other: RGB, t: Double) -> RGB {
        RGB(
            r: r + (other.r - r) * t,
            g: g + (other.g - g) * t,
            b: b + (other.b - b) * t
        )
    }

    var color: Color { Color(red: r, green: g, blue: b) }
}

private struct TimePalette {
    let top: RGB
    let bottom: RGB
    let orb1: RGB
    let orb2: RGB
}

private func timeBlend(hour: Int, minute: Int) -> (index: Int, t: Double) {
    let h = Double(hour) + Double(minute) / 60.0
    switch h {
    case 6..<12: return (0, (h - 6) / 6)
    case 12..<17: return (1, (h - 12) / 5)
    case 17..<21: return (2, (h - 17) / 4)
    default: return (3, h >= 21 ? (h - 21) / 9 : (h + 3) / 9)
    }
}

private func palette(for style: BreakBackgroundStyle, date: Date) -> TimePalette {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: date)
    let minute = cal.component(.minute, from: date)
    let (index, t) = timeBlend(hour: hour, minute: minute)

    let palettes: [TimePalette]
    switch style {
    case .dawn:
        palettes = [

            TimePalette(top: RGB(r: 0.45, g: 0.18, b: 0.15), bottom: RGB(r: 0.55, g: 0.28, b: 0.18), orb1: RGB(r: 0.6, g: 0.3, b: 0.2), orb2: RGB(r: 0.5, g: 0.2, b: 0.25)),

            TimePalette(top: RGB(r: 0.5, g: 0.25, b: 0.12), bottom: RGB(r: 0.6, g: 0.35, b: 0.15), orb1: RGB(r: 0.65, g: 0.4, b: 0.15), orb2: RGB(r: 0.55, g: 0.25, b: 0.1)),

            TimePalette(top: RGB(r: 0.4, g: 0.12, b: 0.1), bottom: RGB(r: 0.5, g: 0.18, b: 0.1), orb1: RGB(r: 0.55, g: 0.2, b: 0.12), orb2: RGB(r: 0.4, g: 0.1, b: 0.15)),

            TimePalette(top: RGB(r: 0.2, g: 0.06, b: 0.1), bottom: RGB(r: 0.3, g: 0.08, b: 0.12), orb1: RGB(r: 0.35, g: 0.1, b: 0.15), orb2: RGB(r: 0.25, g: 0.05, b: 0.12)),
        ]
    case .ocean:
        palettes = [

            TimePalette(top: RGB(r: 0.1, g: 0.2, b: 0.4), bottom: RGB(r: 0.15, g: 0.3, b: 0.5), orb1: RGB(r: 0.2, g: 0.35, b: 0.55), orb2: RGB(r: 0.1, g: 0.2, b: 0.45)),

            TimePalette(top: RGB(r: 0.05, g: 0.15, b: 0.35), bottom: RGB(r: 0.1, g: 0.25, b: 0.5), orb1: RGB(r: 0.15, g: 0.3, b: 0.55), orb2: RGB(r: 0.05, g: 0.18, b: 0.45)),

            TimePalette(top: RGB(r: 0.04, g: 0.08, b: 0.25), bottom: RGB(r: 0.06, g: 0.12, b: 0.35), orb1: RGB(r: 0.1, g: 0.15, b: 0.4), orb2: RGB(r: 0.05, g: 0.08, b: 0.3)),

            TimePalette(top: RGB(r: 0.02, g: 0.04, b: 0.15), bottom: RGB(r: 0.04, g: 0.06, b: 0.2), orb1: RGB(r: 0.06, g: 0.1, b: 0.25), orb2: RGB(r: 0.03, g: 0.05, b: 0.18)),
        ]
    case .moss:
        palettes = [

            TimePalette(top: RGB(r: 0.12, g: 0.25, b: 0.15), bottom: RGB(r: 0.18, g: 0.35, b: 0.2), orb1: RGB(r: 0.22, g: 0.4, b: 0.22), orb2: RGB(r: 0.15, g: 0.3, b: 0.18)),

            TimePalette(top: RGB(r: 0.08, g: 0.2, b: 0.12), bottom: RGB(r: 0.12, g: 0.3, b: 0.16), orb1: RGB(r: 0.18, g: 0.35, b: 0.2), orb2: RGB(r: 0.1, g: 0.25, b: 0.14)),

            TimePalette(top: RGB(r: 0.1, g: 0.18, b: 0.08), bottom: RGB(r: 0.15, g: 0.25, b: 0.1), orb1: RGB(r: 0.2, g: 0.3, b: 0.12), orb2: RGB(r: 0.12, g: 0.2, b: 0.08)),

            TimePalette(top: RGB(r: 0.03, g: 0.1, b: 0.06), bottom: RGB(r: 0.05, g: 0.15, b: 0.08), orb1: RGB(r: 0.08, g: 0.2, b: 0.1), orb2: RGB(r: 0.04, g: 0.12, b: 0.06)),
        ]
    case .graphite:
        palettes = [

            TimePalette(top: RGB(r: 0.2, g: 0.2, b: 0.22), bottom: RGB(r: 0.28, g: 0.28, b: 0.3), orb1: RGB(r: 0.32, g: 0.32, b: 0.35), orb2: RGB(r: 0.22, g: 0.22, b: 0.26)),

            TimePalette(top: RGB(r: 0.15, g: 0.15, b: 0.18), bottom: RGB(r: 0.22, g: 0.22, b: 0.25), orb1: RGB(r: 0.28, g: 0.28, b: 0.32), orb2: RGB(r: 0.18, g: 0.18, b: 0.22)),

            TimePalette(top: RGB(r: 0.1, g: 0.1, b: 0.12), bottom: RGB(r: 0.16, g: 0.16, b: 0.18), orb1: RGB(r: 0.2, g: 0.2, b: 0.24), orb2: RGB(r: 0.12, g: 0.12, b: 0.15)),

            TimePalette(top: RGB(r: 0.05, g: 0.05, b: 0.07), bottom: RGB(r: 0.08, g: 0.08, b: 0.1), orb1: RGB(r: 0.12, g: 0.12, b: 0.15), orb2: RGB(r: 0.06, g: 0.06, b: 0.09)),
        ]
    }

    let current = palettes[index]
    let next = palettes[(index + 1) % palettes.count]
    return TimePalette(
        top: current.top.blend(to: next.top, t: t),
        bottom: current.bottom.blend(to: next.bottom, t: t),
        orb1: current.orb1.blend(to: next.orb1, t: t),
        orb2: current.orb2.blend(to: next.orb2, t: t)
    )
}

private struct FloatingOrb: View {
    let color: Color
    let size: CGFloat
    let startOffset: CGPoint
    let endOffset: CGPoint
    let duration: Double
    @Binding var animate: Bool

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.4)
            .opacity(0.2)
            .offset(
                x: animate ? endOffset.x : startOffset.x,
                y: animate ? endOffset.y : startOffset.y
            )
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: animate
            )
    }
}

struct BreakBackgroundView: View {
    let style: BreakBackgroundStyle
    var date: Date = Date()
    @State private var animate = false

    var body: some View {
        let p = palette(for: style, date: date)

        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [p.top.color.opacity(0.45), p.bottom.color.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                FloatingOrb(
                    color: p.orb1.color,
                    size: geo.size.width * 0.4,
                    startOffset: CGPoint(x: -geo.size.width * 0.15, y: -geo.size.height * 0.2),
                    endOffset: CGPoint(x: geo.size.width * 0.15, y: geo.size.height * 0.1),
                    duration: 28,
                    animate: $animate
                )

                FloatingOrb(
                    color: p.orb2.color,
                    size: geo.size.width * 0.35,
                    startOffset: CGPoint(x: geo.size.width * 0.2, y: geo.size.height * 0.15),
                    endOffset: CGPoint(x: -geo.size.width * 0.1, y: -geo.size.height * 0.15),
                    duration: 32,
                    animate: $animate
                )
            }
        }
        .onAppear { animate = true }
    }
}

private struct OverlayButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(filled ? .black : .white.opacity(0.85))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background {
                if filled {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white)
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2, bounce: 0), value: configuration.isPressed)
            .pointerCursor()
    }
}

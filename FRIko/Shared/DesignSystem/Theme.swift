import SwiftUI

enum Theme {

    enum Palette {
        static let canvas = Color.white
        static let ink = Color(hex: "111111")
        static let inkSecondary = Color(hex: "595959")
        static let inkTertiary = Color(hex: "6B6B6B")
        static let hairline = Color.black.opacity(0.14)
        static let wash = Color.black.opacity(0.04)

        static let brand = Color(hex: "3B86F7")
        static let accent = Color(hex: "2563C9")
        static let signal = Color(hex: "D92D20")
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let page: CGFloat = 20
        static let l: CGFloat = 24
        static let xl: CGFloat = 40
    }

    enum Radius {
        static let block: CGFloat = 4
        static let control: CGFloat = 10
    }
}

struct ThemeFont {
    let size: CGFloat
    let weight: Font.Weight
    var design: Font.Design = .default
    let style: Font.TextStyle

    static let numeralXL = ThemeFont(size: 96, weight: .thin, style: .largeTitle)
    static let numeralL = ThemeFont(size: 72, weight: .thin, style: .largeTitle)
    static let numeralM = ThemeFont(size: 56, weight: .thin, style: .largeTitle)
    static let numeralS = ThemeFont(size: 26, weight: .light, style: .title2)
    static let unit = ThemeFont(size: 20, weight: .light, style: .title3)

    static let display = ThemeFont(size: 36, weight: .bold, design: .serif, style: .largeTitle)
    static let title = ThemeFont(size: 28, weight: .bold, design: .serif, style: .title)

    static let headline = ThemeFont(size: 17, weight: .medium, style: .headline)
    static let body = ThemeFont(size: 16, weight: .regular, style: .body)
    static let bodyStrong = ThemeFont(size: 16, weight: .medium, style: .body)
    static let callout = ThemeFont(size: 14, weight: .regular, style: .callout)
    static let caption = ThemeFont(size: 13, weight: .regular, style: .footnote)
    static let eyebrow = ThemeFont(size: 11, weight: .semibold, style: .caption2)

    static let mono = ThemeFont(size: 12, weight: .medium, design: .monospaced, style: .caption)
    static let monoStrong = ThemeFont(size: 14, weight: .medium, design: .monospaced, style: .callout)
}

private struct ThemeFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(_ font: ThemeFont) {
        _size = ScaledMetric(wrappedValue: font.size, relativeTo: font.style)
        weight = font.weight
        design = font.design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func themeFont(_ font: ThemeFont) -> some View {
        modifier(ThemeFontModifier(font))
    }
}

enum Motion {
    static let enter = Animation.smooth(duration: 0.5)
    static let snap = Animation.snappy(duration: 0.3)
    static let press = Animation.snappy(duration: 0.18)
    static let fade = Animation.easeOut(duration: 0.2)
}

private struct Rise: ViewModifier {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 12)
            .onAppear {
                guard !shown else { return }
                let animation = reduceMotion ? Motion.fade : Motion.enter.delay(min(delay, 0.6))
                withAnimation(animation) { shown = true }
            }
    }
}

extension View {
    func rise(_ delay: Double = 0) -> some View {
        modifier(Rise(delay: delay))
    }
}

struct Hairline: View {
    var delay: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        Rectangle()
            .fill(Theme.Palette.hairline)
            .frame(height: 0.5)
            .scaleEffect(x: drawn || reduceMotion ? 1 : 0, anchor: .leading)
            .onAppear {
                guard !drawn else { return }
                withAnimation(.easeOut(duration: 0.6).delay(min(delay, 0.6))) { drawn = true }
            }
            .accessibilityHidden(true)
    }
}

struct PulseDot: View {
    var color: Color = Theme.Palette.brand
    var size: CGFloat = 6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            if !reduceMotion {
                Circle()
                    .fill(color.opacity(0.3))
                    .scaleEffect(pulse ? 3 : 1)
                    .opacity(pulse ? 0 : 1)
            }
            Circle().fill(color)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
        .accessibilityHidden(true)
    }
}

struct Eyebrow: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .themeFont(.eyebrow)
            .tracking(1)
            .foregroundStyle(Theme.Palette.inkTertiary)
            .accessibilityAddTraits(.isHeader)
    }
}

struct MetaTag: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .themeFont(.mono)
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.block, style: .continuous)
                    .fill(Theme.Palette.ink)
            )
    }
}

struct MetaText: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .themeFont(.mono)
            .monospacedDigit()
            .foregroundStyle(Theme.Palette.inkTertiary)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.Palette.wash : .clear)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .themeFont(.bodyStrong)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.body.weight(.medium))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(enabled ? Color.white : Theme.Palette.inkTertiary)
            .padding(.horizontal, Theme.Space.l)
            .frame(minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(enabled ? Theme.Palette.accent : Theme.Palette.wash)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .animation(Motion.snap, value: enabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String = "arrow.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .themeFont(.bodyStrong)

                Spacer()

                Image(systemName: systemImage)
                    .font(.body.weight(.medium))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, Theme.Space.l)
            .frame(minHeight: 54)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.Palette.ink.opacity(0.25), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

struct ChipButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.medium))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .themeFont(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.block * 2, style: .continuous)
                    .strokeBorder(Theme.Palette.ink.opacity(0.25), lineWidth: 0.5)
            )
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }
}

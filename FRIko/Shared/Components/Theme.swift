import SwiftUI

// MARK: - Brand palette
//
// Derived from the "UL" app icon: a vibrant iOS blue with crisp white.
// The app is light-only (every screen sets .preferredColorScheme(.light)),
// so these are fixed values rather than adaptive asset colors.

extension Color {
    /// Primary brand / accent blue (iOS system blue family).
    static var ulBlue: Color { Color(hex: "007AFF") }
    /// Lighter tint taken from the top of the app icon.
    static var ulBlueLight: Color { Color(hex: "5AA6FF") }
    /// Deeper blue used at the bottom end of brand gradients.
    static var ulBlueDeep: Color { Color(hex: "0A5FD8") }

    /// Grouped-list background, matches iOS `systemGroupedBackground`.
    static var ulBackground: Color { Color(hex: "F2F2F7") }
    /// Card / cell surface.
    static var ulCard: Color { Color.white }

    /// Primary text.
    static var ulLabel: Color { Color(hex: "1C1C1E") }
    /// Secondary text (>= 4.5:1 on white).
    static var ulSecondary: Color { Color(hex: "6C6C70") }
    /// Tertiary text / chevrons / placeholders.
    static var ulTertiary: Color { Color(hex: "8E8E93") }

    /// Success / valid state.
    static var ulGreen: Color { Color(hex: "34C759") }
}

extension LinearGradient {
    /// The signature brand gradient used on hero cards and primary buttons.
    static var ulBrand: LinearGradient {
        LinearGradient(
            colors: [Color.ulBlue, Color.ulBlueDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Cards

/// White, continuous-corner surface with a soft shadow. Content is clipped to the
/// card shape first so pressed-row highlights respect the rounded corners, while
/// the shadow (drawn on the background) is not cut off.
private struct ULCardModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .clipShape(shape)
            .background(
                shape
                    .fill(Color.ulCard)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
            )
    }
}

/// Blue brand-gradient surface for hero content (white text on top).
private struct BrandCardModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .background(
                ZStack {
                    LinearGradient.ulBrand
                    RadialGradient(
                        colors: [Color.white.opacity(0.22), Color.clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 280
                    )
                }
                .clipShape(shape)
                .shadow(color: Color.ulBlue.opacity(0.28), radius: 18, y: 10)
            )
    }
}

extension View {
    func ulCard(radius: CGFloat = 20) -> some View {
        modifier(ULCardModifier(radius: radius))
    }

    func brandCard(radius: CGFloat = 28) -> some View {
        modifier(BrandCardModifier(radius: radius))
    }
}

// MARK: - Motion

/// Soft fade-and-rise entrance. Respects Reduce Motion.
struct Rise: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 16)
            .onAppear {
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(delay)) {
                        shown = true
                    }
                }
            }
    }
}

extension View {
    func rise(_ delay: Double = 0) -> some View {
        modifier(Rise(delay: delay))
    }
}

/// Live-state indicator dot with an expanding ring.
struct PulseDot: View {
    var color: Color = Color.ulBlue
    var size: CGFloat = 6
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: size, height: size)
                .scaleEffect(pulse ? 3 : 1)
                .opacity(pulse ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

// MARK: - Button styles

/// Subtle highlight for tappable rows inside cards.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.black.opacity(configuration.isPressed ? 0.06 : 0))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Spring scale for prominent buttons.
struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Small shared components

/// The "UL" app icon, rendered with the iOS icon corner ratio.
struct ULLogo: View {
    var size: CGFloat = 60

    var body: some View {
        Image("icon")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
            .shadow(color: Color.ulBlue.opacity(0.25), radius: size * 0.18, y: size * 0.08)
            .accessibilityHidden(true)
    }
}

/// Small rounded-square SF Symbol tile, like iOS Settings rows.
struct IconTile: View {
    let systemName: String
    var color: Color = Color.ulBlue
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .fill(color)
            )
            .accessibilityHidden(true)
    }
}

/// Compact pill. `onDark` renders it translucent-white for use on brand cards.
struct ULTag: View {
    let text: String
    var onDark: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(onDark ? Color.white : Color.ulBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(onDark ? Color.white.opacity(0.2) : Color.ulBlue.opacity(0.12))
            )
    }
}

import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome, about, school, studentId, calendar, summary
}

final class OnboardingData: ObservableObject {
    @Published var school = ""
    @Published var studentId = ""
    @Published var timetableURL = ""

    var isStudentIdValid: Bool { studentId.count >= 7 }
    var isURLValid: Bool { Self.isValidTimetableURL(timetableURL) }

    static func isValidTimetableURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "urnik.fri.uni-lj.si"
        else { return false }

        return url.path.lowercased().hasPrefix("/timetable/")
    }
}

struct Reveal: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .blur(radius: shown ? 0 : 8)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(delay)) {
                    shown = true
                }
            }
    }
}

extension View {
    func reveal(_ delay: Double = 0) -> some View {
        modifier(Reveal(delay: delay))
    }
}

struct Hairline: View {
    var delay: Double = 0
    @State private var drawn = false

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
            .scaleEffect(x: drawn ? 1 : 0, anchor: .leading)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                    drawn = true
                }
            }
    }
}

struct OnboardingPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(white: 0.1)))
    }
}

struct TwoToneTitle: View {
    let dark: String
    let light: String
    var size: CGFloat = 40
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dark)
                .foregroundColor(.black)
            Text(light)
                .foregroundColor(Color(white: 0.6))
        }
        .font(.system(size: size, weight: .bold))
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Color(white: 0.6))
    }
}

struct ContinueButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(enabled ? Color.white : Color(white: 0.55))
            .padding(.horizontal, 28)
            .frame(height: 60)
            .background(
                Capsule()
                    .fill(enabled ? Color(white: 0.1) : Color.black.opacity(0.06))
            )
            .contentShape(Capsule())
        }
        .buttonStyle(OnboardingPressStyle())
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)        .padding(.horizontal, -4)
        .padding(.bottom, 4)
    }
}

struct OnboardingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

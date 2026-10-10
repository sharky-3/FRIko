import SwiftUI

struct OnboardingFlow: View {

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("school") private var savedSchool = ""

    @StateObject private var data = OnboardingData()
    @State private var step: OnboardingStep = .welcome
    @State private var isEditing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.Palette.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ZStack {
                    page
                        .id(step)
                        .transition(
                            .asymmetric(
                                insertion: reduceMotion
                                    ? .opacity
                                    : .opacity.combined(with: .offset(y: 12)),
                                removal: .opacity
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .preferredColorScheme(.light)
        .tint(Theme.Palette.accent)
    }
    
    @ViewBuilder
    private var page: some View {
        let title = isEditing ? "Shrani" : "Naprej"

        switch step {
        case .welcome:
            WelcomePage(onContinue: next)
        case .about:
            AboutPage(onContinue: next)
        case .school:
            SchoolPage(data: data, buttonTitle: title, onContinue: next)
        case .studentId:
            StudentIdPage(data: data, buttonTitle: title, onContinue: next)
        case .calendar:
            CalendarURLPage(data: data, buttonTitle: title, onContinue: next)
        case .summary:
            SummaryPage(data: data, onEdit: edit, onFinish: finish)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: back) {
                Image(systemName: "arrow.left")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Nazaj")
            .opacity(step == .welcome ? 0 : 1)
            .disabled(step == .welcome)
            .padding(.leading, -12)

            Spacer()

            HStack(spacing: 4) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                    Rectangle()
                        .fill(fill(for: s))
                        .frame(width: s == step ? 22 : 8, height: 3)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Korak \(step.rawValue + 1) od \(OnboardingStep.allCases.count)")
        }
        .padding(.horizontal, Theme.Space.l)
        .padding(.top, 8)
        .frame(height: 52)
        .animation(Motion.snap, value: step)
    }

    private func fill(for s: OnboardingStep) -> Color {
        if s == step { return Theme.Palette.accent }
        return s.rawValue < step.rawValue ? Theme.Palette.ink : Theme.Palette.ink.opacity(0.12)
    }

    private func go(to newStep: OnboardingStep) {
        withAnimation(reduceMotion ? Motion.fade : .smooth(duration: 0.4)) {
            step = newStep
        }
    }

    private func next() {
        if isEditing {
            isEditing = false
            go(to: .summary)
            return
        }
        if let n = OnboardingStep(rawValue: step.rawValue + 1) {
            go(to: n)
        }
    }

    private func back() {
        if isEditing {
            isEditing = false
            go(to: .summary)
            return
        }
        if let p = OnboardingStep(rawValue: step.rawValue - 1) {
            go(to: p)
        }
    }

    private func edit(_ target: OnboardingStep) {
        isEditing = true
        go(to: target)
    }

    private func finish() {
        StudentStorage.shared.studentId = data.studentId
        StudentStorage.shared.timetableURL = data.timetableURL.trimmingCharacters(in: .whitespacesAndNewlines)
        savedSchool = data.school

        withAnimation(.easeInOut(duration: 0.5)) {
            isLoggedIn = true
        }
    }
}

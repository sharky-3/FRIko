import SwiftUI

struct OnboardingFlow: View {

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("school") private var savedSchool = ""

    @StateObject private var data = OnboardingData()
    @State private var step: OnboardingStep = .welcome
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ZStack {
                    page
                        .id(step)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 16)),
                                removal: .opacity
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .preferredColorScheme(.light)
        .tint(.black)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 0.5))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(step == .welcome ? 0 : 1)
            .disabled(step == .welcome)

            Spacer()

            HStack(spacing: 4) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? Color.black : Color.black.opacity(0.12))
                        .frame(width: s == step ? 22 : 8, height: 3)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .frame(height: 50)
        .animation(.snappy(duration: 0.35), value: step)
    }

    private func go(to newStep: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.4)) {
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

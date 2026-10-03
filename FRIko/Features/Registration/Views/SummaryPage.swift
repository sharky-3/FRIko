import SwiftUI

struct SummaryPage: View {
    @ObservedObject var data: OnboardingData
    let onEdit: (OnboardingStep) -> Void
    let onFinish: () -> Void

    private var shortURL: String {
        data.timetableURL
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingPill(text: "PREGLED")
                .reveal(0.1)

            TwoToneTitle(dark: "Vse ", light: "pripravljeno?")
                .padding(.top, 20)
                .reveal(0.2)

            Text("Preveri podatke. Če kaj ne drži, lahko to popraviš.")
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.45))
                .padding(.top, 10)
                .reveal(0.3)

            Spacer()

            VStack(spacing: 0) {
                Hairline(delay: 0.4)

                summaryRow(label: "FAKULTETA", step: .school, delay: 0.45) {
                    Text(data.school)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                summaryRow(label: "VPISNA ŠTEVILKA", step: .studentId, delay: 0.55) {
                    Text(data.studentId)
                        .font(.system(size: 28, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(.black)
                }

                summaryRow(label: "URNIK", step: .calendar, delay: 0.65) {
                    Text(shortURL)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(white: 0.4))
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer().frame(height: 32)

            ContinueButton(title: "Začni", action: onFinish)
                .reveal(0.9)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private func summaryRow<Value: View>(
        label: String,
        step: OnboardingStep,
        delay: Double,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: label)
                    value()
                }

                Spacer(minLength: 12)

                Button {
                    onEdit(step)
                } label: {
                    Text("Uredi")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
                        .contentShape(Capsule())
                }
                .buttonStyle(OnboardingPressStyle())
            }
            .padding(.vertical, 16)
            .reveal(delay)

            Hairline(delay: delay + 0.1)
        }
    }
}

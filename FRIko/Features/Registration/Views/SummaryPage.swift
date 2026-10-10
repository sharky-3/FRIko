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
            MetaTag("PREGLED")
                .rise(0.1)

            TwoToneTitle(dark: "Vse ", light: "pripravljeno?")
                .padding(.top, 20)
                .rise(0.2)

            Text("Preveri podatke. Če kaj ne drži, lahko to popraviš.")
                .themeFont(.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .padding(.top, 10)
                .rise(0.3)

            Spacer()

            VStack(spacing: 0) {
                Hairline(delay: 0.25)

                summaryRow(label: "FAKULTETA", step: .school, delay: 0.3) {
                    Text(data.school)
                        .themeFont(.headline)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                summaryRow(label: "VPISNA ŠTEVILKA", step: .studentId, delay: 0.38) {
                    Text(data.studentId)
                        .themeFont(.numeralS)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.ink)
                }

                summaryRow(label: "URNIK", step: .calendar, delay: 0.46) {
                    Text(shortURL)
                        .themeFont(.mono)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer().frame(height: 32)

            PrimaryButton(title: "Začni", action: onFinish)
                .rise(0.55)
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
                    Eyebrow(label)
                    value()
                }

                Spacer(minLength: 12)

                ChipButton(title: "Uredi") {
                    onEdit(step)
                }
            }
            .padding(.vertical, 16)
            .rise(delay)

            Hairline(delay: delay + 0.05)
        }
    }
}

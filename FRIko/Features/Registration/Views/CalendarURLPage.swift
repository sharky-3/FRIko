import SwiftUI
import UIKit

struct CalendarURLPage: View {
    @ObservedObject var data: OnboardingData
    let buttonTitle: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    private let exampleURL = "https://urnik.fri.uni-lj.si/timetable/fri-2026_2027-zimski"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaTag("3 / 3")
                .rise(0.1)

            TwoToneTitle(dark: "Povezava ", light: "do urnika.")
                .padding(.top, 20)
                .rise(0.2)

            Text("Prilepi povezavo do svojega urnika na urnik.fri.uni-lj.si.")
                .themeFont(.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .lineSpacing(3)
                .padding(.top, 10)
                .rise(0.3)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow("POVEZAVA")

                    Spacer()

                    ChipButton(title: "Prilepi", systemImage: "doc.on.clipboard", action: paste)
                }

                HStack(spacing: 10) {
                    TextField(
                        "",
                        text: $data.timetableURL,
                        prompt: Text("https://urnik.fri.uni-lj.si/…").foregroundColor(Theme.Palette.inkTertiary)
                    )
                    .themeFont(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(Theme.Palette.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit { isFocused = false }

                    if data.isURLValid {
                        Image(systemName: "checkmark")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Theme.Palette.accent)
                            .accessibilityLabel("Povezava je veljavna")
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isFocused ? Theme.Palette.accent : Theme.Palette.hairline)
                        .frame(height: isFocused ? 1.5 : 0.5)
                }

                Text("Primer: \(exampleURL)")
                    .themeFont(.caption)
                    .foregroundStyle(Theme.Palette.inkTertiary)
                    .lineLimit(2)
            }
            .rise(0.45)

            Spacer().frame(height: 32)

            PrimaryButton(
                title: buttonTitle,
                enabled: data.isURLValid,
                action: onContinue
            )
            .rise(0.6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .animation(.snappy(duration: 0.25), value: data.isURLValid)
        .sensoryFeedback(.success, trigger: data.isURLValid) { _, new in new }
    }

    private func paste() {
        if let text = UIPasteboard.general.string {
            data.timetableURL = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

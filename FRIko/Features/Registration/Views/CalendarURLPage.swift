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
            OnboardingPill(text: "3 / 3")
                .reveal(0.1)

            TwoToneTitle(dark: "Povezava ", light: "do urnika.")
                .padding(.top, 20)
                .reveal(0.2)

            Text("Prilepi povezavo do svojega urnika na urnik.fri.uni-lj.si.")
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.45))
                .lineSpacing(3)
                .padding(.top, 10)
                .reveal(0.3)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabel(text: "POVEZAVA")

                    Spacer()

                    Button(action: paste) {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11, weight: .medium))
                            Text("Prilepi")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(Capsule().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
                    }
                    .buttonStyle(OnboardingPressStyle())
                }

                HStack(spacing: 10) {
                    TextField(
                        "",
                        text: $data.timetableURL,
                        prompt: Text("https://urnik.fri.uni-lj.si/…").foregroundColor(Color(white: 0.7))
                    )
                    .font(.system(size: 17))
                    .foregroundStyle(.black)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit { isFocused = false }

                    if data.isURLValid {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isFocused ? Color.black : Color.black.opacity(0.18))
                        .frame(height: isFocused ? 1.5 : 0.5)
                }

                Text("Primer: \(exampleURL)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.55))
                    .lineLimit(2)
            }
            .reveal(0.45)

            Spacer().frame(height: 32)

            ContinueButton(
                title: buttonTitle,
                enabled: data.isURLValid,
                action: onContinue
            )
            .reveal(0.6)
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

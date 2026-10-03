import SwiftUI

struct AboutPage: View {
    let onContinue: () -> Void

    private let features: [(number: String, title: String, text: String)] = [
        ("01", "Danes", "Takoj vidiš, katero predavanje poteka in katero je naslednje."),
        ("02", "Teden", "Pregleden tedenski urnik z živo črto trenutnega časa."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TwoToneTitle(dark: "Vse, kar rabiš. ", light: "Nič odveč.")
                .padding(.top, 20)
                .reveal(0.2)

            Spacer()

            VStack(spacing: 0) {
                Hairline(delay: 0.4)

                ForEach(features.indices, id: \.self) { i in
                    let f = features[i]

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(f.title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.black)

                            Text(f.text)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(white: 0.5))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        Text(f.number)
                            .font(.system(size: 28, weight: .light))
                            .monospacedDigit()
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 18)
                    .reveal(0.5 + Double(i) * 0.15)

                    Hairline(delay: 0.6 + Double(i) * 0.15)
                }
            }

            Spacer().frame(height: 32)

            ContinueButton(title: "Naprej", action: onContinue)
                .reveal(1.0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

import SwiftUI

struct AboutPage: View {
    let onContinue: () -> Void

    private let features: [(title: String, text: String)] = [
        ("Danes", "Takoj vidiš, katero predavanje poteka in katero je naslednje."),
        ("Teden", "Pregleden tedenski urnik z živo črto trenutnega časa."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TwoToneTitle(dark: "Vse, kar rabiš. ", light: "Nič odveč.")
                .padding(.top, 20)
                .rise(0.2)

            Spacer()

            VStack(spacing: 0) {
                Hairline(delay: 0.25)

                ForEach(features.indices, id: \.self) { i in
                    let f = features[i]

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(f.title)
                                .themeFont(.headline)
                                .foregroundStyle(Theme.Palette.ink)

                            Text(f.text)
                                .themeFont(.callout)
                                .foregroundStyle(Theme.Palette.inkSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)
                    }
                    .padding(.vertical, 18)
                    .rise(0.3 + Double(i) * 0.08)

                    Hairline(delay: 0.35 + Double(i) * 0.08)
                }
            }

            Spacer().frame(height: 32)

            PrimaryButton(title: "Naprej", action: onContinue)
                .rise(0.5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

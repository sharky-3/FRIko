import SwiftUI

struct WelcomePage: View {
    let onContinue: () -> Void

    private let word = Array("FRIko")
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = Array(repeating: false, count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            HStack(spacing: 0) {
                ForEach(0..<word.count, id: \.self) { i in
                    Text(String(word[i]))
                        .themeFont(ThemeFont(size: 88, weight: .bold, design: .serif, style: .largeTitle))
                        .foregroundStyle(i < 3 ? Theme.Palette.ink : Theme.Palette.inkTertiary)
                        .opacity(shown[i] ? 1 : 0)
                        .offset(y: shown[i] || reduceMotion ? 0 : 36)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("FRIko")
            .accessibilityAddTraits(.isHeader)

            TwoToneTitle(dark: "Tvoj urnik, ", light: "vedno pri roki.", size: 28)
                .padding(.top, 20)
                .rise(0.5)

            Text("Preglej današnja predavanja in tedenski urnik na enem mestu, brez odpiranja spletne strani.")
                .themeFont(.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .lineSpacing(3)
                .padding(.top, 12)
                .rise(0.55)

            Spacer().frame(height: 40)

            PrimaryButton(title: "Začnimo", action: onContinue)
                .rise(0.6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            for i in 0..<shown.count {
                withAnimation(reduceMotion ? Motion.fade : .smooth(duration: 0.55)) {
                    shown[i] = true
                }
                try? await Task.sleep(nanoseconds: reduceMotion ? 0 : 70_000_000)
            }
        }
    }
}

import SwiftUI

struct WelcomePage: View {
    let onContinue: () -> Void

    private let word = Array("FRIko")
    @State private var shown = Array(repeating: false, count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            HStack(spacing: 0) {
                ForEach(0..<word.count, id: \.self) { i in
                    Text(String(word[i]))
                        .font(.system(size: 88, weight: .bold, design: .serif))
                        .foregroundStyle(i < 3 ? .black : .gray)
                        .opacity(shown[i] ? 1 : 0)
                        .offset(y: shown[i] ? 0 : 50)
                        .blur(radius: shown[i] ? 0 : 14)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            TwoToneTitle(dark: "Tvoj urnik, ", light: "vedno pri roki.", size: 28)
                .padding(.top, 20)
                .reveal(1.1)

            Text("Preglej današnja predavanja in tedenski urnik na enem mestu, brez odpiranja spletne strani.")
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.45))
                .lineSpacing(3)
                .padding(.top, 12)
                .reveal(1.25)

            Spacer().frame(height: 40)

            ContinueButton(title: "Začnimo", action: onContinue)
                .reveal(1.4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            for i in 0..<shown.count {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                    shown[i] = true
                }
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }
}

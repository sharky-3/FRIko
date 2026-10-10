import SwiftUI

/// Launch moment. The one place the brand gets to be loud: three serif
/// letters rising into place, the faculty name, and a hairline of progress.
struct LoadingView: View {

    @Binding var isFinished: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var topIn = false
    @State private var letterStates = [false, false, false]
    @State private var subtitleStates = [false, false, false]
    @State private var barVisible = false
    @State private var progressStart: Date?
    @State private var exiting = false

    private let letters = Array("FRI")
    private let subtitle = [
        "Fakulteta za računalništvo",
        "in informatiko",
        "Univerze v Ljubljani"
    ]

    private let progressDuration: Double = 1.0
    private let exitDuration: Double = 0.4

    var body: some View {
        ZStack {
            Theme.Palette.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topRow

                Spacer()

                title

                subtitleLines
                    .padding(.top, 24)

                Spacer().frame(height: 64)

                progressSection
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.top, 12)
            .padding(.bottom, Theme.Space.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(exiting ? 0 : 1)
            .scaleEffect(exiting && !reduceMotion ? 1.02 : 1)
        }
        .preferredColorScheme(.light)
        .task { await runSequence() }
    }

    // MARK: - Pieces

    private var topRow: some View {
        VStack(spacing: 14) {
            HStack {
                MetaTag("Univerza v Ljubljani")

                Spacer()

                MetaText(Date.now.formatted(.dateTime.hour().minute()))
            }

            Hairline()
        }
        .opacity(topIn ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var title: some View {
        HStack(spacing: -2) {
            ForEach(0..<letters.count, id: \.self) { index in
                Text(String(letters[index]))
                    .themeFont(ThemeFont(size: 150, weight: .regular, design: .serif, style: .largeTitle))
                    .foregroundStyle(Theme.Palette.ink)
                    .offset(y: letterStates[index] || reduceMotion ? 0 : 190)
                    .opacity(letterStates[index] ? 1 : 0)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("FRI")
        .accessibilityAddTraits(.isHeader)
    }

    private var subtitleLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<subtitle.count, id: \.self) { index in
                Text(subtitle[index])
                    .themeFont(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .offset(y: subtitleStates[index] || reduceMotion ? 0 : 16)
                    .opacity(subtitleStates[index] ? 1 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var progressSection: some View {
        TimelineView(.animation(paused: progressStart == nil)) { context in
            let p = progress(at: context.date)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .lastTextBaseline) {
                    Eyebrow("NALAGANJE")

                    Spacer()

                    Text("\(Int((p * 100).rounded()))")
                        .themeFont(.monoStrong)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.Palette.hairline)
                            .frame(height: 1)

                        Rectangle()
                            .fill(Theme.Palette.brand)
                            .frame(width: geo.size.width * p, height: 2)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 6)
            }
        }
        .opacity(barVisible ? 1 : 0)
        .accessibilityHidden(true)
    }

    private func progress(at date: Date) -> CGFloat {
        guard let start = progressStart else { return 0 }
        let t = min(max(date.timeIntervalSince(start) / progressDuration, 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }

    // MARK: - Sequence

    @MainActor
    private func runSequence() async {
        withAnimation(Motion.fade) { topIn = true }
        await sleep(0.15)

        for i in 0..<letterStates.count {
            withAnimation(reduceMotion ? Motion.fade : .smooth(duration: 0.7)) {
                letterStates[i] = true
            }
            await sleep(reduceMotion ? 0 : 0.08)
        }
        await sleep(0.1)

        for i in 0..<subtitleStates.count {
            withAnimation(reduceMotion ? Motion.fade : .smooth(duration: 0.5)) {
                subtitleStates[i] = true
            }
            await sleep(reduceMotion ? 0 : 0.08)
        }

        withAnimation(Motion.fade) { barVisible = true }
        progressStart = Date()

        await sleep(progressDuration + 0.15)

        withAnimation(.easeInOut(duration: exitDuration)) { exiting = true }
        await sleep(exitDuration)

        isFinished = true
    }

    private func sleep(_ seconds: Double) async {
        guard seconds > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

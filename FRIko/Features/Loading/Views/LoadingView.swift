import SwiftUI

private struct GrainRNG: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct LoadingView: View {

    @Binding var isFinished: Bool

    @State private var bgIn = false
    @State private var topIn = false
    @State private var letterStates = [false, false, false]
    @State private var subtitleStates = [false, false, false]
    @State private var barVisible = false
    @State private var progressStart: Date?
    @State private var sheenStart: Date?
    @State private var exiting = false

    private let letters = Array("FRI")
    private let subtitle = [
        "Fakulteta za računalništvo",
        "in informatiko",
        "Univerze v Ljubljani"
    ]

    private let progressDuration: Double = 1.6
    private let sheenDuration: Double = 1.8
    private let exitDuration: Double = 0.7

    private var expo: Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: 1.1)
    }

    var body: some View {
        ZStack {
            background

            VStack(alignment: .leading, spacing: 0) {
                topRow

                Spacer()

                title

                subtitleLines
                    .padding(.top, 24)

                Spacer().frame(height: 64)

                progressSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .scaleEffect(exiting ? 1.04 : 1)
            .blur(radius: exiting ? 12 : 0)
            .opacity(exiting ? 0 : 1)
        }
        .preferredColorScheme(.light)
        .task { await runSequence() }
    }

    private var background: some View {
        ZStack {
            Color(white: 0.985)

            RadialGradient(
                colors: [Color.white, Color(white: 0.94)],
                center: .topLeading,
                startRadius: 40,
                endRadius: 800
            )

            Canvas { context, size in
                var rng = GrainRNG(state: 11)
                for _ in 0..<3500 {
                    let x = CGFloat.random(in: 0..<size.width, using: &rng)
                    let y = CGFloat.random(in: 0..<size.height, using: &rng)
                    let alpha = Double.random(in: 0.02...0.09, using: &rng)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.black.opacity(alpha))
                    )
                }
            }
        }
        .ignoresSafeArea()
        .opacity(bgIn ? 1 : 0)
    }

    private var topRow: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Univerza v Ljubljani")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(white: 0.1)))

                Spacer()

                Text(Date.now, format: .dateTime.hour().minute())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(white: 0.55))
            }
            .opacity(topIn ? 1 : 0)
            .offset(y: topIn ? 0 : -8)

            Rectangle()
                .fill(Color.black.opacity(0.18))
                .frame(height: 0.5)
                .scaleEffect(x: topIn ? 1 : 0, anchor: .leading)
                .animation(.easeOut(duration: 1.0).delay(0.1), value: topIn)
        }
    }

    private var lettersRow: some View {
        HStack(spacing: -2) {
            ForEach(0..<letters.count, id: \.self) { index in
                Text(String(letters[index]))
                    .font(.system(size: 150, weight: .regular, design: .serif))
                    .foregroundStyle(.black)
                    .offset(y: letterStates[index] ? 0 : 190)
            }
        }
        .clipped()
    }

    private var plainLetters: some View {
        HStack(spacing: -2) {
            ForEach(0..<letters.count, id: \.self) { index in
                Text(String(letters[index]))
                    .font(.system(size: 150, weight: .regular, design: .serif))
            }
        }
    }

    private var title: some View {
        lettersRow
            .overlay {
                TimelineView(.animation(paused: sheenStart == nil)) { context in
                    sheen(at: context.date)
                }
                .mask(plainLetters)
                .allowsHitTesting(false)
            }
    }

    @ViewBuilder
    private func sheen(at date: Date) -> some View {
        let raw = sheenStart.map {
            min(max(date.timeIntervalSince($0) / sheenDuration, 0), 1)
        } ?? 0
        let eased = raw * raw * (3 - 2 * raw)

        if eased > 0 && eased < 1 {
            let p = -0.3 + 1.6 * eased
            let c: (Double) -> Double = { min(max($0, 0), 1) }

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: c(p - 0.22)),
                    .init(color: .white.opacity(0.6), location: c(p)),
                    .init(color: .clear, location: c(p + 0.22)),
                    .init(color: .clear, location: 1)
                ],
                startPoint: UnitPoint(x: 0, y: 0.2),
                endPoint: UnitPoint(x: 1, y: 0.8)
            )
        } else {
            Color.clear
        }
    }

    private var subtitleLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<subtitle.count, id: \.self) { index in
                Text(subtitle[index])
                    .font(.system(size: 17))
                    .foregroundStyle(Color(white: 0.45))
                    .offset(y: subtitleStates[index] ? 0 : 26)
                    .opacity(subtitleStates[index] ? 1 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
            }
        }
    }

    private var progressSection: some View {
        TimelineView(.animation(paused: progressStart == nil)) { context in
            let p = progress(at: context.date)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .lastTextBaseline) {
                    Text("NALAGANJE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color(white: 0.6))

                    Spacer()

                    counter(p)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.12))
                            .frame(height: 1)

                        Rectangle()
                            .fill(Color.black)
                            .frame(width: geo.size.width * p, height: 1)

                        Circle()
                            .fill(Color.black)
                            .frame(width: 7, height: 7)
                            .offset(x: geo.size.width * p - 3.5)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 7)
            }
        }
        .opacity(barVisible ? 1 : 0)
    }

    private func counter(_ p: CGFloat) -> some View {
        let value = Int((p * 100).rounded())
        let digits = String(format: "%03d", value)
        let zeros = min(digits.prefix { $0 == "0" }.count, 2)

        return VStack {
            HStack(spacing: 0) {
                Text(String(digits.prefix(zeros)))
                    .foregroundColor(Color(white: 0.8))
                Text(String(digits.dropFirst(zeros)))
                    .foregroundColor(.black)
            }
            .font(.system(size: 34, weight: .light))
            .monospacedDigit()
        }
    }

    private func progress(at date: Date) -> CGFloat {
        guard let start = progressStart else { return 0 }
        let t = min(max(date.timeIntervalSince(start) / progressDuration, 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }

    @MainActor
    private func runSequence() async {
        withAnimation(.easeOut(duration: 0.8)) {
            bgIn = true
        }
        await sleep(0.25)

        withAnimation(.easeOut(duration: 0.7)) {
            topIn = true
        }
        await sleep(0.3)

        for i in 0..<letterStates.count {
            withAnimation(expo) {
                letterStates[i] = true
            }
            await sleep(0.11)
        }
        await sleep(0.2)

        sheenStart = Date()

        for i in 0..<subtitleStates.count {
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9)) {
                subtitleStates[i] = true
            }
            await sleep(0.12)
        }
        await sleep(0.15)

        withAnimation(.easeIn(duration: 0.3)) {
            barVisible = true
        }
        progressStart = Date()

        await sleep(progressDuration + 0.3)

        withAnimation(.timingCurve(0.7, 0, 0.3, 1, duration: exitDuration)) {
            exiting = true
        }
        await sleep(exitDuration)

        isFinished = true
    }

    private func sleep(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

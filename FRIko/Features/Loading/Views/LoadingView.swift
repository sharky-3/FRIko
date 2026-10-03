import SwiftUI

struct LoadingView: View {

    @Binding var isFinished: Bool

    @State private var pillIn = false
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

    private let progressDuration: Double = 1.8
    private let exitDuration: Double = 0.6

    private let showPhoto = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if showPhoto {
                Image("objektX")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                    .grayscale(1)
                    .opacity(pillIn ? 0.07 : 0)
            }

            VStack(alignment: .leading, spacing: 0) {
                pill

                Spacer()

                title

                subtitleLines
                    .padding(.top, 20)

                Spacer().frame(height: 56)

                progressSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .blur(radius: exiting ? 14 : 0)
            .offset(y: exiting ? -24 : 0)
            .opacity(exiting ? 0 : 1)
        }
        .preferredColorScheme(.light)
        .task { await runSequence() }
    }

    private var pill: some View {
        Text("FRI · UL")
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(white: 0.1)))
            .opacity(pillIn ? 1 : 0)
            .offset(y: pillIn ? 0 : -8)
    }

    private var title: some View {
        HStack(spacing: 2) {
            ForEach(0..<letters.count, id: \.self) { index in
                Text(String(letters[index]))
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .foregroundStyle(.black)
                    .opacity(letterStates[index] ? 1 : 0)
                    .offset(y: letterStates[index] ? 0 : 40)
                    .blur(radius: letterStates[index] ? 0 : 14)
            }
        }
    }

    private var subtitleLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<subtitle.count, id: \.self) { index in
                Text(subtitle[index])
                    .font(.system(size: 17))
                    .foregroundStyle(Color(white: 0.45))
                    .opacity(subtitleStates[index] ? 1 : 0)
                    .offset(y: subtitleStates[index] ? 0 : 12)
                    .blur(radius: subtitleStates[index] ? 0 : 5)
            }
        }
    }

    private var progressSection: some View {
        TimelineView(.animation(paused: progressStart == nil)) { context in
            let p = progress(at: context.date)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .lastTextBaseline) {
                    Text("NALAGANJE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color(white: 0.6))

                    Spacer()

                    Text("\(Int(p * 100))")
                        .font(.system(size: 28, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(.black)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.12))

                        Rectangle()
                            .fill(Color.black)
                            .frame(width: geo.size.width * p)
                    }
                }
                .frame(height: 1.5)
            }
        }
        .opacity(barVisible ? 1 : 0)
    }


    private func progress(at date: Date) -> CGFloat {
        guard let start = progressStart else { return 0 }
        let t = min(max(date.timeIntervalSince(start) / progressDuration, 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }

    @MainActor
    private func runSequence() async {
        await sleep(0.2)

        withAnimation(.easeOut(duration: 0.5)) {
            pillIn = true
        }
        await sleep(0.3)

        for i in 0..<letterStates.count {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                letterStates[i] = true
            }
            await sleep(0.12)
        }
        await sleep(0.15)

        for i in 0..<subtitleStates.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                subtitleStates[i] = true
            }
            await sleep(0.14)
        }
        await sleep(0.1)

        withAnimation(.easeIn(duration: 0.3)) {
            barVisible = true
        }
        progressStart = Date()

        await sleep(progressDuration + 0.25)

        withAnimation(.easeInOut(duration: exitDuration)) {
            exiting = true
        }
        await sleep(exitDuration)

        isFinished = true
    }

    private func sleep(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

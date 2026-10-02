import SwiftUI

struct LoadingView: View {
    
    @Binding var isFinished: Bool
    
    @State private var bgIn = false
    @State private var letterStates = [false, false, false]
    @State private var lineIn = false
    @State private var subtitleStates = [false, false, false]
    @State private var barVisible = false
    @State private var progress: CGFloat = 0
    @State private var shimmerOn = false
    @State private var exiting = false
    
    private let letters = Array("FRI")
    private let subtitle = [
        "Fakulteta za računalništvo",
        "in informatiko",
        "Univerze v Ljubljani"
    ]
    
    private let bgDuration: Double = 1.4
    private let progressDuration: Double = 2.0
    private let exitDuration: Double = 0.8
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            Image("objektX")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .blur(radius: exiting ? 20 : (bgIn ? 0 : 25))
                .opacity(exiting ? 0 : (bgIn ? 1 : 0))
            
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)
                
                Spacer()
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
            }
            .ignoresSafeArea()
            .blur(radius: exiting ? 20 : 0)
            .opacity(exiting ? 0 : (bgIn ? 1 : 0))
            
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    
                    title
                    
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: lineIn ? 50 : 0, height: 3)
                        .opacity(lineIn ? 1 : 0)
                    
                    VStack(spacing: 4) {
                        ForEach(0..<subtitle.count, id: \.self) { index in
                            Text(subtitle[index])
                                .opacity(subtitleStates[index] ? 1 : 0)
                                .offset(y: subtitleStates[index] ? 0 : 14)
                                .blur(radius: subtitleStates[index] ? 0 : 6)
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 120 * progress)
                    }
                    .frame(width: 120, height: 3)
                    .padding(.top, 12)
                    .opacity(barVisible ? 1 : 0)
                }
                .padding(.bottom, 40)
                .blur(radius: exiting ? 20 : 0)
                .scaleEffect(exiting ? 0.5 : 1)
                .opacity(exiting ? 0 : 1)
            }
            .padding(.horizontal, 30)
        }
        .task {
            await runSequence()
        }
    }
    
    private var titleLetters: some View {
        HStack(spacing: 4) {
            ForEach(0..<letters.count, id: \.self) { index in
                Text(String(letters[index]))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(letterStates[index] ? 1 : 0)
                    .offset(y: letterStates[index] ? 0 : 30)
                    .scaleEffect(letterStates[index] ? 1 : 0.4)
                    .blur(radius: letterStates[index] ? 0 : 12)
            }
        }
    }
    
    private var title: some View {
        titleLetters
            .overlay {
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let phase = CGFloat(t.truncatingRemainder(dividingBy: 1.6) / 1.6)
                    
                    GeometryReader { geo in
                        let w = geo.size.width
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.9), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: w * 0.7)
                        .offset(x: -w * 0.7 + phase * (w * 1.7))
                        .blendMode(.plusLighter)
                    }
                }
                .mask(titleLetters)
                .opacity(shimmerOn ? 1 : 0)
                .allowsHitTesting(false)
            }
            .shadow(color: .white.opacity(letterStates.allSatisfy { $0 } ? 0.35 : 0), radius: 18)
    }
    
    @MainActor
    private func runSequence() async {
        
        await sleep(0.2)
        
        withAnimation(.easeOut(duration: bgDuration)) {
            bgIn = true
        }
        
        await sleep(0.6)
        
        for i in 0..<letterStates.count {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                letterStates[i] = true
            }
            await sleep(0.18)
        }
        
        withAnimation(.easeIn(duration: 0.4)) {
            shimmerOn = true
        }
        await sleep(0.2)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            lineIn = true
        }
        await sleep(0.3)
        
        withAnimation(.easeIn(duration: 0.4)) {
            barVisible = true
        }
        withAnimation(.easeInOut(duration: progressDuration)) {
            progress = 1
        }
        for i in 0..<subtitleStates.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                subtitleStates[i] = true
            }
            await sleep(0.2)
        }
        
        await sleep(progressDuration - 0.6 + 0.4)
        
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


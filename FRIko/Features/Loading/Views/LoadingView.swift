import SwiftUI
import Combine

struct LoadingView: View {
    
    @Binding var isFinished: Bool
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            
            Color.white
                .ignoresSafeArea()
            
            Image("objektX")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .blur(radius: isFinished ? 20 : 0)
                .opacity(isFinished ? 0 : 1)

            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)
            }
            .ignoresSafeArea()
            .blur(radius: isFinished ? 20 : 0)
            .opacity(isFinished ? 0 : 1)

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Text("FRI")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .blur(radius: isFinished ? 20 : 0)
                        .scaleEffect(isFinished ? 0.5 : 1)
                        .opacity(isFinished ? 0 : 1)
                    
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 50, height: 3)
                        .blur(radius: isFinished ? 20 : 0)
                        .scaleEffect(isFinished ? 0.5 : 1)
                        .opacity(isFinished ? 0 : 1)
                    
                    VStack(spacing: 4) {
                        
                        Text("Fakulteta za računalništvo")
                        Text("in informatiko")
                        Text("Univerze v Ljubljani")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .blur(radius: isFinished ? 20 : 0)
                    .scaleEffect(isFinished ? 0.5 : 1)
                    .opacity(isFinished ? 0 : 1)
                    
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 30)
        }
        .onReceive(timer) { _ in
            if !isFinished {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isFinished = true
                }
            }
        }
    }
}

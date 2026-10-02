import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Image("objektX")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            Color.black.opacity(0.4)
                .ignoresSafeArea()

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

            VStack {
                Spacer()

                VStack(spacing: 8) {
                    Text("FRI")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Timetable & Results")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                VStack(spacing: 16) {
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 40, height: 3)

                    VStack(spacing: 4) {
                        Text("Fakulteta za računalništvo")
                        Text("in informatiko")
                        Text("Univerze v Ljubljani")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 30)
        }
    }
}

#Preview {
    LoadingView()
}

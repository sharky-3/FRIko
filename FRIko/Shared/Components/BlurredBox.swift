
import SwiftUI

struct BlurredBox: View {
    var body: some View {
        ZStack {
            Image("your_background_image")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Blurred Card / Overlay
            VStack {
                Text("Blurred Container")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 280, height: 180) // Set explicit size
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20)) // Apply blur & shape
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1) // Optional border line
            )
            .position(x: 200, y: 300) // Set explicit position (center point)
        }
    }
}

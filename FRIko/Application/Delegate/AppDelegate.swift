import SwiftUI

@main
struct FRIkoApp: App {
    @State private var isLoaded: Bool = true
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("studentId") private var studentId: String = ""
    
    init() {
        NotificationManager.shared.configure()
    }

    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Palette.canvas
                    .ignoresSafeArea()

                if !isLoaded {
                    LoadingView(isFinished: $isLoaded)
                        .transition(.opacity)
                } else if isLoggedIn {
                    PagerView()
                } else {
                    OnboardingFlow()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isLoaded)
            .animation(.easeInOut(duration: 0.35), value: isLoggedIn)
        }
    }
}

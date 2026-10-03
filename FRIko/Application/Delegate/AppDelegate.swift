import SwiftUI

@main
struct FRIkoApp: App {
    @State private var isLoaded: Bool = false
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("studentId") private var studentId: String = ""
    
    var body: some Scene {
        WindowGroup {
            PagerView()
            /*
            ZStack {
                Color.white
                    .ignoresSafeArea()

                if !isLoaded {
                    LoadingView(isFinished: $isLoaded)
                        .transition(.opacity)
                } else if isLoggedIn {
                    PagerView()
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isLoaded)
            .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
             */
        }
    }
}

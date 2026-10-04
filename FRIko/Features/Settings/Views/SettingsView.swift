import SwiftUI

private struct Rise: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 22)
            .blur(radius: shown ? 0 : 6)
            .onAppear {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(delay)) {
                    shown = true
                }
            }
    }
}

private extension View {
    func rise(_ delay: Double = 0) -> some View {
        modifier(Rise(delay: delay))
    }
}

private struct DrawHairline: View {
    var delay: Double = 0
    @State private var drawn = false

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
            .scaleEffect(x: drawn ? 1 : 0, anchor: .leading)
            .onAppear {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(delay)) {
                    drawn = true
                }
            }
    }
}

private struct PulseDot: View {
    var color: Color = .black
    var size: CGFloat = 6
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .scaleEffect(pulse ? 3 : 1)
                .opacity(pulse ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

private struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.black.opacity(configuration.isPressed ? 0.04 : 0))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct PillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SettingsView: View {

    @ObservedObject var viewModel: TimetableViewModel

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("settings.notifications") private var notifications = true

    @State private var showLogoutConfirm = false
    @State private var isRefreshing = false

    private var studentId: String {
        StudentStorage.shared.studentId ?? "-"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var windowInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .keyWindow?
            .safeAreaInsets ?? .zero
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topRow
                    .rise(0.05)

                hero
                    .padding(.top, 18)
                    .rise(0.15)

                Spacer(minLength: 24)

                settingsList

                logoutButton
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .rise(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, windowInsets.top + 20)
            .padding(.bottom, windowInsets.bottom + 16)
        }
        .ignoresSafeArea()
        .tint(.black)
        .preferredColorScheme(.light)
        .confirmationDialog(
            "Se želiš odjaviti?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Odjava", role: .destructive) { logout() }
            Button("Prekliči", role: .cancel) {}
        }
    }

    private var topRow: some View {
        HStack {
            Text("FRI · UL")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            Spacer()

            Text("NASTAVITVE")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))
        }
        .padding(.horizontal, 20)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                PulseDot(color: .black, size: 6)
                    .frame(width: 6, height: 6)

                Text("PRIJAVLJEN RAČUN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color(white: 0.6))

                Spacer()
            }

            Text(studentId)
                .font(.system(size: 64, weight: .ultraLight))
                .monospacedDigit()
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 24)

            Text("VPISNA ŠTEVILKA")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color(white: 0.6))
                .padding(.top, 2)

            Rectangle()
                .fill(Color.black.opacity(0.18))
                .frame(height: 0.5)
                .padding(.vertical, 20)

            HStack {
                Text("FRIko")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(.black)

                Spacer()

                Text("v\(appVersion)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(white: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)

        return shape
            .fill(Color(white: 0.07))
            .overlay(
                RadialGradient(
                    colors: [Color.white.opacity(0.14), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 280
                )
                .clipShape(shape)
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            )
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            DrawHairline(delay: 0.35)

            row(
                title: "Opomniki",
                subtitle: "Obvestila pred predavanji"
            ) {
                Toggle("", isOn: notificationsBinding)
                    .labelsHidden()
                    .tint(.black)
            }
            .rise(0.4)

            DrawHairline(delay: 0.45)

            Button {
                Task {
                    isRefreshing = true
                    await viewModel.refresh()
                    isRefreshing = false
                }
            } label: {
                row(
                    title: "Osveži urnik",
                    subtitle: "Prenesi podatke znova"
                ) {
                    if isRefreshing {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(RowPressStyle())
            .rise(0.5)

            DrawHairline(delay: 0.55)

            row(
                title: "O aplikaciji",
                subtitle: "FRI · UL"
            ) {
                Text(appVersion)
                    .font(.system(size: 24, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.black)
            }
            .rise(0.6)

            DrawHairline(delay: 0.65)
        }
    }

    private func row<Trailing: View>(
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(minHeight: 70)
        .contentShape(Rectangle())
    }

    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack {
                Text("Odjava")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .frame(height: 60)
            .background(Capsule().fill(Color(white: 0.1)))
            .contentShape(Capsule())
        }
        .buttonStyle(PillPressStyle())
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { notifications },
            set: { newValue in
                Task {
                    if newValue {
                        let granted = await NotificationManager.shared.requestPermission()
                        notifications = granted

                        if granted {
                            NotificationManager.shared.send(
                                title: "FRIko",
                                body: "Obvestila so vklopljena!",
                                after: 1
                            )
                        }
                    } else {
                        notifications = false
                    }
                }
            }
        )
    }

    private func logout() {
        StudentStorage.shared.clearAll()
        isLoggedIn = false
    }
}

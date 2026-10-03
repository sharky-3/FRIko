import SwiftUI

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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "\(version)"
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
                header

                Spacer(minLength: 24)

                settingsList
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(studentId)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            VStack(alignment: .leading, spacing: 10) {
                Text("NASTAVITVE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(white: 0.6))

                Text("Tvoj račun in aplikacija.")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("FRI · UL · FRIko \(appVersion)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            hairline

            settingsRow(
                title: "Vpisna številka",
                subtitle: "Prijavljen račun",
                caption: "Račun"
            ) {
                bigValue(studentId)
            }

            settingsRow(
                title: "Opomniki",
                subtitle: "Pred predavanji",
                caption: "Obvestila"
            ) {
                Toggle("", isOn: notificationsBinding)
                    .labelsHidden()
                    .tint(.black)
            }
            Button {
                Task {
                    isRefreshing = true
                    await viewModel.refresh()
                    isRefreshing = false
                }
            } label: {
                settingsRow(
                    title: "Osveži urnik",
                    subtitle: "Prenesi znova",
                    caption: "Urnik"
                ) {
                    if isRefreshing {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)

            settingsRow(
                title: "FRIko",
                subtitle: "O aplikaciji",
                caption: "Različica"
            ) {
                bigValue(appVersion)
            }

            Button {
                showLogoutConfirm = true
            } label: {
                settingsRow(
                    title: "Odjava",
                    subtitle: "Izbriši podatke",
                    caption: "Račun"
                ) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.black)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow<Trailing: View>(
        title: String,
        subtitle: String,
        caption: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(caption)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(white: 0.55))
                        .lineLimit(1)

                    trailing()
                        .frame(minHeight: 32, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())

            hairline
        }
    }
    
    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { notifications },
            set: { newValue in
                Task {
                    if newValue {
                        let granted = await NotificationManager.shared.requestPermission()
                        notifications = granted
                    } else {
                        notifications = false
                    }
                    
                    NotificationManager.shared.send(
                        title: "FRIko",
                        body: "Obvestila so \(notifications ? "vklopljena" : "izklopljena").",
                        after: 1
                    )
                }
            }
        )
    }

    private func bigValue(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .light))
            .monospacedDigit()
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
    }

    private func logout() {
        StudentStorage.shared.clearAll()
        isLoggedIn = false
    }
}

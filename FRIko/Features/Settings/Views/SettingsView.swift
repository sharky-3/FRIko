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
            Theme.Palette.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topRow
                    .rise(0.05)

                hero
                    .padding(.top, 18)
                    .rise(0.1)

                Spacer(minLength: 24)

                settingsList

                SecondaryButton(
                    title: "Odjava",
                    systemImage: "rectangle.portrait.and.arrow.right"
                ) {
                    showLogoutConfirm = true
                }
                .padding(.horizontal, Theme.Space.m)
                .padding(.top, 20)
                .rise(0.35)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, windowInsets.top + 20)
            .padding(.bottom, windowInsets.bottom + 16)
        }
        .ignoresSafeArea()
        .tint(Theme.Palette.accent)
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
            MetaTag("FRI · UL")

            Spacer()

            MetaText("NASTAVITVE")
        }
        .padding(.horizontal, Theme.Space.page)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                PulseDot()

                Eyebrow("PRIJAVLJEN RAČUN")

                Spacer()
            }

            Text(studentId)
                .themeFont(.numeralM)
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 20)

            Eyebrow("VPISNA ŠTEVILKA")
                .padding(.top, 2)

            Hairline()
                .padding(.vertical, 20)

            HStack {
                Text("FRIko")
                    .themeFont(.title)
                    .foregroundStyle(Theme.Palette.ink)

                Spacer()

                MetaText("v\(appVersion)")
            }
        }
        .padding(.horizontal, Theme.Space.page)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            Hairline(delay: 0.15)

            row(
                title: "Opomniki",
                subtitle: "Obvestila pred predavanji"
            ) {
                Toggle("Opomniki", isOn: notificationsBinding)
                    .labelsHidden()
            }
            .rise(0.2)

            Hairline(delay: 0.2)

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
                        ProgressView().tint(Theme.Palette.ink)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3.weight(.light))
                            .foregroundStyle(Theme.Palette.ink)
                            .accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(RowPressStyle())
            .disabled(isRefreshing)
            .rise(0.25)

            Hairline(delay: 0.25)

            row(
                title: "O aplikaciji",
                subtitle: "FRI · UL"
            ) {
                Text(appVersion)
                    .themeFont(.numeralS)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.ink)
            }
            .rise(0.3)

            Hairline(delay: 0.3)
        }
    }

    private func row<Trailing: View>(
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .themeFont(.bodyStrong)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .themeFont(.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.vertical, 16)
        .frame(minHeight: 70)
        .contentShape(Rectangle())
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

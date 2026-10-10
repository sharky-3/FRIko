import SwiftUI

struct School: Identifiable {
    let code: String
    let name: String
    let available: Bool
    var id: String { code }
}

struct SchoolPage: View {
    @ObservedObject var data: OnboardingData
    let buttonTitle: String
    let onContinue: () -> Void

    private let schools: [School] = [
        School(code: "FRI", name: "Fakulteta za računalništvo in informatiko", available: true),
        School(code: "FE", name: "Fakulteta za elektrotehniko", available: false),
        School(code: "FMF", name: "Fakulteta za matematiko in fiziko", available: false),
        School(code: "EF", name: "Ekonomska fakulteta", available: false)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaTag("1 / 3")
                .rise(0.1)

            TwoToneTitle(dark: "Kje ", light: "študiraš?")
                .padding(.top, 20)
                .rise(0.2)

            Text("Izberi svojo fakulteto.")
                .themeFont(.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .padding(.top, 10)
                .rise(0.3)

            Spacer()

            VStack(spacing: 0) {
                Hairline(delay: 0.25)

                ForEach(schools.indices, id: \.self) { i in
                    row(schools[i])
                        .rise(0.3 + Double(i) * 0.06)

                    Hairline(delay: 0.35 + Double(i) * 0.06)
                }
            }

            Spacer().frame(height: 32)

            PrimaryButton(
                title: buttonTitle,
                enabled: !data.school.isEmpty,
                action: onContinue
            )
            .rise(0.55)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .sensoryFeedback(.selection, trigger: data.school)
    }

    private func row(_ school: School) -> some View {
        let isSelected = data.school == school.name

        return Button {
            guard school.available else { return }
            withAnimation(Motion.snap) {
                data.school = school.name
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(school.code)
                            .themeFont(.numeralS)
                            .foregroundStyle(Theme.Palette.ink)

                        if !school.available {
                            Text("KMALU")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.6)
                                .foregroundStyle(Theme.Palette.inkSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .stroke(Theme.Palette.ink.opacity(0.25), lineWidth: 0.5)
                                )
                        }
                    }

                    Text(school.name)
                        .themeFont(.callout)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.Palette.accent : Theme.Palette.ink.opacity(0.3), lineWidth: 1)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Theme.Palette.accent)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }
            }
            .padding(.vertical, 14)
            .opacity(school.available ? 1 : 0.4)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
        .disabled(!school.available)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

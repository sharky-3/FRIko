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
            OnboardingPill(text: "1 / 3")
                .reveal(0.1)

            TwoToneTitle(dark: "Kje ", light: "študiraš?")
                .padding(.top, 20)
                .reveal(0.2)

            Text("Izberi svojo fakulteto.")
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.45))
                .padding(.top, 10)
                .reveal(0.3)

            Spacer()

            VStack(spacing: 0) {
                Hairline(delay: 0.4)

                ForEach(schools.indices, id: \.self) { i in
                    row(schools[i])
                        .reveal(0.45 + Double(i) * 0.1)

                    Hairline(delay: 0.55 + Double(i) * 0.1)
                }
            }

            Spacer().frame(height: 32)

            ContinueButton(
                title: buttonTitle,
                enabled: !data.school.isEmpty,
                action: onContinue
            )
            .reveal(0.9)
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
            withAnimation(.snappy(duration: 0.3)) {
                data.school = school.name
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(school.code)
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.black)

                        if !school.available {
                            Text("KMALU")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(Color(white: 0.45))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .overlay(Capsule().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
                        }
                    }

                    Text(school.name)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(white: 0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.black.opacity(0.25), lineWidth: 1)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }
            }
            .padding(.vertical, 14)
            .opacity(school.available ? 1 : 0.4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!school.available)
    }
}

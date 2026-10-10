import SwiftUI

struct StudentIdPage: View {
    @ObservedObject var data: OnboardingData
    let buttonTitle: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool
    @State private var caretOn = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let digitCount = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaTag("2 / 3")
                .rise(0.1)

            TwoToneTitle(dark: "Tvoja ", light: "vpisna številka.")
                .padding(.top, 20)
                .rise(0.2)

            Text("Vpiši številko, s katero si vpisan na fakulteto.")
                .themeFont(.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .padding(.top, 10)
                .rise(0.3)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Eyebrow("VPISNA ŠTEVILKA")

                HStack(spacing: 6) {
                    ForEach(0..<digitCount, id: \.self) { index in
                        cell(at: index)
                    }
                }
                .background(hiddenField)
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }
            }
            .rise(0.45)

            Spacer().frame(height: 32)

            PrimaryButton(
                title: buttonTitle,
                enabled: data.isStudentIdValid,
                action: onContinue
            )
            .rise(0.6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .sensoryFeedback(.selection, trigger: data.studentId)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    caretOn = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isFocused = true
            }
        }
    }

    private var hiddenField: some View {
        TextField("", text: $data.studentId)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .onChange(of: data.studentId) { _, newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(digitCount))
                if filtered != newValue {
                    data.studentId = filtered
                }
            }
    }

    private func cell(at index: Int) -> some View {
        let digit = digit(at: index)
        let isActive = isFocused && index == min(data.studentId.count, digitCount - 1)

        return ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.control - 2, style: .continuous)
                .fill(Theme.Palette.canvas)

            RoundedRectangle(cornerRadius: Theme.Radius.control - 2, style: .continuous)
                .strokeBorder(
                    isActive ? Theme.Palette.accent : Theme.Palette.ink.opacity(0.2),
                    lineWidth: isActive ? 1.5 : 0.5
                )

            if let digit {
                Text(digit)
                    .themeFont(.numeralS)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.ink)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else if isActive {
                Rectangle()
                    .fill(Theme.Palette.accent)
                    .frame(width: 1.5, height: 22)
                    .opacity(caretOn ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: data.studentId)
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private func digit(at index: Int) -> String? {
        guard index < data.studentId.count else { return nil }
        return String(data.studentId[data.studentId.index(data.studentId.startIndex, offsetBy: index)])
    }
}

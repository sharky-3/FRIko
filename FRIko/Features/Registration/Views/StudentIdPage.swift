import SwiftUI

struct StudentIdPage: View {
    @ObservedObject var data: OnboardingData
    let buttonTitle: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool
    @State private var caretOn = true

    private let digitCount = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingPill(text: "2 / 3")
                .reveal(0.1)

            TwoToneTitle(dark: "Tvoja ", light: "vpisna številka.")
                .padding(.top, 20)
                .reveal(0.2)

            Text("Vpiši številko, s katero si vpisan na fakulteto.")
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.45))
                .padding(.top, 10)
                .reveal(0.3)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "VPISNA ŠTEVILKA")

                HStack(spacing: 6) {
                    ForEach(0..<digitCount, id: \.self) { index in
                        cell(at: index)
                    }
                }
                .background(hiddenField)
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }
            }
            .reveal(0.45)

            Spacer().frame(height: 32)

            ContinueButton(
                title: buttonTitle,
                enabled: data.isStudentIdValid,
                action: onContinue
            )
            .reveal(0.6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .sensoryFeedback(.selection, trigger: data.studentId)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                caretOn = false
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isActive ? Color.black : Color.black.opacity(0.18),
                    lineWidth: isActive ? 1.5 : 0.5
                )

            if let digit {
                Text(digit)
                    .font(.system(size: 24, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            } else if isActive {
                Capsule()
                    .fill(Color.black)
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

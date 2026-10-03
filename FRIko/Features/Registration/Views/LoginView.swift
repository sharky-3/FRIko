import SwiftUI

struct LoginView: View {

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var inputId: String = ""
    @State private var inputTimetableURL: String = ""

    @State private var showError: Bool = false
    @State private var shakeTrigger: Int = 0
    @State private var caretOn: Bool = true

    @FocusState private var isFieldFocused: Bool
    @FocusState private var isURLFocused: Bool

    private let digitCount = 8
    private let minDigits = 7

    private let exampleURL = "https://urnik.fri.uni-lj.si/timetable/fri-2026_2027-zimski"

    private var isStudentIdValid: Bool {
        inputId.count >= minDigits
    }

    private var isURLValid: Bool {
        guard let url = URL(string: inputTimetableURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "urnik.fri.uni-lj.si"
        else {
            return false
        }

        return url.path.lowercased().hasPrefix("/timetable/")
    }

    private var isValid: Bool {
        isStudentIdValid && isURLValid
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                .onTapGesture {
                    isFieldFocused = false
                    isURLFocused = false
                }

            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        Spacer(minLength: 32)

                        VStack(alignment: .leading, spacing: 32) {
                            digitField
                            timetableURLField
                            errorLabel
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 32)

                        loginButton
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .preferredColorScheme(.light)
        .tint(.black)
        .sensoryFeedback(.selection, trigger: inputId)
        .sensoryFeedback(.error, trigger: shakeTrigger)
        .sensoryFeedback(.success, trigger: isLoggedIn)
        .onAppear {
            inputId = StudentStorage.shared.studentId ?? ""
            inputTimetableURL = StudentStorage.shared.timetableURL ?? ""

            withAnimation(
                .easeInOut(duration: 0.55)
                .repeatForever(autoreverses: true)
            ) {
                caretOn = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFieldFocused = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("FRI · UL")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 0) {
                    Text("Prijava ")
                        .foregroundColor(.black)
                    Text("v FRIko.")
                        .foregroundColor(Color(white: 0.6))
                }
                .font(.system(size: 36, weight: .bold, design: .serif))
                .fixedSize(horizontal: false, vertical: true)

                Text("Vnesi vpisno številko in povezavo do urnika.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
    }

    private var digitField: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("VPISNA ŠTEVILKA")

            HStack(spacing: 6) {
                ForEach(0..<digitCount, id: \.self) { index in
                    cell(at: index)
                }
            }
            .background(hiddenTextField)
            .contentShape(Rectangle())
            .onTapGesture {
                isFieldFocused = true
            }
            .keyframeAnimator(
                initialValue: 0.0,
                trigger: shakeTrigger
            ) { content, offset in
                content.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(10, duration: 0.07)
                    CubicKeyframe(-10, duration: 0.07)
                    CubicKeyframe(6, duration: 0.07)
                    CubicKeyframe(-6, duration: 0.07)
                    CubicKeyframe(0, duration: 0.07)
                }
            }
        }
    }

    private var hiddenTextField: some View {
        TextField("", text: $inputId)
            .keyboardType(.numberPad)
            .focused($isFieldFocused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .onChange(of: inputId) { _, newValue in
                let filtered = String(
                    newValue
                        .filter(\.isNumber)
                        .prefix(digitCount)
                )

                if filtered != newValue {
                    inputId = filtered
                }

                if showError && isValid {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showError = false
                    }
                }
            }
    }

    private func cell(at index: Int) -> some View {
        let digit = getDigit(at: index)
        let isActive = isFieldFocused && index == min(inputId.count, digitCount - 1)
        let hasError = showError && !isStudentIdValid

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    hasError ? Color.red.opacity(0.8)
                    : isActive ? Color.black
                    : Color.black.opacity(0.18),
                    lineWidth: isActive || hasError ? 1.5 : 0.5
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: inputId)
        .animation(.easeOut(duration: 0.15), value: isFieldFocused)
    }

    private var timetableURLField: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("POVEZAVA DO URNIKA")

            VStack(alignment: .leading, spacing: 0) {
                TextField(
                    "",
                    text: $inputTimetableURL,
                    prompt: Text("Prilepi povezavo").foregroundColor(Color(white: 0.7))
                )
                .font(.system(size: 17))
                .foregroundStyle(.black)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .focused($isURLFocused)
                .padding(.vertical, 14)
                .onChange(of: inputTimetableURL) { _, _ in
                    if showError && isValid {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showError = false
                        }
                    }
                }

                Rectangle()
                    .fill(
                        showError && !isURLValid ? Color.red.opacity(0.8)
                        : isURLFocused ? Color.black
                        : Color.black.opacity(0.18)
                    )
                    .frame(height: isURLFocused || (showError && !isURLValid) ? 1.5 : 0.5)
            }

            Text("Primer: \(exampleURL)")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.55))
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if showError {
            VStack(alignment: .leading, spacing: 6) {
                if !isStudentIdValid {
                    errorRow("Vnesi vsaj \(minDigits) številk vpisne številke.")
                }

                if !isURLValid {
                    errorRow("Vnesi veljavno povezavo do urnika.")
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func errorRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(size: 13))
        }
        .foregroundStyle(Color.red.opacity(0.85))
    }

    private var loginButton: some View {
        Button(action: handleLogin) {
            Text("Prijava")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isValid ? Color.white : Color(white: 0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isValid ? Color(white: 0.1) : Color.black.opacity(0.06))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Color(white: 0.6))
    }

    private func getDigit(at index: Int) -> String? {
        guard index < inputId.count else { return nil }
        return String(inputId[inputId.index(inputId.startIndex, offsetBy: index)])
    }

    private func handleLogin() {
        guard isValid else {
            withAnimation(.easeOut(duration: 0.2)) {
                showError = true
            }
            shakeTrigger += 1
            return
        }

        StudentStorage.shared.studentId = inputId

        StudentStorage.shared.timetableURL =
            inputTimetableURL.trimmingCharacters(in: .whitespacesAndNewlines)

        showError = false
        isFieldFocused = false
        isURLFocused = false

        withAnimation(.easeInOut(duration: 0.5)) {
            isLoggedIn = true
        }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

import SwiftUI

struct LoginView: View {

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var inputId: String = ""
    @State private var inputTimetableURL: String = ""

    @State private var showError: Bool = false
    @State private var shakeTrigger: Int = 0
    @State private var caretOn: Bool = true

    @FocusState private var isFieldFocused: Bool

    private let digitCount = 8
    private let minDigits = 7

    private let exampleURL = "https://urnik.fri.uni-lj.si/timetable/fri-2026_2027-zimski"

    private var isStudentIdValid: Bool {
        inputId.count >= minDigits
    }

    private var isURLValid: Bool {
        guard let url = URL(string: inputTimetableURL),
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

            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isFieldFocused = false
                }

            VStack(spacing: 0) {
                Spacer()

                header
                    .padding(.bottom, 44)

                digitField
                    .padding(.horizontal, 20)

                timetableURLField
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                errorLabel
                    .padding(.top, 14)

                Spacer()

                loginButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
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
        VStack(spacing: 16) {
            Image("icon")
                .resizable()
                .frame(width: 72, height: 72)
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 14,
                    y: 6
                )

            VStack(spacing: 6) {
                Text("FRI")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Vnesite vpisno številko za nadaljevanje")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var digitField: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Vpisna številka")
                .font(.headline)

            HStack(spacing: 8) {
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
            ) { content, offset in content.offset(x: offset) } keyframes: { _ in
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

        let isActive =
            isFieldFocused &&
            index == min(inputId.count, digitCount - 1)

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                Color(.secondarySystemGroupedBackground)
            )
            RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                borderColor(isActive: isActive),
                lineWidth: isActive ? 2 : 1
            )

            if let digit {
                Text(digit)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .transition(
                        .scale(scale: 0.5)
                        .combined(with: .opacity)
                    )

            } else if isActive {
                Capsule()
                    .fill(Color.primary)
                    .frame(width: 2, height: 22)
                    .opacity(caretOn ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .shadow(
            color: .black.opacity(0.04),
            radius: 6,
            y: 2
        )
        .scaleEffect(
            isActive ? 1.04 : 1
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: inputId
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.8),
            value: isFieldFocused
        )
    }

    private func borderColor(isActive: Bool) -> Color {
        if showError && !isStudentIdValid {
            return .red.opacity(0.7)
        }
        return isActive ? .primary : Color.primary.opacity(0.08)
    }

    private var timetableURLField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URNIK povezava")
                .font(.headline)

            TextField(
                "Prilepite URNIK povezavo",
                text: $inputTimetableURL
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textFieldStyle(.roundedBorder)
            .onChange(of: inputTimetableURL) { _, _ in
                if showError && isValid {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showError = false
                    }
                }
            }

            Text("Primer: \(exampleURL)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if showError {
            VStack(spacing: 6) {
                if !isStudentIdValid {
                    Label(
                        "Vnesite vsaj \(minDigits) številk vpisne številke",
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.red)
                }

                if !isURLValid {
                    Label(
                        "Vnesite veljavno URNIK povezavo",
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.red)
                }
            }
            .transition(
                .opacity.combined(
                    with: .move(edge: .top)
                )
            )
        }
    }

    private var loginButton: some View {
        Button(action: handleLogin) {
            Text("Prijava")
                .font(.headline)
                .foregroundStyle(
                    isValid
                        ? Color(.systemBackground)
                        : Color.secondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .fill(
                        isValid
                            ? Color.primary
                            : Color.primary.opacity(0.1)
                    )
                )
        }
        .buttonStyle(PressableButtonStyle())
        .animation(
            .easeInOut(duration: 0.2),
            value: isValid
        )
    }

    private func getDigit(at index: Int) -> String? {
        guard index < inputId.count else {
            return nil
        }

        return String(
            inputId[
                inputId.index(
                    inputId.startIndex,
                    offsetBy: index
                )
            ]
        )
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
            inputTimetableURL.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        showError = false
        isFieldFocused = false

        withAnimation(.easeInOut(duration: 0.5)) {
            isLoggedIn = true
        }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

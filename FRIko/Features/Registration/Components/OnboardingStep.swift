import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome, about, school, studentId, calendar, summary
}

final class OnboardingData: ObservableObject {
    @Published var school = ""
    @Published var studentId = ""
    @Published var timetableURL = ""

    var isStudentIdValid: Bool { studentId.count >= 7 }
    var isURLValid: Bool { Self.isValidTimetableURL(timetableURL) }

    static func isValidTimetableURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "urnik.fri.uni-lj.si"
        else { return false }

        return url.path.lowercased().hasPrefix("/timetable/")
    }
}

struct TwoToneTitle: View {
    let dark: String
    let light: String
    var size: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dark)
                .foregroundStyle(Theme.Palette.ink)
            Text(light)
                .foregroundStyle(Theme.Palette.inkTertiary)
        }
        .themeFont(ThemeFont(size: size, weight: .bold, style: .largeTitle))
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

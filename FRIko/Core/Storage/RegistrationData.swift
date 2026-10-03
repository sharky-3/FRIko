import SwiftUI
import Combine

final class RegistrationData: ObservableObject {
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

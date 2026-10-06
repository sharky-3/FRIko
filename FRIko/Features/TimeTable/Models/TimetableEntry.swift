import Foundation
import SwiftUI

struct TimetableEntry: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let tag: String
    let classroom: String
    let durration: Int
    let rawStart: String
    let type: String
    let teachers: [String]
    var dayOfWeek: DayOfWeek = .monday
    var ects: Int? { 6 }
    var lecturerEmail: String? { "predavatelj@fri.uni-lj.si" }
    var lecturer: String {
        teachers.joined(separator: ", ")
    }
    var subject: String {
        name
            .components(separatedBy: "_")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? name
    }
    
    var start: String {
        Self.add(minutes: 15, to: rawStart)
    }
    
    var end: String {
        Self.add(minutes: durration * 60, to: rawStart)
    }
    
    var time: String { "\(start) – \(end)" }

    private static func add(minutes: Int, to time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return time }
        let total = h * 60 + m + minutes
        return String(format: "%02d:%02d", (total / 60) % 24, total % 60)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, tag, classroom, durration, type, teachers
        case rawStart = "start"
    }
    
    var subjectColor: Color {
        SubjectColorManager.shared.color(for: subject)
    }
}

enum DayOfWeek: String, Codable, CaseIterable, Identifiable {
    case monday = "Pon"
    case tuesday = "Tor"
    case wednesday = "Sre"
    case thursday = "Čet"
    case friday = "Pet"
    var id: String { self.rawValue }
    
    static func from(apiKey: String) -> DayOfWeek {
        switch apiKey.uppercased() {
        case "MON": return .monday
        case "TUE": return .tuesday
        case "WED": return .wednesday
        case "THU": return .thursday
        case "FRI": return .friday
        default: return .monday
        }
    }
    
    static func today() -> DayOfWeek {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        switch weekday {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .friday
        }
    }
}

final class SubjectColorManager {
    static let shared = SubjectColorManager()
    
    private let palette: [Color] = [
        Color(hex: "ffff45"),
        Color(hex: "ff5238"),
        Color(hex: "ff80c5"),
        Color(hex: "43beaf"),
        Color(hex: "8f8ac4"),
        Color(hex: "b8b8b8"),
        Color(hex: "95d94e"),
        Color(hex: "569fdc")
    ]
    
    private var assignedColors: [String: Color] = [:]
    
    func color(for subject: String) -> Color {
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = assignedColors[trimmed] {
            return existing
        }
        let nextColor = palette[assignedColors.count % palette.count]
        assignedColors[trimmed] = nextColor
        return nextColor
    }
}

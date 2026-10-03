import Foundation

final class StudentStorage {

    static let shared = StudentStorage()

    private init() {}

    private let studentIDKey = "studentID"
    private let timetableURLKey = "timetableURL"


    var studentId: String? {
        get {
            UserDefaults.standard.string(forKey: studentIDKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: studentIDKey)
        }
    }

    var timetableURL: String? {
        get {
            UserDefaults.standard.string(forKey: timetableURLKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: timetableURLKey)
        }
    }

    func clearStudentId() {
        UserDefaults.standard.removeObject(forKey: studentIDKey)
    }

    func clearTimetableURL() {
        UserDefaults.standard.removeObject(forKey: timetableURLKey)
    }

    func clearAll() {
        clearStudentId()
        clearTimetableURL()
    }
}

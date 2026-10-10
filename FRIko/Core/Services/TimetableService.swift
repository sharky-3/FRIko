import Foundation

struct TimetableService {

    static let shared = TimetableService()

    private init() {}

    func fetchTimetable() async throws -> [TimetableEntry] {

        guard let studentId = StudentStorage.shared.studentId,
              !studentId.isEmpty else {
            throw TimetableError.missingStudentId
        }

        guard let savedURL = StudentStorage.shared.timetableURL,
              !savedURL.isEmpty else {
            throw TimetableError.missingURL
        }

        let baseURL = savedURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let jsonURLString =
            "\(baseURL)/allocations.json?student=\(studentId)&mode=ext"

        guard let url = URL(string: jsonURLString) else {
            throw TimetableError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TimetableError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TimetableError.serverError(
                httpResponse.statusCode
            )
        }

        do {
            let timetable = try JSONDecoder().decode(
                [String: [TimetableEntry]].self,
                from: data
            )

            var entries: [TimetableEntry] = []
            for (dayKey, dayEntries) in timetable {
                let dayOfWeek = DayOfWeek.from(apiKey: dayKey)
                
                for var entry in dayEntries {
                    entry.dayOfWeek = dayOfWeek
                    entries.append(entry)
                }
            }

            return entries.sorted {
                $0.start < $1.start
            }

        } catch {

            print("Failed to decode timetable JSON")
            print("URL:", jsonURLString)
            print("Error:", error)

            if let responseString = String(
                data: data,
                encoding: .utf8
            ) {
                print("Response:")
                print(responseString)
            }

            throw TimetableError.decodingError
        }
    }
}

enum TimetableError: LocalizedError {

    case missingStudentId
    case missingURL
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError

    var errorDescription: String? {

        switch self {

        case .missingStudentId:
            return "Vpisna številka ni shranjena."

        case .missingURL:
            return "URNIK povezava ni shranjena."

        case .invalidURL:
            return "URNIK povezava ni veljavna."

        case .invalidResponse:
            return "Neveljaven odgovor URNIK strežnika."

        case .serverError(let statusCode):
            return "URNIK je vrnil napako \(statusCode)."

        case .decodingError:
            return "Podatkov urnika ni bilo mogoče prebrati."
        }
    }
}

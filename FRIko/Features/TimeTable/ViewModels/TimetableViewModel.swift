import Foundation
import SwiftUI
import Combine

@MainActor
final class TimetableViewModel: ObservableObject {
    @Published var entries: [TimetableEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadTimetable() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }
        do {
            entries = try await TimetableService.shared.fetchTimetable()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        await loadTimetable()
    }
}

import SwiftUI

struct Block: Identifiable {
    let entry: TimetableEntry
    let start: Double
    var end: Double
    
    var id: String { "\(entry.id)-\(start)" }
}

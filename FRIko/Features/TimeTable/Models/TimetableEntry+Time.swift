import Foundation

extension TimetableEntry {

    /// Start and end as fractional hours (08:30 → 8.5).
    var hourRange: (start: Double, end: Double)? {
        let nums = time
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Double($0) }

        var start: Double?
        var end: Double?

        if nums.count >= 4 {
            start = nums[0] + nums[1] / 60
            end = nums[2] + nums[3] / 60
        } else if nums.count == 2 {
            start = nums[0]
            end = nums[1]
        }

        if start == nil, let hour = Int(self.start.prefix(2)) {
            start = Double(hour)
        }

        guard let start else { return nil }

        let finalEnd = end.flatMap { $0 > start ? $0 : nil } ?? start + 1
        return (start, finalEnd)
    }
}

enum TimeFormat {

    /// Fractional hours since midnight for a date.
    static func hours(of date: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
    }

    /// 8.5 → "08:30"
    static func clock(_ value: Double) -> String {
        let h = Int(value)
        let m = Int(((value - Double(h)) * 60).rounded())
        return String(format: "%02d:%02d", h, m)
    }

    /// Total hours rounded to the nearest half, with a decimal comma.
    static func total(_ hours: Double) -> String {
        let rounded = (hours * 2).rounded() / 2
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",")
    }
}

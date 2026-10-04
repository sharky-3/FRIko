import SwiftUI

private struct Rise: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 22)
            .blur(radius: shown ? 0 : 6)
            .onAppear {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(delay)) {
                    shown = true
                }
            }
    }
}

private extension View {
    func rise(_ delay: Double = 0) -> some View {
        modifier(Rise(delay: delay))
    }
}

private struct DrawHairline: View {
    var delay: Double = 0
    @State private var drawn = false

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
            .scaleEffect(x: drawn ? 1 : 0, anchor: .leading)
            .onAppear {
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(delay)) {
                    drawn = true
                }
            }
    }
}

struct ClassDetailView: View {
    let entry: TimetableEntry
    let allEntries: [TimetableEntry]

    private struct Slot: Identifiable {
        let entry: TimetableEntry
        let start: Double
        var end: Double

        var id: String { "\(entry.dayOfWeek.rawValue)-\(start)" }
    }

    private var relatedEntries: [TimetableEntry] {
        allEntries.filter { $0.subject == entry.subject }
    }

    private var slots: [Slot] {
        let items = relatedEntries
            .compactMap { e -> Slot? in
                guard let r = timeRange(for: e) else { return nil }
                return Slot(entry: e, start: r.start, end: r.end)
            }
            .sorted { a, b in
                let ia = DayOfWeek.allCases.firstIndex(of: a.entry.dayOfWeek) ?? 0
                let ib = DayOfWeek.allCases.firstIndex(of: b.entry.dayOfWeek) ?? 0
                return ia == ib ? a.start < b.start : ia < ib
            }

        var result: [Slot] = []
        for item in items {
            if let last = result.last,
               last.entry.dayOfWeek == item.entry.dayOfWeek,
               last.entry.type == item.entry.type,
               last.entry.classroom == item.entry.classroom,
               abs(last.end - item.start) < 0.01 {
                result[result.count - 1].end = item.end
            } else {
                result.append(item)
            }
        }
        return result
    }

    private var totalHours: Double {
        slots.reduce(0) { $0 + ($1.end - $1.start) }
    }

    private var hoursText: String {
        let rounded = (totalHours * 2).rounded() / 2
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",")
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topRow
                        .rise(0.05)

                    Text(entry.subject)
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.black)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .rise(0.15)

                    stat
                        .padding(.top, 28)
                        .rise(0.25)

                    if !entry.lecturer.isEmpty {
                        lecturerSection
                            .padding(.top, 32)
                            .rise(0.35)
                    }

                    Spacer(minLength: 40)

                    scheduleSection
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.black)
        .preferredColorScheme(.light)
    }

    private var topRow: some View {
        HStack {
            Text(entry.ects.map { "\($0) ECTS" } ?? "PREDMET")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            Spacer()

            Text(entry.type.uppercased())
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
    }

    private var stat: some View {
        VStack(alignment: .leading, spacing: 0) {
            DrawHairline(delay: 0.3)
                .padding(.bottom, 22)

            Text("TEDENSKO")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color(white: 0.6))

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(hoursText)
                    .font(.system(size: 72, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("ur")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color(white: 0.5))
            }
            .padding(.top, 10)

            Text("\(slots.count) \(slots.count == 1 ? "termin" : "terminov")")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.5))
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
    }

    private var lecturerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("PREDAVATELJ")

            Text(entry.lecturer)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }

    private var scheduleSection: some View {
        let entryStart = timeRange(for: entry)?.start ?? 0

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionLabel("URNIK")

                Spacer()

                Text(String(format: "%02d", slots.count))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(white: 0.6))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .rise(0.4)

            DrawHairline(delay: 0.45)

            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                let isCurrent = slot.entry.dayOfWeek == entry.dayOfWeek
                    && entryStart >= slot.start - 0.01
                    && entryStart < slot.end

                scheduleRow(slot, isCurrent: isCurrent)
                    .rise(0.5 + Double(index) * 0.08)

                DrawHairline(delay: 0.55 + Double(index) * 0.08)
            }
        }
    }

    private func scheduleRow(_ slot: Slot, isCurrent: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isCurrent ? Color.black : Color.clear)
                        .frame(width: 6, height: 6)

                    Text(slot.entry.dayOfWeek.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                }

                Text(slot.entry.type)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .padding(.leading, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(slot.entry.classroom)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.55))
                    .lineLimit(1)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(formatted(slot.start))
                        .font(.system(size: 26, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(.black)

                    Text("– \(formatted(slot.end))")
                        .font(.system(size: 13))
                        .monospacedDigit()
                        .foregroundStyle(Color(white: 0.55))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Color(white: 0.6))
    }

    private func formatted(_ value: Double) -> String {
        let h = Int(value)
        let m = Int(((value - Double(h)) * 60).rounded())
        return String(format: "%02d:%02d", h, m)
    }

    private func timeRange(for entry: TimetableEntry) -> (start: Double, end: Double)? {
        let nums = entry.time
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

        if start == nil, let hour = Int(entry.start.prefix(2)) {
            start = Double(hour)
        }

        guard let start else { return nil }

        let finalEnd = end.flatMap { $0 > start ? $0 : nil } ?? start + 1
        return (start, finalEnd)
    }
}

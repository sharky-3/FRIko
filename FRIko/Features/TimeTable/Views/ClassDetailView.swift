import SwiftUI

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
                guard let r = e.hourRange else { return nil }
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
        TimeFormat.total(totalHours)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topRow
                        .rise(0.05)

                    Text(entry.subject)
                        .themeFont(.display)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Theme.Space.page)
                        .padding(.top, 24)
                        .rise(0.1)

                    stat
                        .padding(.top, 28)
                        .rise(0.15)

                    if !entry.lecturer.isEmpty {
                        lecturerSection
                            .padding(.top, 32)
                            .rise(0.2)
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
        .background(Theme.Palette.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(Theme.Palette.ink)
        .preferredColorScheme(.light)
    }

    private var topRow: some View {
        HStack {
            MetaTag(entry.ects.map { "\($0) ECTS" } ?? "PREDMET")

            Spacer()

            MetaText(entry.type.uppercased())
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Space.page)
    }

    private var stat: some View {
        VStack(alignment: .leading, spacing: 0) {
            Hairline(delay: 0.2)
                .padding(.bottom, 22)

            Eyebrow("TEDENSKO")

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(hoursText)
                    .themeFont(.numeralL)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("ur")
                    .themeFont(.unit)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            .padding(.top, 8)

            Text("\(slots.count) \(slots.count == 1 ? "termin" : "terminov")")
                .themeFont(.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .padding(.top, 2)
        }
        .padding(.horizontal, Theme.Space.page)
        .accessibilityElement(children: .combine)
    }

    private var lecturerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("PREDAVATELJ")

            Text(entry.lecturer)
                .themeFont(.headline)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Theme.Space.page)
    }

    private var scheduleSection: some View {
        let entryStart = entry.hourRange?.start ?? 0

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("URNIK")

                Spacer()

                Text(String(format: "%02d", slots.count))
                    .themeFont(.mono)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.bottom, 10)
            .rise(0.25)

            Hairline(delay: 0.3)

            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                let isCurrent = slot.entry.dayOfWeek == entry.dayOfWeek
                    && entryStart >= slot.start - 0.01
                    && entryStart < slot.end

                scheduleRow(slot, isCurrent: isCurrent)
                    .rise(0.3 + Double(index) * 0.05)

                Hairline(delay: 0.35 + Double(index) * 0.05)
            }
        }
    }

    private func scheduleRow(_ slot: Slot, isCurrent: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isCurrent ? Theme.Palette.brand : Color.clear)
                        .frame(width: 6, height: 6)

                    Text(slot.entry.dayOfWeek.rawValue)
                        .themeFont(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Palette.ink)
                }

                Text(slot.entry.type)
                    .themeFont(.callout)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .padding(.leading, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(slot.entry.classroom)
                    .themeFont(.callout)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(TimeFormat.clock(slot.start))
                        .themeFont(.numeralS)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.ink)

                    Text("– \(TimeFormat.clock(slot.end))")
                        .themeFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
    }
}

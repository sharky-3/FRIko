import SwiftUI

private struct WeekBlockView: View {
    let block: Block
    let width: CGFloat
    let rowHeight: CGFloat
    let gap: CGFloat
    let isLive: Bool
    let isPast: Bool
    let progress: CGFloat

    var body: some View {
        let entry = block.entry
        let height = max(CGFloat(block.end - block.start) * rowHeight - gap * 2, 24)
        let isCompact = height < 46
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.block, style: .continuous)

        VStack(alignment: .leading, spacing: 2) {
            Text(entry.tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if !isCompact {
                Text(entry.classroom)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)

                Text(entry.type)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(
            shape.fill(isLive ? Theme.Palette.brand.opacity(0.14) : Theme.Palette.wash)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(entry.subjectColor)
                .frame(width: 3)
        }
        .overlay(alignment: .topTrailing) {
            if isLive {
                PulseDot(size: 4)
                    .padding(7)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if isLive {
                Rectangle()
                    .fill(Theme.Palette.brand)
                    .frame(width: width * progress, height: 2)
            }
        }
        .clipShape(shape)
        .opacity(isPast ? 0.5 : 1)
        .contentShape(shape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.subject), \(entry.type)")
        .accessibilityValue("\(entry.time), \(entry.classroom)")
    }
}

struct WeeklyTimetableView: View {
    @ObservedObject var viewModel: TimetableViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var barsIn = false

    private let days: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    private let firstHour = 7
    private let lastHour = 17
    private let rowHeight: CGFloat = 60
    private let timeWidth: CGFloat = 40
    private let gap: CGFloat = 2
    private let horizontalPadding: CGFloat = 12

    private var hours: [Int] { Array(firstHour...lastHour) }

    var body: some View {
        ZStack {
            NavigationStack {
                GeometryReader { proxy in
                    let availableWidth = proxy.size.width - timeWidth - horizontalPadding * 2
                    let colWidth = max(0, availableWidth / CGFloat(days.count))

                    VStack(alignment: .leading, spacing: 0) {
                        topRow
                            .padding(.top, 18)
                            .rise(0.05)

                        hero
                            .padding(.top, 16)
                            .rise(0.12)

                        header(colWidth: colWidth)
                            .padding(.top, 14)
                            .rise(0.2)

                        ScrollView(.vertical, showsIndicators: false) {
                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                grid(colWidth: colWidth, date: context.date)
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 140)
                        }
                    }
                }
                .background(Theme.Palette.canvas)
                .toolbar(.hidden, for: .navigationBar)
            }
            .tint(Theme.Palette.ink)

            bottomFade
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
        }
        .preferredColorScheme(.light)
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            barsIn = true
        }
    }

    // MARK: - Header

    private var topRow: some View {
        HStack {
            MetaTag(StudentStorage.shared.studentId ?? "-")

            Spacer()

            MetaText(weekRange)
        }
        .padding(.horizontal, horizontalPadding + 8)
    }

    private var weekRange: String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current

        guard let monday = cal.dateInterval(of: .weekOfYear, for: Date())?.start,
              let friday = cal.date(byAdding: .day, value: 4, to: monday)
        else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "d. M."
        return "\(formatter.string(from: monday)) – \(formatter.string(from: friday))"
    }

    private var loads: [(day: DayOfWeek, hours: Double)] {
        days.map { day in
            (day, blocks(for: day).reduce(0) { $0 + ($1.end - $1.start) })
        }
    }

    private var hero: some View {
        let loads = loads
        let total = loads.reduce(0) { $0 + $1.hours }
        let peak = max(loads.map(\.hours).max() ?? 1, 1)
        let slotCount = days.reduce(0) { $0 + blocks(for: $1).count }
        let subjectCount = Set(
            viewModel.entries
                .filter { days.contains($0.dayOfWeek) }
                .map(\.subject)
        ).count

        return HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("TA TEDEN")

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(TimeFormat.total(total))
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

                Text("\(slotCount) terminov · \(subjectCount) predmetov")
                    .themeFont(.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            chart(loads, peak: peak)
        }
        .padding(.horizontal, horizontalPadding + 8)
    }

    private func chart(_ loads: [(day: DayOfWeek, hours: Double)], peak: Double) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(loads.enumerated()), id: \.offset) { index, item in
                let isToday = item.day == DayOfWeek.today()
                let target = max(CGFloat(item.hours / peak) * 52, 4)
                let animation: Animation? = reduceMotion
                    ? nil
                    : Motion.enter.delay(Double(index) * 0.05)

                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isToday ? Theme.Palette.brand : Theme.Palette.ink.opacity(0.15))
                        .frame(width: 6, height: barsIn ? target : 4)
                        .animation(animation, value: barsIn)

                    Text(String(item.day.rawValue.prefix(1)).uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(isToday ? Theme.Palette.ink : Theme.Palette.inkTertiary)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var bottomFade: some View {
        LinearGradient(
            colors: [Theme.Palette.canvas.opacity(0), Theme.Palette.canvas],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 64)
        .ignoresSafeArea()
    }

    private func header(colWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: timeWidth)

            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                let isToday = day == DayOfWeek.today()

                VStack(spacing: 6) {
                    Text(day.rawValue.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(isToday ? Theme.Palette.ink : Theme.Palette.inkTertiary)

                    Text("\(dayNumber(at: index))")
                        .font(.system(size: 16, weight: isToday ? .semibold : .regular))
                        .monospacedDigit()
                        .foregroundStyle(isToday ? Color.white : Theme.Palette.ink)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isToday ? Theme.Palette.accent : Color.clear)
                        )
                }
                .frame(width: colWidth)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { Hairline(delay: 0.25) }
        .frame(maxHeight: 55)
    }

    private func dayNumber(at index: Int) -> Int {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        guard let monday = cal.dateInterval(of: .weekOfYear, for: Date())?.start,
              let date = cal.date(byAdding: .day, value: index, to: monday)
        else { return 0 }
        return cal.component(.day, from: date)
    }

    // MARK: - Grid

    private func grid(colWidth: CGFloat, date: Date) -> some View {
        ZStack(alignment: .topLeading) {
            todayTint(colWidth: colWidth)

            hourLines

            HStack(alignment: .top, spacing: 0) {
                Color.clear.frame(width: timeWidth)

                ForEach(Array(days.enumerated()), id: \.element) { index, day in
                    dayColumn(day, index: index, colWidth: colWidth, date: date)
                }
            }

            nowIndicator(colWidth: colWidth, date: date)
        }
        .frame(width: timeWidth + colWidth * CGFloat(days.count), alignment: .topLeading)
        .padding(.top, 16)
    }

    @ViewBuilder
    private func todayTint(colWidth: CGFloat) -> some View {
        if let index = days.firstIndex(of: DayOfWeek.today()) {
            Rectangle()
                .fill(Theme.Palette.wash.opacity(0.6))
                .frame(width: colWidth, height: rowHeight * CGFloat(hours.count))
                .offset(x: timeWidth + colWidth * CGFloat(index))
        }
    }

    private var hourLines: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Theme.Palette.hairline.opacity(0.7))
                        .frame(height: 0.5)
                        .padding(.leading, timeWidth)

                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.inkTertiary)
                        .frame(width: timeWidth - 6, alignment: .trailing)
                        .offset(y: -7)
                }
                .frame(height: rowHeight, alignment: .top)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func nowIndicator(colWidth: CGFloat, date: Date) -> some View {
        let time = TimeFormat.hours(of: date)

        if let todayIndex = days.firstIndex(of: DayOfWeek.today()),
           time >= Double(firstHour), time <= Double(lastHour + 1) {
            let y = (time - Double(firstHour)) * rowHeight
            let xStart = timeWidth + colWidth * CGFloat(todayIndex)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Theme.Palette.signal.opacity(0.18))
                    .frame(width: colWidth * CGFloat(days.count), height: 0.5)
                    .offset(x: timeWidth, y: -0.25)

                Rectangle()
                    .fill(Theme.Palette.signal)
                    .frame(width: colWidth, height: 1)
                    .offset(x: xStart, y: -0.5)

                Circle()
                    .fill(Theme.Palette.signal)
                    .frame(width: 7, height: 7)
                    .offset(x: xStart - 3.5, y: -3.5)

                Text(TimeFormat.clock(time))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.Palette.signal)
                    .padding(.horizontal, 3)
                    .background(Theme.Palette.canvas)
                    .frame(width: timeWidth - 2, alignment: .trailing)
                    .offset(y: -8)
            }
            .offset(y: y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func dayColumn(_ day: DayOfWeek, index: Int, colWidth: CGFloat, date: Date) -> some View {
        let now = TimeFormat.hours(of: date)
        let todayIndex = days.firstIndex(of: DayOfWeek.today())
        let isToday = day == DayOfWeek.today()
        let isPastDay = todayIndex.map { index < $0 } ?? false

        return ZStack(alignment: .topLeading) {
            Color.clear.frame(width: colWidth, height: rowHeight * CGFloat(hours.count))

            ForEach(blocks(for: day)) { block in
                let isLive = isToday && now >= block.start && now < block.end
                let isPast = isPastDay || (isToday && now >= block.end)
                let progress: CGFloat = isLive
                    ? CGFloat(min(max((now - block.start) / (block.end - block.start), 0), 1))
                    : 0

                NavigationLink {
                    ClassDetailView(entry: block.entry, allEntries: viewModel.entries)
                } label: {
                    WeekBlockView(
                        block: block,
                        width: max(0, colWidth - gap * 2),
                        rowHeight: rowHeight,
                        gap: gap,
                        isLive: isLive,
                        isPast: isPast,
                        progress: progress
                    )
                }
                .buttonStyle(PressableStyle())
                .offset(x: gap, y: CGFloat(block.start - Double(firstHour)) * rowHeight + gap)
            }
        }
        .frame(width: colWidth)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.Palette.hairline.opacity(0.5))
                .frame(width: 0.5)
                .accessibilityHidden(true)
        }
        .rise(0.25 + Double(index) * 0.05)
    }

    // MARK: - Data

    private func blocks(for day: DayOfWeek) -> [Block] {
        let items: [Block] = viewModel.entries
            .filter { $0.dayOfWeek == day }
            .compactMap { entry in
                guard let r = entry.hourRange else { return nil }
                return Block(entry: entry, start: r.start, end: r.end)
            }
            .sorted { $0.start < $1.start }

        var result: [Block] = []
        for item in items {
            if let last = result.last {
                let sameClass = last.entry.subject == item.entry.subject &&
                                last.entry.type == item.entry.type &&
                                last.entry.classroom == item.entry.classroom
                if sameClass && abs(last.end - item.start) < 0.01 {
                    result[result.count - 1].end = item.end
                    continue
                }
                if item.start < last.end - 0.01 {
                    continue
                }
            }
            result.append(item)
        }
        return result
    }
}

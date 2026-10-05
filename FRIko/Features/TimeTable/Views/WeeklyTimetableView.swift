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

private struct PulseDot: View {
    var color: Color = .black
    var size: CGFloat = 6
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .scaleEffect(pulse ? 3 : 1)
                .opacity(pulse ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

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
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        VStack(alignment: .leading, spacing: 2) {
            Text(entry.tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if !isCompact {
                Text(entry.classroom)
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .lineLimit(1)

                Text(entry.type)
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, 11)
        .padding(.trailing, 6)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(
            shape.fill(isLive ? entry.subjectColor.opacity(0.5) : .black.opacity(0.04))
        )
        .overlay(
            shape.strokeBorder(.black.opacity(isLive ? 0 : 0.16), lineWidth: 0.5)
        )
        .overlay(alignment: .leading) {
            Capsule()
                .fill(AnyShapeStyle(entry.subjectColor.gradient))
                .frame(width: 2.5)
                .padding(.vertical, 6)
                .padding(.leading, 3)
        }
        .overlay(alignment: .topTrailing) {
            if isLive {
                PulseDot(color: .white, size: 4)
                    .frame(width: 4, height: 4)
                    .padding(8)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if isLive {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: width * progress, height: 1.5)
            }
        }
        .clipShape(shape)
        .shadow(color: .clear, radius: 8, y: 4)
        .opacity(isPast ? 0.4 : 1)
        .contentShape(shape)
    }
}

struct WeeklyTimetableView: View {
    @ObservedObject var viewModel: TimetableViewModel

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
                            .rise(0.15)

                        header(colWidth: colWidth)
                            .padding(.top, 14)
                            .rise(0.3)

                        ScrollView(.vertical, showsIndicators: false) {
                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                grid(colWidth: colWidth, date: context.date)
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 140)
                        }
                    }
                }
                .background(Color.white)
                .toolbar(.hidden, for: .navigationBar)
            }

            bottomBlur
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
        }
        .preferredColorScheme(.light)
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            barsIn = true
        }
    }
    
    private var topRow: some View {
        HStack {
            Text(StudentStorage.shared.studentId ?? "-")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            Spacer()

            Text(weekRange)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))
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

    private func hoursText(_ total: Double) -> String {
        let rounded = (total * 2).rounded() / 2
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",")
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
                Text("TA TEDEN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color(white: 0.6))

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(hoursText(total))
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

                Text("\(slotCount) terminov · \(subjectCount) predmetov")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.5))
                    .lineLimit(1)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            chart(loads, peak: peak)
        }
        .padding(.horizontal, horizontalPadding + 8)
    }

    private func chart(_ loads: [(day: DayOfWeek, hours: Double)], peak: Double) -> some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(loads.enumerated()), id: \.offset) { index, item in
                let isToday = item.day == DayOfWeek.today()
                let target = max(CGFloat(item.hours / peak) * 52, 4)

                VStack(spacing: 6) {
                    Capsule()
                        .fill(isToday ? Color.black : Color.black.opacity(0.15))
                        .frame(width: 6, height: barsIn ? target : 4)
                        .animation(
                            .timingCurve(0.16, 1, 0.3, 1, duration: 1.0).delay(Double(index) * 0.06),
                            value: barsIn
                        )

                    Text(String(item.day.rawValue.prefix(1)).uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(isToday ? Color.black : Color(white: 0.6))
                }
            }
        }
    }

    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)

        return shape
            .fill(Color(white: 0.07))
            .overlay(
                RadialGradient(
                    colors: [Color.white.opacity(0.14), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 260
                )
                .clipShape(shape)
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            )
    }

    private var bottomBlur: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 75)
        .ignoresSafeArea()
        .blur(radius: 20)
    }
    
    private func header(colWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: timeWidth)

            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                let isToday = day == DayOfWeek.today()

                VStack(spacing: 6) {
                    Text(day.rawValue.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(isToday ? Color.black : Color(white: 0.6))

                    Text("\(dayNumber(at: index))")
                        .font(.system(size: 16, weight: isToday ? .medium : .light))
                        .monospacedDigit()
                        .foregroundStyle(isToday ? Color.white : Color.black)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(isToday ? Color.black : Color.clear))
                }
                .frame(width: colWidth)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { DrawHairline(delay: 0.4) }
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
                .fill(Color.black.opacity(0.025))
                .frame(width: colWidth, height: rowHeight * CGFloat(hours.count))
                .offset(x: timeWidth + colWidth * CGFloat(index))
        }
    }

    private var hourLines: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(height: 0.5)
                        .padding(.leading, timeWidth)

                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 10, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(Color(white: 0.55))
                        .frame(width: timeWidth - 8, alignment: .trailing)
                        .offset(y: -6)
                }
                .frame(height: rowHeight, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func nowIndicator(colWidth: CGFloat, date: Date) -> some View {
        let time = minutes(of: date)

        if let todayIndex = days.firstIndex(of: DayOfWeek.today()),
           time >= Double(firstHour), time <= Double(lastHour + 1) {
            let y = (time - Double(firstHour)) * rowHeight
            let xStart = timeWidth + colWidth * CGFloat(todayIndex)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.red.opacity(0.18))
                    .frame(width: colWidth * CGFloat(days.count), height: 0.5)
                    .offset(x: timeWidth, y: -0.25)

                Rectangle()
                    .fill(Color.red)
                    .frame(width: colWidth, height: 1)
                    .offset(x: xStart, y: -0.5)

                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .offset(x: xStart - 3.5, y: -3.5)

                // Live time on the axis
                Text(formatted(time))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 3)
                    .background(Color.white)
                    .frame(width: timeWidth - 4, alignment: .trailing)
                    .offset(y: -7)
            }
            .offset(y: y)
            .allowsHitTesting(false)
        }
    }

    private func dayColumn(_ day: DayOfWeek, index: Int, colWidth: CGFloat, date: Date) -> some View {
        let now = minutes(of: date)
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
                .buttonStyle(.plain)
                .offset(x: gap, y: CGFloat(block.start - Double(firstHour)) * rowHeight + gap)
            }
        }
        .frame(width: colWidth)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 0.5)
        }
        .rise(0.4 + Double(index) * 0.07)
    }

    private func minutes(of date: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
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

        if start == nil, let h = Int(entry.start.prefix(2)) {
            start = Double(h)
        }

        guard let s = start else { return nil }
        let e = (end ?? 0) > s ? end! : s + 1
        return (s, e)
    }

    private func blocks(for day: DayOfWeek) -> [Block] {
        let items: [Block] = viewModel.entries
            .filter { $0.dayOfWeek == day }
            .compactMap { entry in
                guard let r = timeRange(for: entry) else { return nil }
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

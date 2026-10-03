import SwiftUI

struct WeeklyTimetableView: View {
    @ObservedObject var viewModel: TimetableViewModel
    
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
                        titleSection
                        
                        header(colWidth: colWidth)
                        
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
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(StudentStorage.shared.studentId ?? "-")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))
            
            HStack(spacing: 0) {
                Text("Tedenski ")
                    .foregroundColor(.black)
                Text("pregled")
                    .foregroundColor(Color(white: 0.6))
            }
            .font(.system(size: 36, weight: .bold, design: .serif))
        }
        .padding(.horizontal, horizontalPadding + 8)
        .padding(.top, 12)
        .padding(.bottom, 20)
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
        .overlay(alignment: .bottom) { hairline }
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
    
    private var hairline: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
    }
    
    private func grid(colWidth: CGFloat, date: Date) -> some View {
        ZStack(alignment: .topLeading) {
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
            
            HStack(alignment: .top, spacing: 0) {
                Color.clear.frame(width: timeWidth)
                ForEach(days) { day in
                    dayColumn(day, colWidth: colWidth, date: date)
                }
            }
            
            nowIndicator(colWidth: colWidth, date: date)
        }
        .frame(width: timeWidth + colWidth * CGFloat(days.count), alignment: .topLeading)
        .padding(.top, 16)
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
                    .fill(Color.red)
                    .frame(width: colWidth, height: 1)
                    .offset(x: xStart, y: -0.5)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .offset(x: xStart - 3.5, y: -3.5)
            }
            .offset(y: y)
            .allowsHitTesting(false)
        }
    }
    
    private func dayColumn(_ day: DayOfWeek, colWidth: CGFloat, date: Date) -> some View {
        let now = minutes(of: date)
        let isToday = day == DayOfWeek.today()
        
        return ZStack(alignment: .topLeading) {
            Color.clear.frame(width: colWidth, height: rowHeight * CGFloat(hours.count))
            
            ForEach(blocks(for: day)) { block in
                let isLive = isToday && now >= block.start && now < block.end
                
                NavigationLink {
                    ClassDetailView(entry: block.entry, allEntries: viewModel.entries)
                } label: {
                    ClassBlockView(
                        block: block,
                        width: max(0, colWidth - gap * 2),
                        rowHeight: rowHeight,
                        gap: gap,
                        isLive: isLive
                    )
                }
                .buttonStyle(.plain)
                .offset(x: gap, y: CGFloat(block.start - Double(firstHour)) * rowHeight + gap)
            }
        }
        .frame(width: colWidth)
    }
    
    private func minutes(of date: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
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

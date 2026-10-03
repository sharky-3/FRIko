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
    
    private struct Block: Identifiable {
        let id = UUID()
        let entry: TimetableEntry
        let start: Double
        var end: Double
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                GeometryReader { proxy in
                    let availableWidth = proxy.size.width - timeWidth - horizontalPadding * 2
                    let colWidth = max(0, availableWidth / CGFloat(days.count))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HeaderTitleView(title: "tedenski pregled", position: .center)
                        
                        header(colWidth: colWidth)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            grid(colWidth: colWidth)
                                .padding(.horizontal, horizontalPadding)
                                .padding(.bottom, 140)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .toolbar(.hidden, for: .navigationBar)
            }
            
            bottomBlur
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
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
                colors: [.clear, Color(.systemBackground).opacity(0.85)],
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
                        .foregroundStyle(isToday ? Color.primary : Color.secondary)
                    
                    Text("\(dayNumber(at: index))")
                        .font(.system(size: 16, weight: isToday ? .semibold : .regular))
                        .monospacedDigit()
                        .foregroundStyle(isToday ? Color(.systemBackground) : Color.primary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(isToday ? Color.primary : Color.clear))
                }
                .frame(width: colWidth)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 10)
        .frame(maxHeight: 55)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator).opacity(0.5))
                .frame(height: 0.5)
        }
    }
    
    private func dayNumber(at index: Int) -> Int {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        guard let monday = cal.dateInterval(of: .weekOfYear, for: Date())?.start,
              let date = cal.date(byAdding: .day, value: index, to: monday)
        else { return 0 }
        return cal.component(.day, from: date)
    }
    
    private func grid(colWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color(.separator).opacity(0.35))
                            .frame(height: 0.5)
                            .padding(.leading, timeWidth)
                        
                        Text(String(format: "%02d:00", hour))
                            .font(.system(size: 10, weight: .regular))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: timeWidth - 8, alignment: .trailing)
                            .offset(y: -6)
                    }
                    .frame(height: rowHeight, alignment: .top)
                }
            }
            
            HStack(alignment: .top, spacing: 0) {
                Color.clear.frame(width: timeWidth)
                ForEach(days) { day in
                    dayColumn(day, colWidth: colWidth)
                }
            }
            
            nowIndicator(colWidth: colWidth)
        }
        .frame(width: timeWidth + colWidth * CGFloat(days.count), alignment: .topLeading)
        .padding(.top, 16)
    }
    
    private func nowIndicator(colWidth: CGFloat) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let cal = Calendar.current
            let time = Double(cal.component(.hour, from: context.date))
                + Double(cal.component(.minute, from: context.date)) / 60
            
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
    }
    
    private func dayColumn(_ day: DayOfWeek, colWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: colWidth, height: rowHeight * CGFloat(hours.count))
            
            ForEach(blocks(for: day)) { block in
                NavigationLink {
                    ClassDetailView(entry: block.entry, allEntries: viewModel.entries)
                } label: {
                    classBlock(block, width: max(0, colWidth - gap * 2))
                }
                .buttonStyle(.plain)
                .offset(x: gap, y: CGFloat(block.start - Double(firstHour)) * rowHeight + gap)
            }
        }
        .frame(width: colWidth)
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
    
    private func classBlock(_ block: Block, width: CGFloat) -> some View {
        let entry = block.entry
        let duration = block.end - block.start
        let height = max(CGFloat(duration) * rowHeight - gap * 2, 24)
        let isCompact = height < 46
        
        return VStack(alignment: .leading, spacing: 2) {
            Text(entry.tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if !isCompact {
                Text(entry.classroom)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(entry.type)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(.primary.opacity(0.06))
        .overlay(alignment: .leading) {
            Capsule()
                .fill(entry.subjectColor.gradient)
                .frame(width: 2.5)
                .padding(.vertical, 6)
                .padding(.leading, 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

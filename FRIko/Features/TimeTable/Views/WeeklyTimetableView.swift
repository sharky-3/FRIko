import SwiftUI

struct WeeklyTimetableView: View {
    @ObservedObject var viewModel: TimetableViewModel
    private let days: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    private let firstHour = 7
    private let lastHour = 17
    private let rowHeight: CGFloat = 64
    private let timeWidth: CGFloat = 48
    private let gap: CGFloat = 3
    
    private var hours: [Int] {
        Array(firstHour...lastHour)
    }
    
    private struct Block: Identifiable {
        let id = UUID()
        let entry: TimetableEntry
        let start: Double
        var end: Double
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let horizontalPadding: CGFloat = 8
                let availableWidth = proxy.size.width - timeWidth - horizontalPadding * 2
                let colWidth = max(0, availableWidth / CGFloat(days.count))
                
                VStack(spacing: 0) {
                    header(colWidth: colWidth)
                    ScrollView(.vertical, showsIndicators: false) {
                        grid(colWidth: colWidth)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 80)
                    }
                }
                .background(Color.white)
            }
            .navigationTitle("Urnik")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.white)
    }
    
    private func header(colWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: timeWidth)
            ForEach(days) { day in
                let isToday = day == DayOfWeek.today()
                Text(day.rawValue)
                    .font(.system(size: 12, weight: isToday ? .semibold : .medium))
                    .foregroundStyle(isToday ? .black : .gray)
                    .frame(width: colWidth, height: 38)
                    .overlay(alignment: .bottom) {
                        if isToday {
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 18, height: 2)
                                .offset(y: -3)
                        }
                    }
            }
        }
        .frame(height: 44)
        .background(Color.white)
    }
    
    private func grid(colWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    ZStack(alignment: .top) {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color.black.opacity(0.10))
                                .frame(height: 0.5)
                        }
                        .padding(.leading, timeWidth)
                        
                        HStack(spacing: 0) {
                            Text(String(format: "%02d:00", hour))
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(.gray)
                                .frame(width: timeWidth - 7, alignment: .trailing)
                            Spacer(minLength: 0)
                        }
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
        }
        .background(Color.white)
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
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 0.5)
        }
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
        let color = entry.subjectColor
        let height = max(CGFloat(duration) * rowHeight - gap * 2, 24)
        
        return VStack(alignment: .leading, spacing: 3) {
            Text(entry.tag)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(entry.classroom)
                .font(.system(size: 11))
                .foregroundStyle(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            if duration >= 1.5 {
                Text(entry.type)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                Text(entry.lecturer)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gray.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, 8)
        .padding(.trailing, 5)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(color.opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(Color.black.opacity(0.14), lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

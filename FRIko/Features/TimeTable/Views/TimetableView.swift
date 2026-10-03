import SwiftUI

struct TimetableView: View {

    @ObservedObject var viewModel: TimetableViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.entries.isEmpty {
                        ProgressView("Nalaganje urnika...")
                            .tint(.black)
                    } else if let errorMessage = viewModel.errorMessage,
                              viewModel.entries.isEmpty {
                        errorView(errorMessage)
                    } else {
                        mainContentView
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.loadTimetable() }
        }
        .preferredColorScheme(.light)
    }

    private var mainContentView: some View {
        let todayEntries = viewModel.entries
            .filter { $0.dayOfWeek == DayOfWeek.today() }
            .sorted { (timeRange(for: $0)?.start ?? 0) < (timeRange(for: $1)?.start ?? 0) }

        return GeometryReader { proxy in
            ScrollView {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    VStack(alignment: .leading, spacing: 0) {
                        header(entries: todayEntries, date: context.date)

                        Spacer(minLength: 48)

                        if !todayEntries.isEmpty {
                            classList(entries: todayEntries, date: context.date)
                        }
                    }
                    .frame(minHeight: proxy.size.height, alignment: .top)
                    .padding(.top, 20)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func header(entries: [TimetableEntry], date: Date) -> some View {
        let current = currentClass(in: entries, at: date)
        let entry = current ?? nextClass(in: entries, at: date)

        return VStack(alignment: .leading, spacing: 20) {
            Text(StudentStorage.shared.studentId ?? "-")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            VStack(alignment: .leading, spacing: 10) {
                Text(label(isLive: current != nil, hasEntry: entry != nil))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(white: 0.6))

                if let entry {
                    Text(entry.subject)
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.black)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(entry.time) · \(entry.classroom) · \(entry.type)")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.45))
                        .lineLimit(2)
                } else {
                    Text(entries.isEmpty ? "Danes nimaš predavanj." : "Za danes je konec.")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.black)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func label(isLive: Bool, hasEntry: Bool) -> String {
        if isLive { return "TRENUTNO IMAŠ" }
        return hasEntry ? "NASLEDNJI PREDMET" : "DANES"
    }

    private func classList(entries: [TimetableEntry], date: Date) -> some View {
        let now = minutes(of: date)
        let current = currentClass(in: entries, at: date)

        return VStack(spacing: 0) {
            hairline

            ForEach(entries) { entry in
                let range = timeRange(for: entry)
                let isLive = entry.id == current?.id
                let isPast = (range?.end ?? 0) <= now

                NavigationLink {
                    ClassDetailView(entry: entry, allEntries: viewModel.entries)
                } label: {
                    classRow(entry, start: range?.start, isLive: isLive)
                        .opacity(isPast ? 0.35 : 1)
                }
                .buttonStyle(.plain)

                hairline
            }
        }
        .padding(.bottom, 8)
    }

    private func classRow(_ entry: TimetableEntry, start: Double?, isLive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.subject)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(entry.type)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.classroom)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(white: 0.55))
                        .lineLimit(1)

                    if isLive {
                        Text("ZDAJ")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black))
                    }
                }

                Text(start.map(formatted) ?? entry.time)
                    .font(.system(size: 28, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
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

    private func currentClass(in entries: [TimetableEntry], at date: Date) -> TimetableEntry? {
        let now = minutes(of: date)
        return entries.first {
            guard let r = timeRange(for: $0) else { return false }
            return now >= r.start && now < r.end
        }
    }

    private func nextClass(in entries: [TimetableEntry], at date: Date) -> TimetableEntry? {
        let now = minutes(of: date)
        return entries.first {
            guard let r = timeRange(for: $0) else { return false }
            return r.start > now
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

        if start == nil, let hour = Int(entry.start.prefix(2)) {
            start = Double(hour)
        }

        guard let start else { return nil }

        let finalEnd = end.flatMap { $0 > start ? $0 : nil } ?? start + 1
        return (start, finalEnd)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.black)

            Text("Napaka")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Button("Poskusi znova") {
                Task { await viewModel.loadTimetable() }
            }
            .buttonStyle(.bordered)
            .tint(.black)
        }
        .padding()
    }
}

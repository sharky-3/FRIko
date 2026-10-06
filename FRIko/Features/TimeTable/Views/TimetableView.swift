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

private struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.black.opacity(configuration.isPressed ? 0.04 : 0))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct TimetableView: View {

    @ObservedObject var viewModel: TimetableViewModel

    private let timeWidth: CGFloat = 46
    private let markWidth: CGFloat = 10
    private let dotSize: CGFloat = 9

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
                        topRow(date: context.date)
                            .rise(0.05)

                        hero(entries: todayEntries, date: context.date)
                            .padding(.top, 22)
                            .rise(0.2)

                        Spacer(minLength: 36)

                        if !todayEntries.isEmpty {
                            timeline(entries: todayEntries, date: context.date)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 44)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func topRow(date: Date) -> some View {
        HStack {
            Text(StudentStorage.shared.studentId ?? "-")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(white: 0.1)))

            Spacer()

            Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .textCase(.uppercase)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.55))
        }
        .padding(.horizontal, 20)
    }

    private func hero(entries: [TimetableEntry], date: Date) -> some View {
        let now = minutes(of: date)
        let current = currentClass(in: entries, at: date)
        let entry = current ?? nextClass(in: entries, at: date)
        let range = entry.flatMap { timeRange(for: $0) }
        let isLive = current != nil

        let progress: CGFloat = range.map {
            CGFloat(min(max((now - $0.start) / ($0.end - $0.start), 0), 1))
        } ?? 0

        return VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 8) {
                if isLive {
                    PulseDot(color: .black, size: 6)
                        .frame(width: 6, height: 6)
                }

                Text(label(isLive: isLive, hasEntry: entry != nil))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color(white: 0.6))

                Spacer()
            }

            if let entry, let range {
                let c = countdown(isLive: isLive, range: range, now: now)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(c.value)
                        .font(.system(size: 96, weight: .ultraLight))
                        .monospacedDigit()
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(c.unit)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color(white: 0.5))
                }
                .padding(.top, 24)

                Text(isLive ? "DO KONCA" : "DO ZAČETKA")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color(white: 0.6))
                    .padding(.top, 2)

                Rectangle()
                    .fill(Color.black.opacity(0.18))
                    .frame(height: 0.5)
                    .padding(.vertical, 22)

                Text(entry.subject)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(entry.time) · \(entry.classroom) · \(entry.type)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(2)
                    .padding(.top, 8)

                if isLive {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.black.opacity(0.12))
                                .frame(height: 1)

                            Rectangle()
                                .fill(Color.black)
                                .frame(width: geo.size.width * progress, height: 1)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(height: 6)
                    .padding(.top, 20)
                    .animation(.easeInOut(duration: 0.8), value: progress)
                }
            } else {
                Text(entries.isEmpty ? "Danes nimaš predavanj." : "Za danes je konec.")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    endRadius: 280
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

    private func label(isLive: Bool, hasEntry: Bool) -> String {
        if isLive { return "TRENUTNO IMAŠ" }
        return hasEntry ? "NASLEDNJI PREDMET" : "DANES"
    }

    private func countdown(
        isLive: Bool,
        range: (start: Double, end: Double),
        now: Double
    ) -> (value: String, unit: String) {
        let target = isLive ? range.end : range.start
        let mins = max(Int(((target - now) * 60).rounded(.up)), 1)

        if mins >= 60 {
            return (String(format: "%d:%02d", mins / 60, mins % 60), "h")
        }
        return ("\(mins)", "min")
    }
    
    private func timeline(entries: [TimetableEntry], date: Date) -> some View {
        let now = minutes(of: date)
        let current = currentClass(in: entries, at: date)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("DANES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color(white: 0.6))

                Spacer()

                Text(String(format: "%02d", entries.count))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(white: 0.6))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
            .rise(0.4)

            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                let range = timeRange(for: entry)
                let isLive = entry.id == current?.id
                let isPast = (range?.end ?? 0) <= now

                NavigationLink {
                    ClassDetailView(entry: entry, allEntries: viewModel.entries)
                } label: {
                    timelineRow(
                        entry,
                        range: range,
                        isFirst: index == 0,
                        isLast: index == entries.count - 1,
                        isLive: isLive,
                        isPast: isPast
                    )
                }
                .buttonStyle(RowPressStyle())
                .rise(0.5 + Double(index) * 0.08)
            }
        }
    }

    private func timelineRow(
        _ entry: TimetableEntry,
        range: (start: Double, end: Double)?,
        isFirst: Bool,
        isLast: Bool,
        isLive: Bool,
        isPast: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {

            VStack(alignment: .leading, spacing: 3) {
                Text(range.map { formatted($0.start) } ?? entry.time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black)

                if let range {
                    Text(formatted(range.end))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color(white: 0.6))
                }
            }
            .frame(width: timeWidth, alignment: .leading)

            Color.clear.frame(width: markWidth, height: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.subject)
                    .font(.system(size: 16, weight: isLive ? .semibold : .medium))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(entry.type) · \(entry.classroom)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(white: 0.6))
                .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .background(alignment: .topLeading) {
            timelineMark(isFirst: isFirst, isLast: isLast, isLive: isLive, isPast: isPast)
        }
        .padding(.horizontal, 20)
        .opacity(isPast ? 0.4 : 1)
        .contentShape(Rectangle())
    }

    private func timelineMark(isFirst: Bool, isLast: Bool, isLive: Bool, isPast: Bool) -> some View {
        let centerX = timeWidth + 14 + markWidth / 2
        let centerY: CGFloat = 16 + dotSize / 2

        return ZStack(alignment: .topLeading) {
            if !(isFirst && isLast) {
                Rectangle()
                    .fill(isPast ? Color.black.opacity(0.7) : Color.black.opacity(0.15))
                    .frame(width: 1, height: isLast ? centerY : nil)
                    .padding(.top, isFirst ? centerY : 0)
                    .padding(.leading, centerX - 0.5)
            }

            dot(isLive: isLive, isPast: isPast)
                .frame(width: dotSize, height: dotSize)
                .padding(.leading, centerX - dotSize / 2)
                .padding(.top, 16)
        }
    }

    @ViewBuilder
    private func dot(isLive: Bool, isPast: Bool) -> some View {
        if isLive {
            PulseDot(color: .black, size: dotSize)
        } else if isPast {
            Circle().fill(Color.black)
        } else {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 1))
        }
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
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.black)

            Text("Napaka")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.black)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.5))
                .multilineTextAlignment(.center)

            Button("Poskusi znova") {
                Task { await viewModel.loadTimetable() }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color(white: 0.1)))
            .padding(.top, 6)
        }
        .padding(24)
    }
}

import SwiftUI

struct TimetableView: View {

    @ObservedObject var viewModel: TimetableViewModel

    private let timeWidth: CGFloat = 46
    private let markWidth: CGFloat = 10
    private let dotSize: CGFloat = 9

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.canvas.ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.entries.isEmpty {
                        ProgressView("Nalaganje urnika...")
                            .tint(Theme.Palette.ink)
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
        .tint(Theme.Palette.ink)
        .preferredColorScheme(.light)
    }

    // MARK: - Content

    private var mainContentView: some View {
        let todayEntries = viewModel.entries
            .filter { $0.dayOfWeek == DayOfWeek.today() }
            .sorted { ($0.hourRange?.start ?? 0) < ($1.hourRange?.start ?? 0) }

        return GeometryReader { proxy in
            ScrollView {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    VStack(alignment: .leading, spacing: 0) {
                        topRow(date: context.date)
                            .rise(0.05)

                        hero(entries: todayEntries, date: context.date)
                            .padding(.top, 22)
                            .rise(0.15)

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
            MetaTag(StudentStorage.shared.studentId ?? "-")

            Spacer()

            MetaText(
                date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased()
            )
        }
        .padding(.horizontal, Theme.Space.page)
    }

    // MARK: - Hero

    private func hero(entries: [TimetableEntry], date: Date) -> some View {
        let now = TimeFormat.hours(of: date)
        let current = currentClass(in: entries, at: date)
        let entry = current ?? nextClass(in: entries, at: date)
        let range = entry?.hourRange
        let isLive = current != nil

        let progress: CGFloat = range.map {
            CGFloat(min(max((now - $0.start) / ($0.end - $0.start), 0), 1))
        } ?? 0

        return VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 8) {
                if isLive {
                    PulseDot()
                }

                Eyebrow(label(isLive: isLive, hasEntry: entry != nil))

                Spacer()
            }

            if let entry, let range {
                let c = countdown(isLive: isLive, range: range, now: now)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(c.value)
                        .themeFont(.numeralXL)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                        .animation(Motion.snap, value: c.value)

                    Text(c.unit)
                        .themeFont(.unit)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                .padding(.top, 20)

                Eyebrow(isLive ? "DO KONCA" : "DO ZAČETKA")
                    .padding(.top, 2)

                Hairline()
                    .padding(.vertical, 22)

                Text(entry.subject)
                    .themeFont(.title)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(entry.time) · \(entry.classroom) · \(entry.type)")
                    .themeFont(.callout)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(2)
                    .padding(.top, 8)

                if isLive {
                    progressLine(progress)
                        .padding(.top, 20)
                }
            } else {
                Text(entries.isEmpty ? "Danes nimaš predavanj." : "Za danes je konec.")
                    .themeFont(.display)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
            }
        }
        .padding(.horizontal, Theme.Space.page)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func progressLine(_ progress: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Palette.hairline)
                    .frame(height: 1)

                Rectangle()
                    .fill(Theme.Palette.brand)
                    .frame(width: geo.size.width * progress, height: 2)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.8), value: progress)
        .accessibilityHidden(true)
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

    // MARK: - Timeline

    private func timeline(entries: [TimetableEntry], date: Date) -> some View {
        let now = TimeFormat.hours(of: date)
        let current = currentClass(in: entries, at: date)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("DANES")

                Spacer()

                Text(String(format: "%02d", entries.count))
                    .themeFont(.mono)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.bottom, 6)
            .rise(0.3)

            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                let range = entry.hourRange
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
                .rise(0.35 + Double(index) * 0.05)
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
                Text(range.map { TimeFormat.clock($0.start) } ?? entry.time)
                    .themeFont(.monoStrong)
                    .foregroundStyle(Theme.Palette.ink)

                if let range {
                    Text(TimeFormat.clock(range.end))
                        .themeFont(.mono)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
            }
            .frame(width: timeWidth, alignment: .leading)

            Color.clear.frame(width: markWidth, height: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.subject)
                    .themeFont(isLive ? .bodyStrong : .body)
                    .fontWeight(isLive ? .semibold : .medium)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(entry.type) · \(entry.classroom)")
                    .themeFont(.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 16)
        .background(alignment: .topLeading) {
            timelineMark(isFirst: isFirst, isLast: isLast, isLive: isLive, isPast: isPast)
        }
        .padding(.horizontal, Theme.Space.page)
        .opacity(isPast ? 0.5 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func timelineMark(isFirst: Bool, isLast: Bool, isLive: Bool, isPast: Bool) -> some View {
        let centerX = timeWidth + 14 + markWidth / 2
        let centerY: CGFloat = 16 + dotSize / 2

        return ZStack(alignment: .topLeading) {
            if !(isFirst && isLast) {
                Rectangle()
                    .fill(isPast ? Theme.Palette.ink.opacity(0.7) : Theme.Palette.hairline)
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
            PulseDot(size: dotSize)
        } else if isPast {
            Circle().fill(Theme.Palette.ink)
        } else {
            Circle()
                .fill(Theme.Palette.canvas)
                .overlay(Circle().stroke(Theme.Palette.ink.opacity(0.4), lineWidth: 1))
        }
    }

    // MARK: - Lookups

    private func currentClass(in entries: [TimetableEntry], at date: Date) -> TimetableEntry? {
        let now = TimeFormat.hours(of: date)
        return entries.first {
            guard let r = $0.hourRange else { return false }
            return now >= r.start && now < r.end
        }
    }

    private func nextClass(in entries: [TimetableEntry], at date: Date) -> TimetableEntry? {
        let now = TimeFormat.hours(of: date)
        return entries.first {
            guard let r = $0.hourRange else { return false }
            return r.start > now
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityHidden(true)

            Text("Napaka")
                .themeFont(.title)
                .foregroundStyle(Theme.Palette.ink)

            Text(message)
                .themeFont(.callout)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Poskusi znova") {
                Task { await viewModel.loadTimetable() }
            }
            .frame(maxWidth: 280)
            .padding(.top, 6)
        }
        .padding(Theme.Space.l)
    }
}

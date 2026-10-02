import SwiftUI

struct TimetableView: View {

    @ObservedObject var viewModel: TimetableViewModel

    @State private var selectedDay: DayOfWeek = DayOfWeek.today()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.entries.isEmpty {
                        ProgressView("Nalaganje urnika...")
                    } else if let errorMessage = viewModel.errorMessage,
                              viewModel.entries.isEmpty {
                        errorView(errorMessage)
                    } else {
                        mainContentView
                    }
                }
            }
            .navigationTitle("URNIK")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadTimetable()
                selectedDay = DayOfWeek.today()
            }
        }
        .preferredColorScheme(.light)
    }

    private var mainContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                studentHeader

                let todayEntries = viewModel.entries.filter {
                    $0.dayOfWeek == DayOfWeek.today()
                }

                if !todayEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Danes")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal)

                        VStack(spacing: 10) {
                            ForEach(todayEntries) { entry in
                                NavigationLink {
                                    ClassDetailView(
                                        entry: entry,
                                        allEntries: viewModel.entries
                                    )
                                } label: {
                                    TimetableCardView(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    emptyTodayView
                }
            }
            .padding(.vertical)
        }
        .scrollIndicators(.hidden)
    }

    private var studentHeader: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ŠTUDENT")
                        .font(
                            .system(
                                size: 10,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.secondary)

                    Text(StudentStorage.shared.studentId ?? "-")
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("FAKULTETA")
                        .font(
                            .system(
                                size: 10,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.secondary)

                    Text("FRI • UL")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.primary)
                }
            }

            currentClassCard
        }
        .padding(.horizontal)
    }

    private var currentClassCard: some View {
        let current = currentClass

        return VStack(alignment: .leading, spacing: 0) {

            HStack {
                Text(
                    current == nil
                    ? "TRENUTNO NIMAŠ POUKA"
                    : "TRENUTNO IMAŠ"
                )
                .font(
                    .system(
                        size: 10,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)

                Spacer()

                Circle()
                    .fill(
                        current == nil
                        ? Color.gray.opacity(0.35)
                        : Color.green
                    )
                    .frame(
                        width: 7,
                        height: 7
                    )
            }

            if let entry = current {
                VStack(alignment: .leading, spacing: 6) {

                    Text(entry.subject)
                        .font(
                            .system(
                                size: 22,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(entry.time)

                        Text("•")

                        Text(entry.classroom)

                        Text("•")

                        Text(entry.type)
                    }
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                    if !entry.lecturer.isEmpty {
                        Text(entry.lecturer)
                            .font(
                                .system(
                                    size: 11,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                Color.secondary.opacity(0.85)
                            )
                            .lineLimit(1)
                    }
                }
                .padding(.top, 12)
            } else if let next = nextClass {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Naslednjič")
                        .font(
                            .system(
                                size: 11,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)

                    Text(next.subject)
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )

                    Text(
                        "\(next.time) • \(next.classroom)"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(Color.black.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.06),
                lineWidth: 0.8
            )
        )
    }

    private var currentClass: TimetableEntry? {
        let entries = viewModel.entries.filter {
            $0.dayOfWeek == DayOfWeek.today()
        }

        let now = Calendar.current.dateComponents(
            [.hour, .minute],
            from: Date()
        )

        guard let hour = now.hour,
              let minute = now.minute else {
            return nil
        }

        let currentTime = Double(hour) + Double(minute) / 60

        return entries.first {
            guard let range = timeRange(for: $0) else {
                return false
            }

            return currentTime >= range.start &&
                   currentTime < range.end
        }
    }

    private var nextClass: TimetableEntry? {
        let entries = viewModel.entries
            .filter {
                $0.dayOfWeek == DayOfWeek.today()
            }
            .compactMap { entry -> (TimetableEntry, Double)? in
                guard let range = timeRange(for: entry) else {
                    return nil
                }

                return (entry, range.start)
            }
            .sorted {
                $0.1 < $1.1
            }

        let now = Calendar.current.dateComponents(
            [.hour, .minute],
            from: Date()
        )

        guard let hour = now.hour,
              let minute = now.minute else {
            return entries.first?.0
        }

        let currentTime =
            Double(hour)
            + Double(minute) / 60

        return entries.first {
            $0.1 > currentTime
        }?.0
    }

    private func timeRange(
        for entry: TimetableEntry
    ) -> (start: Double, end: Double)? {

        let nums = entry.time
            .split(
                whereSeparator: {
                    !$0.isNumber
                }
            )
            .compactMap {
                Double($0)
            }

        var start: Double?
        var end: Double?

        if nums.count >= 4 {
            start = nums[0] + nums[1] / 60
            end = nums[2] + nums[3] / 60
        } else if nums.count == 2 {
            start = nums[0]
            end = nums[1]
        }

        if start == nil,
           let hour = Int(entry.start.prefix(2)) {
            start = Double(hour)
        }

        guard let start else {
            return nil
        }

        let finalEnd =
            end.flatMap {
                $0 > start ? $0 : nil
            } ?? start + 1

        return (start, finalEnd)
    }

    private var emptyTodayView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 30))
                .foregroundStyle(.green)

            Text("Danes nimaš predavanj")
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )

            Text("Uživaj v prostem dnevu.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }

    private var daySelectorHeader: some View {
        HStack(spacing: 10) {
            let dateMap: [DayOfWeek: Int] = [
                .monday: 13,
                .tuesday: 14,
                .wednesday: 15,
                .thursday: 16,
                .friday: 17
            ]

            ForEach(DayOfWeek.allCases) { day in
                let isSelected = day == selectedDay
                let dateNum = dateMap[day] ?? 1

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDay = day
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(day.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                isSelected
                                ? .white.opacity(0.8)
                                : .secondary
                            )

                        Text("\(dateNum)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                isSelected
                                ? .white
                                : .primary
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                        .fill(
                            isSelected
                            ? Color.black
                            : Color.white
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(
                            isSelected ? 0.15 : 0.03
                        ),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                }
            }
        }
    }

    private func errorView(
        _ message: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(.largeTitle)

            Text("Napaka")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Poskusi znova") {
                Task {
                    await viewModel.loadTimetable()
                }
            }
        }
        .padding()
    }
}

struct TimetableCardView: View {

    let entry: TimetableEntry

    var body: some View {
        HStack(spacing: 0) {

            RoundedRectangle(cornerRadius: 3)
                .fill(entry.subjectColor)
                .frame(width: 4)
                .padding(.vertical, 12)
                .padding(.leading, 12)

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                HStack {
                    Text(entry.time)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                }

                Text(entry.subject)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(
                    "\(entry.type) • \(entry.classroom)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(14)
        }
        .background(Color.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16
            )
            .stroke(
                Color.black.opacity(0.05),
                lineWidth: 0.7
            )
        )
        .shadow(
            color: Color.black.opacity(0.035),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

import SwiftUI

struct ClassDetailView: View {
    let entry: TimetableEntry
    let allEntries: [TimetableEntry]

    private var relatedEntries: [TimetableEntry] {
        allEntries.filter { $0.subject == entry.subject }
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if !entry.lecturer.isEmpty {
                        lecturerSection
                            .padding(.top, 36)
                    }

                    Spacer(minLength: 48)

                    scheduleSection
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.black)
        .preferredColorScheme(.light)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let ects = entry.ects {
                Text("\(ects) ECTS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(white: 0.1)))
            }

            Text(entry.subject)
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(.black)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }

    private var lecturerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(entry.lecturer)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            hairline
            ForEach(relatedEntries) { item in
                scheduleRow(item)
                hairline
            }
        }
    }

    private func scheduleRow(_ item: TimetableEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(item.dayOfWeek.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)

                Text(item.type)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.classroom)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.55))
                    .lineLimit(1)

                Text(item.time)
                    .font(.system(size: 22, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Color(white: 0.6))
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.black.opacity(0.18))
            .frame(height: 0.5)
    }
}

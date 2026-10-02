import SwiftUI

struct ClassDetailView: View {
    let entry: TimetableEntry
    let allEntries: [TimetableEntry]
    @State private var selectedTab: DetailTab = .overview
    
    enum DetailTab: String, CaseIterable {
        case overview = "Pregled"
        case grades = "Ocene"
        case lectures = "Predavanja"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.subject)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let ects = entry.ects {
                        Text("\(ects) ECTS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 4) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedTab == tab ? Color(.label) : Color(.systemGray6))
                                )
                                .foregroundStyle(selectedTab == tab ? Color(.systemBackground) : .secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if selectedTab == .overview {
                    if let description = entry.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Opis")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Predavatelj(i)")
                            .font(.headline)
                            .fontWeight(.bold)
                        HStack(spacing: 12) {
                            Text(entry.lecturer.prefix(2).uppercased())
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.lecturer)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let email = entry.lecturerEmail {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Urnik")
                            .font(.headline)
                            .fontWeight(.bold)
                        let relatedEntries = allEntries.filter { $0.subject == entry.subject }
                        VStack(spacing: 8) {
                            ForEach(relatedEntries) { item in
                                HStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(item.subjectColor)
                                        .frame(width: 3)
                                        .padding(.vertical, 8)
                                        .padding(.leading, 10)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(item.dayOfWeek.rawValue) \(item.time)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                        Text("\(item.type) • \(item.classroom)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .padding(12)
                                    Spacer()
                                }
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .center, spacing: 10) {
                        Text("Vsebina za \(selectedTab.rawValue.lowercased()) ni na voljo.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

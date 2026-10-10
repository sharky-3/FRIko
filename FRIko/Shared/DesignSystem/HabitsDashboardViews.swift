import SwiftUI

enum DashStyle {
    static let background = Color(red: 0.86, green: 0.86, blue: 0.87)
    static let card       = Color.white
    static let heroCard   = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let ink        = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let muted      = Color(red: 0.55, green: 0.55, blue: 0.55)
    static let green      = Color(red: 0.82, green: 0.91, blue: 0.74)
    static let blue       = Color(red: 0.76, green: 0.89, blue: 0.93)
    static let accentRed  = Color(red: 0.90, green: 0.35, blue: 0.20)
    static let cardRadius: CGFloat = 28
}

enum ImageSource {
    case asset(String)
    case url(URL)
    case uiImage(UIImage)
    case none
}

struct SourceImage: View {
    let source: ImageSource

    var body: some View {
        switch source {
        case .asset(let name):
            Image(name).resizable().scaledToFill()
        case .url(let url):
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.25)
                }
            }
        case .uiImage(let image):
            Image(uiImage: image).resizable().scaledToFill()
        case .none:
            ZStack {
                Color.gray.opacity(0.25)
                Image(systemName: "person.fill").foregroundStyle(Color.gray)
            }
        }
    }
}

struct AvatarView: View {
    let source: ImageSource
    var size: CGFloat = 36

    var body: some View {
        SourceImage(source: source)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

struct CircleIconButton: View {
    let systemName: String
    var dark: Bool = false
    var size: CGFloat = 44
    var outlined: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(dark ? Color.white : DashStyle.ink)
                .frame(width: size, height: size)
                .background(dark ? DashStyle.ink : Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.black.opacity(outlined ? 0.12 : 0), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PillLabel: View {
    let text: String
    var systemImage: String? = nil
    var imageTint: Color = DashStyle.ink

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(imageTint)
            }
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DashStyle.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(Capsule())
    }
}

struct CommunityCard: View {
    var source: String = "SourceName"
    var category: String = "Community"
    var title: String = "Productive routine."
    var readNowTitle: String = "Read now"
    var websiteText: String = "example.com"
    var views: String = "1.4k"
    var coverImage: ImageSource = .none
    var likedBy: [ImageSource] = []
    var onView: () -> Void = {}
    var onOpen: () -> Void = {}
    var onReadNow: () -> Void = {}
    var onAddLike: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 15))
                    (Text("by ").foregroundStyle(DashStyle.muted)
                     + Text(source).fontWeight(.semibold))
                        .font(.system(size: 15))
                }
                Spacer()
                CircleIconButton(systemName: "eye", outlined: true, action: onView)
                CircleIconButton(systemName: "arrow.up.right", dark: true, action: onOpen)
            }

            Text(category)
                .font(.system(size: 15, weight: .medium))
                .padding(.top, 6)

            Text(title)
                .font(.system(size: 26, weight: .semibold))
                .padding(.top, 2)

            Button(action: onReadNow) {
                HStack(spacing: 6) {
                    Text(readNowTitle)
                        .underline()
                        .foregroundStyle(DashStyle.muted)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .font(.system(size: 15))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            ZStack {
                SourceImage(source: coverImage)
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .clipped()

                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Text(websiteText)
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "link")
                                .font(.system(size: 10))
                                .foregroundStyle(DashStyle.accentRed)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                        Spacer()
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(spacing: 2) {
                            Image(systemName: "eye").font(.system(size: 13))
                            Text(views).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial.opacity(0.9))
                        .background(Color.black.opacity(0.25))
                        .clipShape(Circle())

                        Spacer()

                        HStack(spacing: 8) {
                            Text("Liked\nby")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.trailing)
                            HStack(spacing: -8) {
                                Button(action: onAddLike) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(DashStyle.ink)
                                        .frame(width: 30, height: 30)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                ForEach(Array(likedBy.prefix(3).enumerated()), id: \.offset) { _, src in
                                    AvatarView(source: src, size: 30)
                                        .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                                }
                            }
                            .padding(5)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.top, 14)
        }
        .padding(16)
        .background(DashStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: DashStyle.cardRadius, style: .continuous))
    }
}

struct StatisticsHeroCard: View {
    var label: String = "Statistics"
    var userName: String = "Daniel"
    var avatar: ImageSource = .none
    var emoji: String = "👋"
    var line2Prefix: String = "your overall"
    var line3Prefix: String = "score is "
    var highlight: String = "above average"
    var onShare: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DashStyle.ink)
                Spacer()
                CircleIconButton(systemName: "square.and.arrow.up", size: 44, action: onShare)
            }
            Spacer(minLength: 100)
            Text(label)
                .font(.system(size: 15, weight: .medium))
            VStack(alignment: .leading, spacing: 0) {
                Text("Hello \(emoji) \(userName)")
                HStack(spacing: 8) {
                    AvatarView(source: avatar, size: 36)
                    Text(line2Prefix)
                }
                (Text(line3Prefix) + Text(highlight).fontWeight(.bold))
            }
            .font(.system(size: 44, weight: .regular))
            .minimumScaleFactor(0.6)
            .lineLimit(4)
            .foregroundStyle(DashStyle.ink)
        }
        .padding(18)
        .padding(.top, 25)
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        .background(DashStyle.heroCard)
        .clipShape(RoundedRectangle(cornerRadius: DashStyle.cardRadius, style: .continuous))
    }
}

struct WebinarRow: View {
    var day: String = "11"
    var weekday: String = "Fri"
    var title: String = "Webinar"
    var subtitle: String = "Short description."
    var onMore: () -> Void = {}
    var onLink: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(day).font(.system(size: 20, weight: .semibold))
                Text(weekday).font(.system(size: 12))
            }
            .foregroundStyle(.white)
            .frame(width: 58, height: 66)
            .background(DashStyle.ink)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.system(size: 16, weight: .semibold))
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.2, green: 0.8, blue: 0.75))
                }
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(DashStyle.muted)
                    .lineLimit(1)
            }
            Spacer()
            CircleIconButton(systemName: "ellipsis", size: 44, outlined: true, action: onMore)
            CircleIconButton(systemName: "link", dark: true, size: 44, action: onLink)
        }
        .padding(10)
        .background(DashStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

struct SharedStatsPill: View {
    var text: String = "Statistics shared to "
    var count: Int = 1
    var noun: String = "friend"
    var friendAvatar: ImageSource = .none
    var onSwap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            (Text(text) + Text("\(count) ") + Text(noun).foregroundStyle(DashStyle.muted))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DashStyle.ink)
            Spacer()
            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DashStyle.ink)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(DashStyle.muted.opacity(0.6),
                                             style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            }
            .buttonStyle(.plain)
            AvatarView(source: friendAvatar, size: 46)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DashStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

struct BestResultChip: View {
    var done: Int = 5
    var total: Int = 6
    var label: String = "Tasks"

    var body: some View {
        HStack(spacing: 6) {
            Text("🏆").font(.system(size: 12))
            (Text("Best Result: \(done)/") + Text("\(total)").foregroundStyle(DashStyle.muted) + Text(" \(label)"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DashStyle.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(Capsule())
    }
}

struct GrowthChip: View {
    var text: String = "Growth: +15%"
    var body: some View {
        PillLabel(text: text, systemImage: "chart.line.uptrend.xyaxis", imageTint: DashStyle.accentRed)
    }
}

struct ArrowCircleButton: View {
    var action: () -> Void = {}
    var body: some View {
        CircleIconButton(systemName: "arrow.up.right", size: 44, action: action)
    }
}

struct TasksCard: View {
    var dateText: String = "10 Thu"
    var label: String = "Current tasks"
    var count: Int = 3
    var priority: String = "High"
    var tags: [String] = ["#shopping", "#renovation", "#planning"]
    var onShare: () -> Void = {}
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(dateText)
                }
                .font(.system(size: 15))
                .foregroundStyle(DashStyle.muted)
                Spacer()
                CircleIconButton(systemName: "square.and.arrow.up", size: 44, action: onShare)
                    .opacity(0.85)
                CircleIconButton(systemName: "plus", dark: true, size: 44, action: onAdd)
            }

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .padding(.top, 14)

            VStack(alignment: .leading, spacing: 2) {
                Text("You have \(count)")
                HStack(spacing: 8) {
                    Text("tasks")
                    HStack(spacing: 4) {
                        Text(priority)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DashStyle.accentRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .clipShape(Capsule())
                    Text("for today")
                }
            }
            .font(.system(size: 30, weight: .regular))
            .foregroundStyle(DashStyle.ink)
            .padding(.top, 2)

            Divider().padding(.vertical, 14)

            HStack(spacing: 22) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 14))
                        .foregroundStyle(DashStyle.muted)
                }
            }
        }
        .padding(16)
        .background(DashStyle.green)
        .clipShape(RoundedRectangle(cornerRadius: DashStyle.cardRadius, style: .continuous))
    }
}

enum ProgressPeriod: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct ProgressCard: View {
    var label: String = "Your progress"
    var message: String = "You are doing well ☺️"
    var percent: Int = 78
    @Binding var period: ProgressPeriod

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .clipShape(Circle())
                Spacer()
                HStack(spacing: 0) {
                    ForEach(ProgressPeriod.allCases, id: \.self) { p in
                        Button { period = p } label: {
                            Text(p.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(period == p ? DashStyle.ink : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(period == p ? DashStyle.blue : DashStyle.ink)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(DashStyle.ink)
                .clipShape(Capsule())
            }
            Spacer(minLength: 16)
            Text(label)
                .font(.system(size: 14, weight: .medium))
            HStack(alignment: .bottom) {
                Text(message)
                    .font(.system(size: 26, weight: .regular))
                    .lineLimit(2)
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 60, weight: .light))
            }
            .foregroundStyle(DashStyle.ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(DashStyle.blue)
        .clipShape(RoundedRectangle(cornerRadius: DashStyle.cardRadius, style: .continuous))
    }
}

enum DashTab: CaseIterable {
    case layout, home, settings, profile

    var systemName: String {
        switch self {
        case .layout:   return "square.on.square"
        case .home:     return "square.grid.2x2.fill"
        case .settings: return "gearshape.fill"
        case .profile:  return "person.fill"
        }
    }
}

struct DashTabBar: View {
    @Binding var selected: DashTab

    var body: some View {
        HStack {
            ForEach(DashTab.allCases, id: \.self) { tab in
                Button { selected = tab } label: {
                    Image(systemName: tab.systemName)
                        .font(.system(size: 18))
                        .foregroundStyle(selected == tab ? DashStyle.ink : Color.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selected == tab ? Color.white : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1.2))
    }
}

struct DashboardDemoScreen: View {
    @State private var period: ProgressPeriod = .weekly
    @State private var tab: DashTab = .home

    var body: some View {
        ZStack {
            DashStyle.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    StatisticsHeroCard(
                        userName: "Daniel",
                        avatar: .none
                    )

                    CommunityCard(
                        title: "Productive routine.",
                        coverImage: .none,
                        likedBy: [.none, .none, .none]
                    )

                    WebinarRow(day: "11", weekday: "Fri",
                               title: "Webinar",
                               subtitle: "Short description.")

                    TasksCard(count: 3, priority: "High",
                              tags: ["#shopping", "#renovation", "#planning"])

                    ProgressCard(percent: 78, period: $period)

                    SharedStatsPill(count: 1, noun: "friend", friendAvatar: .none)

                    HStack(spacing: 10) {
                        BestResultChip(done: 5, total: 6)
                        GrowthChip(text: "Growth: +15%")
                        ArrowCircleButton()
                        Spacer()
                    }

                    DashTabBar(selected: $tab)
                        .padding(.top, 8)
                }
                .padding(16)
            }
        }
    }
}

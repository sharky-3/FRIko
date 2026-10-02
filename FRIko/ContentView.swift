import SwiftUI

private let pagerSpace = "pager"

struct ContentView: View {
    @State private var selectedTab: Int? = 0

    private let gradients: [[Color]] = [
        [.blue, .indigo],
        [.green, .teal],
        [.orange, .pink],
        [.purple, .black]
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(gradients.indices, id: \.self) { index in
                        PageContainer(colors: gradients[index]) {
                            pageContent(index)
                        }
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(1 - abs(phase.value) * 0.18)
                                .opacity(1 - abs(phase.value) * 0.6)
                                .blur(radius: abs(phase.value) * 6)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .coordinateSpace(name: pagerSpace)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedTab)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()

            PageIndicator(count: gradients.count, selection: $selectedTab)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selectedTab)
    }

    @ViewBuilder
    private func pageContent(_ index: Int) -> some View {
        switch index {
        case 0: WelcomeView()
        case 1: FeaturesView()
        case 2: StatsView()
        default: GetStartedView()
        }
    }
}

private struct PageContainer<Content: View>: View {
    let colors: [Color]
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .named(pagerSpace)).minX
            let progress = min(abs(minX) / max(proxy.size.width, 1), 1)

            ZStack {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .offset(x: -minX * 0.3)

                content()
                    .environment(\.pageMinX, minX)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: progress * 44, style: .continuous))
        }
    }
}

private struct PageMinXKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    fileprivate var pageMinX: CGFloat {
        get { self[PageMinXKey.self] }
        set { self[PageMinXKey.self] = newValue }
    }
}

private struct Parallax: ViewModifier {
    @Environment(\.pageMinX) private var minX
    let factor: CGFloat

    func body(content: Content) -> some View {
        content.offset(x: minX * factor)
    }
}

extension View {
    fileprivate func parallax(_ factor: CGFloat) -> some View {
        modifier(Parallax(factor: factor))
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 90, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                .parallax(0.4)

            Text("Welcome")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .parallax(0.2)

            Text("Swipe to explore")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .parallax(0.1)
        }
        .foregroundStyle(.white)
    }
}

struct FeaturesView: View {
    private let rows: [(symbol: String, title: String, factor: CGFloat)] = [
        ("bolt.fill", "Fast and fluid", 0.15),
        ("lock.shield.fill", "Private by design", 0.30),
        ("icloud.fill", "Synced everywhere", 0.45)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Features")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .padding(.bottom, 8)
                .parallax(0.1)

            ForEach(rows, id: \.title) { row in
                HStack(spacing: 14) {
                    Image(systemName: row.symbol)
                        .font(.title2)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text(row.title)
                        .font(.title3.weight(.semibold))

                    Spacer()
                }
                .parallax(row.factor)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
    }
}

struct StatsView: View {
    private let stats: [(value: String, label: String, factor: CGFloat)] = [
        ("12k", "Users", 0.15),
        ("4.9", "Rating", 0.30),
        ("98%", "Uptime", 0.30),
        ("24/7", "Support", 0.45)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("By the numbers")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .parallax(0.1)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(stats, id: \.label) { stat in
                    VStack(spacing: 4) {
                        Text(stat.value)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text(stat.label)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .parallax(stat.factor)
                }
            }
            .padding(.horizontal, 28)
        }
        .foregroundStyle(.white)
    }
}

struct GetStartedView: View {
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "rocket.fill")
                .font(.system(size: 80, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                .parallax(0.4)

            Text("Ready?")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .parallax(0.2)

            Button {
                // 
            } label: {
                Text("Get started")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 36)
                    .frame(height: 52)
                    .background(.white, in: Capsule())
            }
            .parallax(0.1)
        }
        .foregroundStyle(.white)
    }
}

private struct PageIndicator: View {
    let count: Int
    @Binding var selection: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                let isActive = (selection ?? 0) == index
                Capsule()
                    .fill(.white.opacity(isActive ? 1 : 0.4))
                    .frame(width: isActive ? 26 : 8, height: 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) { selection = index }
                    }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 24)
        .animation(.snappy, value: selection)
    }
}

#Preview {
    ContentView()
}

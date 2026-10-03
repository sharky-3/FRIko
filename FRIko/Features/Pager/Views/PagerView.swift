import SwiftUI

private let pagerSpace = "pager"

struct PagerView: View {
    @StateObject private var timetableVM = TimetableViewModel()
    @State private var selectedTab: Int? = 0
    private let pageCount = 3

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        PageContainer {
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
            .onAppear {
                selectedTab = 1
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea()

            PageIndicator(
                titles: ["NASTAVITVE", "DANES", "TEDEN"],
                selection: $selectedTab
            )
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selectedTab)
    }

    @ViewBuilder
    private func pageContent(_ index: Int) -> some View {
        switch index {
        case 0: SettingsView(viewModel: timetableVM)
        case 1: TimetableView(viewModel: timetableVM)
        case 2: WeeklyTimetableView(viewModel: timetableVM)
        default: EmptyView()
        }
    }
}

private struct PageContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .named(pagerSpace)).minX
            let progress = min(abs(minX) / max(proxy.size.width, 1), 1)

            ZStack {
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

private struct PageIndicator: View {
    let titles: [String]
    @Binding var selection: Int?

    private let topGap: CGFloat = 28
    private let trailingGap: CGFloat = 16

    private var current: Int { selection ?? 0 }

    var body: some View {
        HStack(spacing: 8) {
            Text(titles.indices.contains(current) ? titles[current] : "")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.4)
                .id(current)
                .transition(.opacity.combined(with: .offset(x: 6)))

            HStack(spacing: 4) {
                ForEach(titles.indices, id: \.self) { index in
                    Capsule()
                        .frame(width: index == current ? 18 : 5, height: 3)
                        .opacity(index == current ? 1 : 0.35)
                        .contentShape(Rectangle().inset(by: -10))
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.35)) {
                                selection = index
                            }
                        }
                }
            }
        }
        .foregroundStyle(.white)
        .compositingGroup()
        .blendMode(.difference)
        .padding(.top, topGap)
        .padding(.trailing, trailingGap)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .allowsHitTesting(true)
        .animation(.snappy(duration: 0.35), value: current)
    }
}

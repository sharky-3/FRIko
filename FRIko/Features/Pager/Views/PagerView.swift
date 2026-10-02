import SwiftUI

private let pagerSpace = "pager"

struct PagerView: View {
    @StateObject private var timetableVM = TimetableViewModel()
    @State private var selectedTab: Int? = 0
    private let pageCount = 2

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .scrollIndicators(.hidden)
            .ignoresSafeArea()

            PageIndicator(count: pageCount, selection: $selectedTab)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selectedTab)
    }

    @ViewBuilder
    private func pageContent(_ index: Int) -> some View {
        switch index {
        case 0: TimetableView(viewModel: timetableVM)
        case 1: WeeklyTimetableView(viewModel: timetableVM)
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

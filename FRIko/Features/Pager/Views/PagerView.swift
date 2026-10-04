import SwiftUI
import Observation

private let pagerSpace = "pager"

@Observable
fileprivate final class PagerProgress {
    var position: CGFloat = 1
}

struct PagerView: View {
    @StateObject private var timetableVM = TimetableViewModel()
    @State private var selectedTab: Int? = 0
    @State private var progress = PagerProgress()
    @State private var ready = false

    private let pageCount = 3

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        PageContainer(index: index, progress: progress) {
                            pageContent(index)
                        }
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(1 - abs(phase.value) * 0.16)
                                .opacity(1 - abs(phase.value) * 0.6)
                                .blur(radius: abs(phase.value) * 6)
                                .rotation3DEffect(
                                    .degrees(phase.value * -8),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.7
                                )
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
            .opacity(ready ? 1 : 0)

            PageIndicator(
                count: pageCount,
                progress: progress,
                selection: $selectedTab
            )
            .opacity(ready ? 1 : 0)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .onAppear {
            selectedTab = 1
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    ready = true
                }
            }
        }
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
    let index: Int
    let progress: PagerProgress
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .named(pagerSpace)).minX
            let width = max(proxy.size.width, 1)
            let amount = min(abs(minX) / width, 1)

            content()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(RoundedRectangle(cornerRadius: amount * 44, style: .continuous))
                .onChange(of: minX, initial: true) { _, newValue in
                    if index == 0 {
                        progress.position = -newValue / width
                    }
                }
        }
    }
}

private struct PageIndicator: View {
    let count: Int
    let progress: PagerProgress
    @Binding var selection: Int?

    private let bottomGap: CGFloat = 22

    var body: some View {
        let position = progress.position

        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                let activity = max(0, 1 - abs(position - CGFloat(index)))

                Capsule()
                    .frame(width: 5 + 17 * activity, height: 3)
                    .opacity(0.3 + 0.7 * activity)
                    .contentShape(Rectangle().inset(by: -12))
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.35)) {
                            selection = index
                        }
                    }
            }
        }
        .foregroundStyle(.white)
        .compositingGroup()
        .blendMode(.difference)
        .padding(.bottom, bottomGap)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
}

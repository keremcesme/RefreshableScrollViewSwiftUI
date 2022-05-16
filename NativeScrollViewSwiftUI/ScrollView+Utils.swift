//
//  ScrollView+Utils.swift
//  NativeScrollViewSwiftUI
//
//  Created by Kerem Cesme on 16.05.2022.
//

import SwiftUI

// - MARK: ScrollView with Offset Tracker -
struct ScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let offsetChanged: (CGPoint) -> Void
    let content: Content
    
    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        offsetChanged: @escaping (CGPoint) -> Void = { _ in },
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.offsetChanged = offsetChanged
        self.content = content()
    }
    
    var body: some View {
        SwiftUI.ScrollView(axes, showsIndicators: showsIndicators) {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scrollView")).origin
                )
            }.frame(width: 0, height: 0)
            content
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: offsetChanged)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

// - MARK: Refresh Space -
///  Adds a space following isRefreshing and scrollOffset on top of the `VStack`.
///  METHOD: .addRefreshIndicatorSpacing(Bool, CGFloat)
struct PullToRefreshModifier: ViewModifier {
    
    var isRefreshing: Bool
    var scrollOffset: CGFloat
    
    init(isRefreshing: Bool,
         scrollOffset: CGFloat){
        self.isRefreshing = isRefreshing
        self.scrollOffset = scrollOffset
    }
    
    func body(content: Content) -> some View {
        VStack(spacing:0) {
            IndicatorSpacing
            content
        }
    }
    
    @ViewBuilder
    var IndicatorSpacing: some View {
        if scrollOffset >= 0 || isRefreshing {
            Color.clear
                .frame(height: isRefreshing ? 100 : scrollOffset <= 0 ? 0 : scrollOffset)
        }
    }
}
extension View {
    func addRefreshIndicatorSpacing(isRefreshing: Bool, scrollOffset: CGFloat) -> some View {
        modifier(PullToRefreshModifier(isRefreshing: isRefreshing, scrollOffset: scrollOffset))
    }
}

// - MARK: Refresh Indicator -
///  Adds an `ProgressView` as an overlay on the `ScrollView`.
///  METHOD: .pullToRefresh(Binding<Bool>, Binding<CGFloat>, action: @escaping () async -> Void)
struct ScrollViewRefreshable<Content: View>: View {
    
    let content: Content
    let action: () async -> Void
    
    @Binding var isRefreshing: Bool
    @Binding var scrollOffset: CGFloat
    
    init(isRefreshing: Binding<Bool>,
         scrollOffset: Binding<CGFloat>,
         action: @escaping () async -> Void,
         content: Content){
        self._isRefreshing = isRefreshing
        self._scrollOffset = scrollOffset
        self.action = action
        self.content = content
    }
    
    var body: some View {
        content
            .overlay(alignment: .top, content: { RefreshIndicator })
            .onChange(of: scrollOffset) { value in
                if value > 100 && !isRefreshing {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isRefreshing = true
                }
            }
            .onChange(of: isRefreshing) { value in
                if value {
                    Task {
                        await self.action()
                        try? await Task.sleep(seconds: 0.5)
                        withAnimation(.spring()) {
                            scrollOffset = 0
                            isRefreshing = false
                        }
                        try? await Task.sleep(seconds: 0.5)
                    }
                }
            }
    }
    
    @ViewBuilder
    var RefreshIndicator: some View {
        if scrollOffset > 0 || isRefreshing {
            ProgressView()
                .padding(5)
                .background(.regularMaterial, in: Circle())
                .opacity(isRefreshing ? 1 : (scrollOffset / 100.0))
                .scaleEffect(isRefreshing ? 1.5 : (scrollOffset / 100.0))
                .padding(.top, 20)
        }
    }
}
extension ScrollView {
    public func pullToRefresh(isRefreshing: Binding<Bool>,
                              scrollOffset: Binding<CGFloat>,
                              action: @escaping () async -> Void) -> some View {
        return ScrollViewRefreshable(isRefreshing: isRefreshing,
                                      scrollOffset: scrollOffset,
                                      action: action,
                                      content: self)
    }
}

// - MARK: Example Usage -

///  struct ContentView: View {
///      @State var isRefreshing = false
///      @State var scrollOffset: CGFloat = 0
///      var body: some View {
///          ScrollView(offsetChanged: { scrollOffset = $0.height } ) {
///              content
///                  .addRefreshIndicatorSpacing(isRefreshing: isRefreshing, scrollOffset: scrollOffset)
///          }
///          .pullToRefresh(isRefreshing: $isRefreshing, scrollOffset: $scrollOffset) {
///               -> `Async` function is called here.
///          }
///      }
///  }


extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

extension CGPoint {
    var height: CGFloat {
        y
    }
}

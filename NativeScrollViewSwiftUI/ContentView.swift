//
//  ContentView.swift
//  NativeScrollViewSwiftUI
//
//  Created by Kerem Cesme on 16.05.2022.
//

import SwiftUI

struct ContentView: View {
    @State var isRefreshing = false
    @State var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ScrollView(offsetChanged: { scrollOffset = $0.height } ) {
                content
                    .addRefreshIndicatorSpacing(isRefreshing: isRefreshing,
                                                scrollOffset: scrollOffset)
            }
            .pullToRefresh(isRefreshing: $isRefreshing,
                           scrollOffset: $scrollOffset) {
                print("Refreshing...")
                try? await Task.sleep(seconds: 2)
            }
            .navigationBarTitle("Refreshable Scroll View")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    var content: some View {
        LazyVStack {
            ForEach(1...100, id: \.self){ inx in
                Rectangle()
                    .frame(maxWidth: UIScreen.main.bounds.width)
                    .frame(height: 150)
                    .padding(.horizontal)
                    .overlay {
                        Text("\(inx)").colorInvert()
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

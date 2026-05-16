//
//  ActionBannerView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/05/16.
//

import SwiftUI

struct ActionBannerView: View {
    let imageName: String

    @State private var opacity: Double = 0

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(height: 100)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.15)) { opacity = 1 }
                withAnimation(.easeIn(duration: 0.4).delay(0.8)) { opacity = 0 }
            }
    }
}

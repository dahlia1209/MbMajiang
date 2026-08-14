//
//  LizhiCutInView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/05/16.
//

import SwiftUI

struct LizhiCutInView: View {
    let onFinished: () -> Void

    @State private var offsetX: CGFloat = 600
    @State private var opacity: Double = 1.0

    var body: some View {
        OshidashiText(text: "リーチ", size: 90)
            .offset(x: offsetX)
            .opacity(opacity)
            .onAppear {
                // スライドイン
                withAnimation(.easeOut(duration: 0.35)) {
                    offsetX = 0
                }
                // 表示後にフェードアウトして完了通知
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    onFinished()
                }
            }
    }
}

//
//  OshidashiText.swift
//  MbMajiang
//
//  局表示・カットインで使う押し出し文字（黄色地・緑の影で立体感を出す）。
//  旧デザインのバナー画像（RoundLabels・CutIns）と同じ配色を、フォント描画に置き換えたもの。
//  TitleView.swiftの「レッツ麻雀」と同じ、二重シャドウで奥行きを出す手法を踏襲している。
//  Oshidashi-M-Gothicは「一」「二」等の横画が細く縞状に割れて見えたため、
//  太さが均一なShinRetroMaruGothic-Boldに変更している。
//

import SwiftUI

struct OshidashiText: View {
    let text: String
    var size: CGFloat

    private let fill = Color(red: 0.96, green: 0.93, blue: 0.2)
    private let shadowColor = Color(red: 0.04, green: 0.53, blue: 0.21)

    var body: some View {
        Text(text)
            .font(.custom("ShinRetroMaruGothic-Bold", size: size))
            .foregroundStyle(fill)
            .shadow(color: shadowColor, radius: size * 0.02, x: size * 0.035, y: size * 0.045)
            .shadow(color: shadowColor.opacity(0.9), radius: size * 0.07)
    }
}

#Preview(traits: .landscapeLeft) {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 24) {
            OshidashiText(text: "東一局", size: 64)
            OshidashiText(text: "1本場", size: 44)
            OshidashiText(text: "リーチ", size: 90)
            OshidashiText(text: "流局", size: 90)
            OshidashiText(text: "テンパイ", size: 80)
        }
    }
}

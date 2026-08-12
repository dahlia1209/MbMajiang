//
//  BackgroundLayer.swift
//  MbMajiang
//

import SwiftUI
import UIKit

struct BackgroundLayer: View {
    var imageName: String? = nil
    /// キャンバステーマの手書き画像。指定時は`color`の上に重ねて描画する
    var overlayImage: UIImage? = nil
    var color: Color? = nil

    var body: some View {
        ZStack {
            if let name = imageName {
                GeometryReader { geo in
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                LinearGradient(
                    colors: [
                        Color(red: 55/255, green: 125/255, blue: 45/255),
                        Color(red: 30/255, green: 85/255, blue: 25/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.15)
            } else if let color {
                color
                if let overlayImage {
                    GeometryReader { geo in
                        Image(uiImage: overlayImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 55/255, green: 125/255, blue: 45/255),
                        Color(red: 30/255, green: 85/255, blue: 25/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview (traits: .landscapeLeft){
    BackgroundLayer()
}

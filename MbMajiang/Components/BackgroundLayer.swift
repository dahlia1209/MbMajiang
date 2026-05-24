//
//  BackgroundLayer.swift
//  MbMajiang
//

import SwiftUI

struct BackgroundLayer: View {
    var imageName: String? = nil

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
            }
            LinearGradient(
                colors: [
                    Color(red: 55/255, green: 125/255, blue: 45/255),
                    Color(red: 30/255, green: 85/255, blue: 25/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(imageName != nil ? 0.5 : 1.0)
        }
        .ignoresSafeArea()
    }
}

#Preview (traits: .landscapeLeft){
    BackgroundLayer()
}

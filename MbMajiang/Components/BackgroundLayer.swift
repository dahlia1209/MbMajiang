//
//  BackgroundLayer.swift
//  MbMajiang
//

import SwiftUI

struct BackgroundLayer: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                        Color(red: 18/255, green: 85/255, blue: 68/255),   // ベースカラー
                        Color(red: 12/255, green: 60/255, blue: 48/255)    // 少し暗めで奥行きを出す
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
            )
            
        }
        .ignoresSafeArea()  
    }
}

#Preview (traits: .landscapeLeft){
    BackgroundLayer()
}

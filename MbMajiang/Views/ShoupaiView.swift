//
//  ShoupaiView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/01.
//

import SwiftUI

struct ShoupaiView: View {
    var shoupai:Shoupai
    var isTajia:Bool=false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(shoupai.bingpai, id: \.self) { pai in
                PaiView(isTajia ? "_" : pai.label)
            }
            
            Spacer().frame(width: 10)

            if let zimo = shoupai.zimo {
                PaiView(isTajia ? "_" : zimo.label)
            } else {
                Color.clear
                    .frame(width: 22 + 8)
            }
        }
    }
}

extension ShoupaiView {
    init(_ bingpai: [String] = [], _ zimo: String? = nil,_ isCPU:Bool=false) {
        self.shoupai = Shoupai(bingpai,zimo)
        self.isTajia=isCPU
    }
}

#Preview (traits: .landscapeLeft){
    ShoupaiView( ["s1","s1","s1","s2","s3","s4","s5","s6","s7","s8","s9","s9","s9"],"z1")
}

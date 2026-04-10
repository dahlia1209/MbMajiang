//
//  ShoupaiView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/01.
//

import SwiftUI

struct ShoupaiView: View {
    var shoupai: Shoupai
    var isTajia: Bool = false
    var onTapPai: ((Int) -> Void)? = nil  // 追加

    private func tajia(_ pai: Pai) -> Pai {
        var p = pai
        p.revealed = false
        return p
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(shoupai.bingpai.indices, id: \.self) { index in
                let pai = shoupai.bingpai[index]
                PaiView(pai: isTajia ? tajia(pai) : pai)
                    .onTapGesture {
                        onTapPai?(index)
                    }
            }

            Spacer().frame(width: 10)

            if let zimo = shoupai.zimo {
                PaiView(pai: isTajia ? tajia(zimo) : zimo)
                    .onTapGesture {
                        onTapPai?(shoupai.bingpai.count)  // zimoは末尾のインデックス
                    }
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

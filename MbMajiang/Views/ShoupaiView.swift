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
    var onTapPai: ((Int) -> Void)? = nil
    /// nil = 制限なし。非 nil の場合、含まれないインデックスはグレーアウトしてタップ不可
    var highlightedIndices: Set<Int>? = nil

    private func tajia(_ pai: Pai) -> Pai {
        var p = pai
        p.revealed = false
        return p
    }

    private func isEnabled(_ index: Int) -> Bool {
        highlightedIndices.map { $0.contains(index) } ?? true
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(shoupai.bingpai.indices, id: \.self) { index in
                let pai = shoupai.bingpai[index]
                paiCell(pai: isTajia ? tajia(pai) : pai, index: index)
            }
            // 13枚分の残りスペースを確保（枚数変動で全体が動かないよう固定）
            let remaining = 13 - shoupai.bingpai.count
            Color.clear.frame(width: CGFloat(remaining) * 22)

            Spacer().frame(width: 10)

            if let zimo = shoupai.zimo {
                paiCell(pai: isTajia ? tajia(zimo) : zimo, index: shoupai.bingpai.count)
            } else {
                Color.clear.frame(width: 22)
            }
        }
    }

    @ViewBuilder
    private func paiCell(pai: Pai, index: Int) -> some View {
        let enabled = isEnabled(index)
        let highlighted = highlightedIndices != nil && enabled
        PaiView(pai: pai)
            .offset(y: highlighted ? -6 : 0)
            .opacity(enabled ? 1.0 : 0.35)
            .onTapGesture {
                guard enabled else { return }
                onTapPai?(index)
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

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
    /// 選択済みインデックス（チー選択中の1枚目など）
    var selectedIndices: Set<Int> = []

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

            // 13枚分の残りスペース（副露グループ分を差し引いて間隔を詰める）
            let fulouTotalWidth = shoupai.fulou.reduce(0) { $0 + FulouGroupView.width(of: $1) }
            let remainingWidth = max(0, CGFloat(13 - shoupai.bingpai.count) * 22 - fulouTotalWidth)
            Color.clear.frame(width: remainingWidth)

            Spacer().frame(width: 10)

            if let zimo = shoupai.zimo {
                paiCell(pai: isTajia ? tajia(zimo) : zimo, index: shoupai.bingpai.count)
            } else {
                Color.clear.frame(width: 22)
            }

            // 副露グループ（ツモの右側）
            if !shoupai.fulou.isEmpty {
                Spacer().frame(width: 25)
                ForEach(shoupai.fulou.indices, id: \.self) { i in
                    FulouGroupView(group: shoupai.fulou[i])
                }
            }
        }
    }

    @ViewBuilder
    private func paiCell(pai: Pai, index: Int) -> some View {
        let enabled = isEnabled(index)
        let highlighted = highlightedIndices != nil && enabled
        let selected = selectedIndices.contains(index)
        PaiView(pai: pai)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.orange, lineWidth: 2)
                }
            }
            .offset(y: selected ? -10 : highlighted ? -6 : 0)
            .opacity(enabled || selected ? 1.0 : 0.35)
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

#Preview("通常", traits: .landscapeLeft) {
    ShoupaiView(["s1","s1","s1","s2","s3","s4","s5","s6","s7","s8","s9","s9","s9"], "z1")
}

#Preview("ポン（上家）", traits: .landscapeLeft) {
    // 上家からポン: [rotated打牌, 手牌, 手牌]
    var dapai = Pai("z7"); dapai.rotated = true
    let ponGroup: [Pai] = [dapai, Pai("z7"), Pai("z7")]
    let shoupai = Shoupai(["m2","m3","m4","p5","p6","p7","s1","s2","s3","s8","s9"], "s7")
    shoupai.fulou = [ponGroup]
    return ShoupaiView(shoupai: shoupai)
}

#Preview("ポン（対面）", traits: .landscapeLeft) {
    // 対面からポン: [手牌, rotated打牌, 手牌]
    var dapai = Pai("m1"); dapai.rotated = true
    let ponGroup: [Pai] = [Pai("m1"), dapai, Pai("m1")]
    let shoupai = Shoupai(["p2","p3","p4","p5","p6","p7","s1","s2","s3","s8","s9"], "s7")
    shoupai.fulou = [ponGroup]
    return ShoupaiView(shoupai: shoupai)
}

#Preview("ポン（下家）", traits: .landscapeLeft) {
    // 下家からポン: [手牌, 手牌, rotated打牌]
    var dapai = Pai("p9"); dapai.rotated = true
    let ponGroup: [Pai] = [Pai("p9"), Pai("p9"), dapai]
    let shoupai = Shoupai(["m1","m2","m3","m7","m8","m9","s4","s5","s6","s8","s9"], "s7")
    shoupai.fulou = [ponGroup]
    return ShoupaiView(shoupai: shoupai)
}

#Preview("ポン×2", traits: .landscapeLeft) {
    var d1 = Pai("z1"); d1.rotated = true
    let pon1: [Pai] = [d1, Pai("z1"), Pai("z1")]
    var d2 = Pai("z5"); d2.rotated = true
    let pon2: [Pai] = [Pai("z5"), d2, Pai("z5")]
    let shoupai = Shoupai(["m1","m2","m3","p4","p5","p6","s7"], "s8")
    shoupai.fulou = [pon1, pon2]
    return ShoupaiView(shoupai: shoupai)
}

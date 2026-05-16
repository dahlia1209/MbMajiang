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
    /// ドラ表示牌ラベルの配列（"m1" 等）。空の場合はドラ強調なし
    var baopai: [String] = []
    /// 手牌全体の表示倍率（1.0 = 標準）
    var scale: CGFloat = 1.0
    /// シャンテン数を下げる有効捨て牌のインデックス（青丸を表示）
    var effectiveDiscardIndices: Set<Int> = []

    private var doraLabels: Set<String> {
        Set(baopai.flatMap { baopaiTable[$0] ?? [] })
    }

    private func tajia(_ pai: Pai) -> Pai {
        var p = pai
        p.revealed = false
        return p
    }

    @State private var lastDragIndex: Int? = nil

    private func isEnabled(_ index: Int) -> Bool {
        highlightedIndices.map { $0.contains(index) } ?? true
    }

    private var fulouTotalWidth: CGFloat {
        shoupai.fulou.reduce(0) { $0 + FulouGroupView.width(of: $1) * scale }
    }

    private var zimoStartX: CGFloat {
        let bingpaiWidth = CGFloat(shoupai.bingpai.count) * 22 * scale
        let remainingWidth = max(0, CGFloat(13 - shoupai.bingpai.count) * 22 * scale - fulouTotalWidth)
        return bingpaiWidth + remainingWidth + 10
    }

    private func tileIndex(at x: CGFloat) -> Int? {
        let tileW = 22 * scale
        if x >= 0, x < CGFloat(shoupai.bingpai.count) * tileW {
            return Int(x / tileW)
        }
        if shoupai.zimo != nil, x >= zimoStartX, x < zimoStartX + tileW {
            return shoupai.bingpai.count
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(shoupai.bingpai.indices, id: \.self) { index in
                let pai = shoupai.bingpai[index]
                paiCell(pai: isTajia ? tajia(pai) : pai, index: index)
            }

            // 13枚分の残りスペース（副露グループ分を差し引いて間隔を詰める）
            let remainingWidth = max(0, CGFloat(13 - shoupai.bingpai.count) * 22 * scale - fulouTotalWidth)
            Color.clear.frame(width: remainingWidth)

            Spacer().frame(width: 10)

            if let zimo = shoupai.zimo {
                paiCell(pai: isTajia ? tajia(zimo) : zimo, index: shoupai.bingpai.count)
            } else {
                Color.clear.frame(width: 22 * scale)
            }

            // 副露グループ（ツモの右側）
            if !shoupai.fulou.isEmpty {
                Spacer().frame(width: 25)
                ForEach(shoupai.fulou.indices, id: \.self) { i in
                    FulouGroupView(group: shoupai.fulou[i], baopai: baopai)
                        .scaleEffect(scale)
                        .frame(width: FulouGroupView.width(of: shoupai.fulou[i]) * scale,
                               height: 30 * scale)
                }
            }
        }
//        .padding(.top,0)
//        .coordinateSpace(name: "shoupai")
//        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("shoupai"))
                .onChanged { value in
                    let x = value.location.x
                    guard let index = tileIndex(at: x),
                          index != lastDragIndex,
                          isEnabled(index),
                          onTapPai != nil else { return }
                    lastDragIndex = index
                    SoundManager.shared.play("tile_select")
                    onTapPai?(index)
                }
                .onEnded { _ in lastDragIndex = nil },
            including: onTapPai != nil ? .all : .none
        )
    }

    private func isDora(_ pai: Pai) -> Bool {
        guard pai.revealed else { return false }
        if ["m0","p0","s0"].contains(pai.label) { return true }
        return doraLabels.contains(Pai.normalize(pai.label))
    }

    @ViewBuilder
    private func paiCell(pai: Pai, index: Int) -> some View {
        let enabled = isEnabled(index)
        let selected = selectedIndices.contains(index)
        let isEffective = effectiveDiscardIndices.contains(index)
        PaiView(pai: pai)
            .scaleEffect(scale)
            .frame(width: 22 * scale, height: 30 * scale)
            .overlay(alignment: .top) { Color.black.opacity(0.01).offset(y: -30 * scale) }
            .overlay {
                if isDora(pai) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.yellow.opacity(0.25))
                }
            }
            .overlay(alignment: .top) {
                if isEffective {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(y: -8)
                }
            }
            .offset(y: selected ? -10 : 0)
            .opacity(enabled || selected ? 1.0 : 0.35)
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

#Preview("ドラあり", traits: .landscapeLeft) {
    // baopai "m4" → ドラは m5 と m0（赤ドラ）
    ShoupaiView(
        shoupai: Shoupai(["m5","m5","m5","p1","p2","p3","s7","s8","s9","z1","z1","z1"], "m0"),
        baopai: ["m4"]
    )
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

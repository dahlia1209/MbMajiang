//
//  HuleDialogView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/12.
//

import SwiftUI

struct HuleDialogView: View {
    let result: HuleResult
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // 半透明オーバーレイ
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 10) {

                    // ドラ表示
                    doraRow

                    Divider().background(Color.white.opacity(0.2))

                    // 手牌（流局時は非表示）
                    if result.kind != .pingju {
                        handRow
                        Divider().background(Color.white.opacity(0.2))
                    }

                    // 役表 or 流局テキスト
                    if result.kind == .pingju {
                        pingjuSection
                    } else {
                        hupaiSection
                    }

                    Divider().background(Color.white.opacity(0.2))

                    // 場況（本場・供託）
                    jicunRow

                    Divider().background(Color.white.opacity(0.2))

                    // 得点変動
                    fenpeiSection
                }
                .fixedSize()
                .padding(16)
                .background(.black)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
        }
        .onTapGesture { onDismiss() }  // どこをタップしても閉じる
    }

    // MARK: - ドラ表示
    private var doraRow: some View {
        HStack(spacing: 16) {
            doraLine(label: "ドラ",   pais: result.baopai)
            doraLine(label: "裏ドラ", pais: result.libaopai)
        }
    }

    private func doraLine(label: String, pais: [Pai]) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            HStack(spacing: 0) {
                ForEach(pais.indices, id: \.self) { i in
                    PaiView(pais[i].label)
                }
                ForEach(pais.count..<5, id: \.self) { _ in
                    PaiView("_", false)
                }
            }
        }
    }

    // MARK: - 手牌
    private var handRow: some View {
        HStack(spacing: 0) {
            // bingpai
            ForEach(result.bingpai.indices, id: \.self) { i in
                PaiView(result.bingpai[i].label)
            }
            // 和了牌（ツモ or ロン牌）
            if let win = result.winTile {
                Spacer().frame(width: 8)
                PaiView(win.label)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.yellow, lineWidth: 1.5)
                    )
            }
            // 副露グループ
            ForEach(result.fulou.indices, id: \.self) { gi in
                Spacer().frame(width: 8)
                HStack(spacing: 0) {
                    ForEach(result.fulou[gi].indices, id: \.self) { pi in
                        PaiView(pai: result.fulou[gi][pi])
                    }
                }
            }
        }
    }

    // MARK: - 役表
    private var hupaiSection: some View {
        VStack(alignment: .center, spacing: 4) {
            if result.hupai.isEmpty {
                Text("（役計算未実装）")
                    .font(.system(size: 13))
                    .foregroundColor(.gray.opacity(0.6))
            } else {
                Grid(horizontalSpacing: 16, verticalSpacing: 4) {
                    ForEach(result.hupai.indices, id: \.self) { i in
                        GridRow {
                            Text(result.hupai[i].name)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .gridColumnAlignment(.leading)
                            Text("\(result.hupai[i].fan)翻")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                                .gridColumnAlignment(.trailing)
                        }
                    }
                }
            }

            // 得点行
            Text(scoreLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var scoreLabel: String {
        var parts: [String] = []
        if result.fu > 0       { parts.append("\(result.fu)符") }
        if result.totalFan > 0 { parts.append("\(result.totalFan)翻") }
        if result.points > 0   { parts.append("\(result.points)点") }
        return parts.isEmpty ? "" : parts.joined(separator: " ")
    }

    // MARK: - 流局
    private var pingjuSection: some View {
        Text("流　局")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 6)
    }

    // MARK: - 場況（本場・供託）
    private var jicunRow: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image("100")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 6)
                Text("× \(result.honba)")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            HStack(spacing: 6) {
                Image("1000")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 6)
                Text("× \(result.lizhibang)")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - 得点変動（麻雀卓配置: 私=下・下家=右・対面=上・上家=左）
    private var fenpeiSection: some View {
        ZStack {
            playerBlock(0).offset(y: 20)
            playerBlock(1).offset(x: 100)
            playerBlock(2).offset(y: -20)
            playerBlock(3).offset(x: -100)
        }
        .frame(width: 240, height: 70)
    }

    private func playerBlock(_ i: Int) -> some View {
        let feng = result.afterScores[i].feng
        let pts  = result.afterScores[i].points
        let diff = result.scoreChanges.indices.contains(i) ? result.scoreChanges[i] : 0
        return VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 0) {
                Text(feng.label + "：")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
                Text(formatScore(pts))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .trailing)
            }
            Text(formatDiff(diff))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(diffColor(diff))
                .frame(width: 60, alignment: .trailing)
        }
    }

    // MARK: - Helpers
    private func formatScore(_ pts: Int) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        return n.string(from: NSNumber(value: pts)) ?? "\(pts)"
    }

    private func formatDiff(_ diff: Int) -> String {
        guard diff != 0 else { return "" }
        let sign = diff > 0 ? "+" : ""
        let n = NumberFormatter()
        n.numberStyle = .decimal
        let s = n.string(from: NSNumber(value: diff)) ?? "\(diff)"
        return "\(sign)\(s)"
    }

    private func diffColor(_ diff: Int) -> Color {
        if diff > 0 { return .green }
        if diff < 0 { return .red }
        return .clear
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    let bingpai: [Pai] = ["m5","m6","m7","p5","p6","p7","s2","s2","s4","s4","s4","s6","s7"].map { Pai($0) }
    let hupai: [(name: String, fan: Int)] = [("断幺九", 1), ("三色同順", 2)]
    let afterScores: [(feng: Feng, points: Int)] = [(.西, 25000), (.北, 25000), (.東, 25000), (.南, 25000)]
    let result = HuleResult(
        kind: .zimo, hulePlayer: 0,
        bingpai: bingpai, fulou: [[Pai]](), winTile: Pai("s5"),
        baopai: [Pai("z7")], hupai: hupai,
        fu: 30, totalFan: 3, points: 5200,
        scoreChanges: [-5200, 0, 5200, 0], afterScores: afterScores,
        honba: 1, lizhibang: 0)
    HuleDialogView(result: result) {}
}

#Preview("副露あり", traits: .landscapeLeft) {
    var nakiPai = Pai("z5"); nakiPai.rotated = true
    let bingpai: [Pai] = ["m2","m3","m4","p5","p6","p7","s3","s4","s5","s7"].map { Pai($0) }
    let fulou: [[Pai]] = [[nakiPai, Pai("z5"), Pai("z5")]]
    let hupai: [(name: String, fan: Int)] = [("白", 1), ("断么九", 1)]
    let afterScores: [(feng: Feng, points: Int)] = [(.東, 28900), (.南, 25000), (.西, 21100), (.北, 25000)]
    let result = HuleResult(
        kind: .rong, hulePlayer: 0,
        bingpai: bingpai, fulou: fulou, winTile: Pai("s7"),
        baopai: [Pai("m3")], hupai: hupai,
        fu: 30, totalFan: 2, points: 3900,
        scoreChanges: [3900, 0, -3900, 0], afterScores: afterScores,
        honba: 0, lizhibang: 0)
    return HuleDialogView(result: result) {}
}

#Preview("流局", traits: .landscapeLeft) {
    let afterScores: [(feng: Feng, points: Int)] = [(.東, 25000), (.南, 25000), (.西, 25000), (.北, 25000)]
    let result = HuleResult(
        kind: .pingju, hulePlayer: nil,
        bingpai: [], fulou: [[Pai]](), winTile: nil,
        baopai: [Pai("z7")],
        scoreChanges: [0, 0, 0, 0], afterScores: afterScores,
        honba: 0, lizhibang: 0)
    HuleDialogView(result: result) {}
}

//
//  RoundResultView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/12.
//

import SwiftUI

struct RoundResultView: View {
    let result: HuleResult
    let onDismiss: () -> Void


    var body: some View {
        ZStack {
            // 半透明オーバーレイ
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            // ダイアログ（中央）
            VStack(spacing: 10) {
                doraRow

                Divider().background(Color.white.opacity(0.2))

                if !result.kind.isPingju {
                    handRow
                    Divider().background(Color.white.opacity(0.2))
                }

                if result.kind.isPingju {
                    pingjuSection(subtitle: result.kind.pingjuSubtitle)
                } else {
                    hupaiSection
                }

                Divider().background(Color.white.opacity(0.2))

                jicunRow

                Divider().background(Color.white.opacity(0.2))

                fenpeiSection
            }
            .fixedSize()
            .padding(16)
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )

            // 次局へボタン（右下）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Text("次局へ")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.yellow)
                            .frame(width: 160, height: 52)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow.opacity(0.7), lineWidth: 1.5)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
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
                    PaiView("_", reveal: false)
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
            } else if result.hupai.count >= 5 {
                // 5役以上: 1列4つで2列に分割
                HStack(alignment: .top, spacing: 24) {
                    hupaiGrid(Array(result.hupai.prefix(4)))
                    hupaiGrid(Array(result.hupai.dropFirst(4).prefix(4)))
                }
            } else {
                hupaiGrid(result.hupai)
            }

            // 得点行
            Text(scoreLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func hupaiGrid(_ hupai: [(name: String, fan: Int)]) -> some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 4) {
            ForEach(hupai.indices, id: \.self) { i in
                GridRow {
                    if hupai[i].fan >= 100 {
                        Text(hupai[i].name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: .orange.opacity(0.7), radius: 4)
                            .gridColumnAlignment(.leading)
                    } else {
                        Text(hupai[i].name)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .gridColumnAlignment(.leading)
                    }
                    if hupai[i].fan > 0 && hupai[i].fan < 100 {
                        Text("\(hupai[i].fan)翻")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                            .gridColumnAlignment(.trailing)
                    }
                }
            }
        }
    }

    private var scoreLabel: String {
        var parts: [String] = []
        if result.fu > 0 &&  result.totalFan <= 4     { parts.append("\(result.fu)符") }
        if result.totalFan > 0 && result.totalFan <= 4 { parts.append("\(result.totalFan)翻") }
        else if result.totalFan == 5 { parts.append("満貫") }
        else if result.totalFan >= 6 && result.totalFan <= 7 { parts.append("跳満") }
        else if result.totalFan >= 8 && result.totalFan <= 10 { parts.append("倍満") }
        else if result.totalFan >= 11 && result.totalFan <= 12 { parts.append("三倍満") }
        else if result.totalFan >= 13 && result.totalFan <= 99 { parts.append("数え役満") }
        else if result.totalFan >= 100 {
            let weight = result.totalFan / 100
            let label:String
            switch weight{
            case 1 : label = "役満"
            case 2 : label = "ダブル役満"
            case 3 : label = "三倍役満"
            case 4 : label = "四倍役満"
            default: label = "役満"
            }
            parts.append(label) }
        
        if result.points > 0   { parts.append("\(result.points)点") }
        return parts.isEmpty ? "" : parts.joined(separator: " ")
    }

    // MARK: - 流局
    private func pingjuSection(subtitle: String?) -> some View {
        VStack(spacing: 4) {
            Text("流　局")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
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
    RoundResultView(result: result) {}
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
    return RoundResultView(result: result) {}
}

#Preview("流局", traits: .landscapeLeft) {
    let afterScores: [(feng: Feng, points: Int)] = [(.東, 25000), (.南, 25000), (.西, 25000), (.北, 25000)]
    let result = HuleResult(
        kind: .pingju, hulePlayer: nil,
        bingpai: [], fulou: [[Pai]](), winTile: nil,
        baopai: [Pai("z7")],
        scoreChanges: [0, 0, 0, 0], afterScores: afterScores,
        honba: 0, lizhibang: 0)
    RoundResultView(result: result) {}
}

#Preview("四風連打", traits: .landscapeLeft) {
    let afterScores: [(feng: Feng, points: Int)] = [(.東, 25000), (.南, 25000), (.西, 25000), (.北, 25000)]
    let result = HuleResult(
        kind: .suufon, hulePlayer: nil,
        bingpai: [], fulou: [[Pai]](), winTile: nil,
        baopai: [Pai("z7")],
        scoreChanges: [0, 0, 0, 0], afterScores: afterScores,
        honba: 0, lizhibang: 0)
    RoundResultView(result: result) {}
}

#Preview("九種九牌", traits: .landscapeLeft) {
    let afterScores: [(feng: Feng, points: Int)] = [(.東, 25000), (.南, 25000), (.西, 25000), (.北, 25000)]
    let result = HuleResult(
        kind: .kyuushu, hulePlayer: nil,
        bingpai: [], fulou: [[Pai]](), winTile: nil,
        baopai: [Pai("z7")],
        scoreChanges: [0, 0, 0, 0], afterScores: afterScores,
        honba: 0, lizhibang: 0)
    RoundResultView(result: result) {}
}

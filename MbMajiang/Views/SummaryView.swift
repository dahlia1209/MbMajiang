//
//  SummaryView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/12.
//

import SwiftUI

struct SummaryView: View {
    let result: SummaryResult
    let onDismiss: () -> Void

    private let playerNames = ["私", "下家", "対面", "上家"]

    // カラム幅
    private let colJushu:  CGFloat = 60
    private let colHonba:  CGFloat = 50
    private let colKind:   CGFloat = 44
    private let colPlayer: CGFloat = 78

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerRow
                        Divider().background(Color.white.opacity(0.25))

                        ForEach(result.roundHistory.indices, id: \.self) { i in
                            roundRow(result.roundHistory[i])
                                .background(i % 2 == 0
                                    ? Color.clear
                                    : Color.white.opacity(0.03))
                        }

                        Divider().background(Color.white.opacity(0.25))
                        defenRow
                        Divider().background(Color.white.opacity(0.1))
                        pointRow
                    }
                }
            }
            .padding(16)
            .background(Color(red: 0.10, green: 0.10, blue: 0.16))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
        .onTapGesture { onDismiss() }
    }

    // MARK: - ヘッダー行（プレイヤー名）
    private var headerRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: colJushu + colHonba + colKind)
            ForEach(0..<4, id: \.self) { i in
                Text(playerNames[i])
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: colPlayer)
            }
        }
        .padding(.vertical, 7)
    }

    // MARK: - 各局の行
    private func roundRow(_ record: RoundRecord) -> some View {
        HStack(spacing: 0) {
            Text(record.jushu.rawValue)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(width: colJushu, alignment: .leading)

            Text("\(record.honba)本場")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(width: colHonba, alignment: .leading)

            Text(kindLabel(record.kind))
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(width: colKind, alignment: .leading)

            ForEach(0..<4, id: \.self) { i in
                playerCell(record: record, playerIdx: i)
            }
        }
        .padding(.vertical, 5)
    }

    private func playerCell(record: RoundRecord, playerIdx: Int) -> some View {
        let diff    = record.scoreChanges.indices.contains(playerIdx) ? record.scoreChanges[playerIdx] : 0
        let isDealer = playerIdx == record.dealerPlayer
        let hasLizhi = record.lizhiPlayers.contains(playerIdx)

        return ZStack {
            if isDealer {
                Color.white.opacity(0.06).cornerRadius(2)
            }
            HStack(spacing: 1) {
                Text(diffText(diff))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(diffColor(diff))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(hasLizhi ? "＊" : " ")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .frame(width: 12)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: colPlayer)
    }

    // MARK: - フッター: 最終得点
    private var defenRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: colJushu + colHonba + colKind)
            ForEach(0..<4, id: \.self) { i in
                let pts = result.finalScores.indices.contains(i) ? result.finalScores[i].points : 0
                Text(formatScore(pts))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(scoreColor(pts))
                    .frame(width: colPlayer, alignment: .trailing)
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - フッター: 最終ポイント
    private var pointRow: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: colJushu + colHonba + colKind)
            ForEach(0..<4, id: \.self) { i in
                let pt = result.finalPoints.indices.contains(i) ? result.finalPoints[i] : 0.0
                Text(formatPoint(pt))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(pt >= 0 ? .green : .red)
                    .frame(width: colPlayer, alignment: .trailing)
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers
    private func kindLabel(_ kind: HuleResult.Kind) -> String {
        switch kind {
        case .zimo:   return "ツモ"
        case .rong:   return "ロン"
        case .pingju: return "流局"
        }
    }

    private func diffText(_ diff: Int) -> String {
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

    private func scoreColor(_ pts: Int) -> Color {
        if pts > 30000 { return .green }
        if pts < 0     { return .red }
        return .white
    }

    private func formatScore(_ pts: Int) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        return n.string(from: NSNumber(value: pts)) ?? "\(pts)"
    }

    private func formatPoint(_ pt: Double) -> String {
        let sign = pt >= 0 ? "+" : ""
        return String(format: "\(sign)%.1f", pt)
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    let history: [RoundRecord] = [
        RoundRecord(jushu: .東一局, honba: 0, kind: .rong,  hulePlayer: 2, dealerPlayer: 0, scoreChanges: [0,     0, +2000,  -2000], lizhiPlayers: []),
        RoundRecord(jushu: .東一局, honba: 1, kind: .rong,  hulePlayer: 2, dealerPlayer: 0, scoreChanges: [-3200, 0, +3200,  0    ], lizhiPlayers: []),
        RoundRecord(jushu: .東一局, honba: 2, kind: .rong,  hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8300, 0, 0,     +10300], lizhiPlayers: [0, 3]),
        RoundRecord(jushu: .東二局, honba: 0, kind: .rong,  hulePlayer: 1, dealerPlayer: 1, scoreChanges: [0,  +2300, -1300, 0    ], lizhiPlayers: [0]),
        RoundRecord(jushu: .東三局, honba: 0, kind: .rong,  hulePlayer: 3, dealerPlayer: 2, scoreChanges: [-7700, 0, 0,    +8700 ], lizhiPlayers: [2]),
        RoundRecord(jushu: .東四局, honba: 0, kind: .rong,  hulePlayer: 2, dealerPlayer: 3, scoreChanges: [-2600, 0, +3600, 0    ], lizhiPlayers: [2]),
        RoundRecord(jushu: .南一局, honba: 0, kind: .rong,  hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8000, 0, 0,    +8000 ], lizhiPlayers: []),
    ]
    let finalScores: [(feng: Feng, points: Int)] = [
        (feng: .西, points: -6800),
        (feng: .北, points: 27300),
        (feng: .東, points: 30500),
        (feng: .南, points: 49000),
    ]
    let finalPoints: [Double] = [-56.8, -12.7, 10.5, 59.0]
    let result = SummaryResult(roundHistory: history, finalScores: finalScores, finalPoints: finalPoints)
    SummaryView(result: result) {}
}

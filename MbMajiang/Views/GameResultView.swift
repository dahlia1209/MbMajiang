//
//  GameResultView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/12.
//

import SwiftUI

struct GameResultView: View {
    let result: SummaryResult
    let onDismiss: () -> Void

    private let playerNames = ["私", "下家", "対面", "上家"]

    private let goldColor      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLightColor = Color(red: 0.97, green: 0.93, blue: 0.83)

    // カラム幅
    private let colPlayer: CGFloat = 90
    private let colRank:   CGFloat = 56
    private let colScore:  CGFloat = 100
    private let colStat:   CGFloat = 76

    // 順位順（1位が先頭）に並べたプレイヤー index
    private var rankedIndices: [Int] {
        (0..<4).sorted { result.finalScores[$0].points > result.finalScores[$1].points }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 16) {
                // ダイアログ
                VStack(spacing: 8) {
                    Text("対局結果")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(goldColor)
                        .tracking(4)
                        .shadow(color: .black.opacity(0.9), radius: 2)

                    VStack(spacing: 0) {
                        headerRow
                        Divider().background(goldColor.opacity(0.25))

                        VStack(spacing: 0) {
                            ForEach(Array(rankedIndices.enumerated()), id: \.offset) { offset, playerIdx in
                                summaryRow(rank: offset + 1, playerIdx: playerIdx)
                                    .background(offset % 2 == 0
                                        ? Color.clear
                                        : goldColor.opacity(0.06))
                            }
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(goldColor.opacity(0.5), lineWidth: 1)
                        )
                )
                .frame(maxWidth: 460)

                // 対局終了ボタン
                Button {
                    onDismiss()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(goldColor.opacity(0.25))
                            .blur(radius: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                LinearGradient(colors: [goldLightColor, goldColor],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.4)))
                        Text("対局終了")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(colors: [goldLightColor, goldColor],
                                               startPoint: .leading, endPoint: .trailing))
                            .tracking(4)
                    }
                    .frame(width: 200, height: 46)
                    .contentShape(Rectangle())
                }
            }
            .offset(y: 15)
        }
    }

    // MARK: - ヘッダー行
    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell("プレイヤー名", width: colPlayer, alignment: .leading)
            headerCell("順位",       width: colRank)
            headerCell("最終持ち点", width: colScore)
            headerCell("リーチ回数", width: colStat)
            headerCell("和了回数",   width: colStat)
            headerCell("放銃回数",   width: colStat)
        }
        .padding(.vertical, 5)
    }

    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment = .center) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(goldLightColor.opacity(0.85))
            .frame(width: width, alignment: alignment)
    }

    // MARK: - 各プレイヤーの行
    private func summaryRow(rank: Int, playerIdx: Int) -> some View {
        let pts = result.finalScores[playerIdx].points
        let pt  = result.finalPoints[playerIdx]

        return HStack(spacing: 0) {
            Text(playerNames[playerIdx])
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(goldLightColor)
                .frame(width: colPlayer, alignment: .leading)

            Text("\(rank)位")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(rank == 1 ? goldColor : goldLightColor)
                .frame(width: colRank)

            VStack(spacing: 1) {
                Text(formatScore(pts))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(goldLightColor)
                Text("(\(formatPoint(pt)))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(pt >= 0 ? .green : .red)
            }
            .frame(width: colScore)

            Text("\(lizhiCount(playerIdx))")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(goldLightColor.opacity(0.85))
                .frame(width: colStat)

            Text("\(agariCount(playerIdx))")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(goldLightColor.opacity(0.85))
                .frame(width: colStat)

            Text("\(houjuuCount(playerIdx))")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(goldLightColor.opacity(0.85))
                .frame(width: colStat)
        }
        .padding(.vertical, 6)
    }

    // MARK: - 集計ヘルパー
    private func lizhiCount(_ playerIdx: Int) -> Int {
        result.roundHistory.filter { $0.lizhiPlayers.contains(playerIdx) }.count
    }

    private func agariCount(_ playerIdx: Int) -> Int {
        result.roundHistory.filter { $0.hulePlayer == playerIdx }.count
    }

    private func houjuuCount(_ playerIdx: Int) -> Int {
        result.roundHistory.filter {
            $0.kind == .rong
                && $0.scoreChanges.indices.contains(playerIdx)
                && $0.scoreChanges[playerIdx] < 0
        }.count
    }

    // MARK: - Format
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
    GameResultView(result: result) {}
}

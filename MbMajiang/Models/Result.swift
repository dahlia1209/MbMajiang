//
//  Result.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation

// MARK: - Result
@Observable
class Result {


    var huleResult: HuleResult? = nil
    var summaryResult: SummaryResult? = nil
    var roundHistory: [RoundRecord] = []

}


// MARK: - SummaryResult
struct SummaryResult {
    var roundHistory: [RoundRecord]
    var finalScores: [(feng: Feng, points: Int)]  // プレイヤー index 順
    var finalPoints: [Double]                            // ウマ・オカ込み最終ポイント
}

// MARK: - HuleResult
struct HuleResult {
    enum Kind { case zimo, rong, pingju }

    var kind: Kind
    var hulePlayer: Int?       // 和了プレイヤー index（流局時は nil）
    var bingpai: [Pai]         // 手牌（表示用・hidden除去済み）
    var fulou: [[Pai]] = []    // 副露グループ（表示順）
    var winTile: Pai?          // 和了牌（ツモ牌 or ロン牌）
    var baopai: [Pai]          // ドラ表示牌
    var libaopai: [Pai] = []   // 裏ドラ表示牌（リーチ和了時のみ）
    var hupai: [(name: String, fan: Int)] = []  // 役一覧（未実装時は空）
    var fu: Int = 0
    var totalFan: Int = 0
    var points: Int = 0
    var scoreChanges: [Int]    // 各プレイヤーの得点変動 [0...3]（未実装時は 0）
    var afterScores: [(feng: Feng, points: Int)]  // 変動後の得点
    var honba: Int
    var lizhibang: Int
}

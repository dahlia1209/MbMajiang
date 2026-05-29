//
//  RenzhuTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

// MARK: - テスト用 HuleResult ファクトリ

private func makeResult(
    kind: HuleResult.Kind,
    winner: Int? = nil,
    tenpai: [Int] = [],
    nagashi: [Int] = []
) -> HuleResult {
    HuleResult(
        kind: kind,
        hulePlayer: winner,
        bingpai: [],
        baopai: [],
        tenpaiPlayers: tenpai,
        nagashiManganPlayers: nagashi,
        scoreChanges: [0, 0, 0, 0],
        afterScores: [(Feng.東, 25000), (Feng.南, 25000), (Feng.西, 25000), (Feng.北, 25000)],
        honba: 0,
        lizhibang: 0
    )
}

// MARK: - テンパイ連荘設定

@Suite("shouldRenzhu: テンパイ連荘")
struct RenzhuTenpaiTests {

    let dealer = 0

    // ── 和了 ──

    @Test("親ツモ和了 → 連荘（バグ修正確認）")
    func dealerZimoIsRenchan() {
        let result = makeResult(kind: .zimo, winner: dealer)
        #expect(Game.renzhuDecision(result: result, primaryWinner: dealer, dealerIdx: dealer, renzhuFang: .tenpai) == true)
    }

    @Test("親ロン和了 → 連荘")
    func dealerRonIsRenchan() {
        let result = makeResult(kind: .rong, winner: dealer)
        #expect(Game.renzhuDecision(result: result, primaryWinner: dealer, dealerIdx: dealer, renzhuFang: .tenpai) == true)
    }

    @Test("子ツモ和了 → 親流れ")
    func nonDealerZimoIsNotRenchan() {
        let result = makeResult(kind: .zimo, winner: 1)
        #expect(Game.renzhuDecision(result: result, primaryWinner: 1, dealerIdx: dealer, renzhuFang: .tenpai) == false)
    }

    @Test("子ロン和了 → 親流れ")
    func nonDealerRonIsNotRenchan() {
        let result = makeResult(kind: .rong, winner: 2)
        #expect(Game.renzhuDecision(result: result, primaryWinner: 2, dealerIdx: dealer, renzhuFang: .tenpai) == false)
    }

    // ── 荒牌流局 ──

    @Test("荒牌流局: 親テンパイ → 連荘")
    func pingjuDealerTenpaiIsRenchan() {
        let result = makeResult(kind: .pingju, tenpai: [dealer, 2])
        #expect(Game.renzhuDecision(result: result, primaryWinner: nil, dealerIdx: dealer, renzhuFang: .tenpai) == true)
    }

    @Test("荒牌流局: 親ノーテン → 親流れ")
    func pingjuDealerNotenIsNotRenchan() {
        let result = makeResult(kind: .pingju, tenpai: [1, 2])
        #expect(Game.renzhuDecision(result: result, primaryWinner: nil, dealerIdx: dealer, renzhuFang: .tenpai) == false)
    }

    @Test("荒牌流局: 全員ノーテン → 親流れ")
    func pingjuAllNotenIsNotRenchan() {
        let result = makeResult(kind: .pingju, tenpai: [])
        #expect(Game.renzhuDecision(result: result, primaryWinner: nil, dealerIdx: dealer, renzhuFang: .tenpai) == false)
    }

    // ── 流し満貫 ──

    @Test("流し満貫: 親が成立 → 連荘")
    func nagashiDealerIsRenchan() {
        let result = makeResult(kind: .nagashiMangan, nagashi: [dealer])
        #expect(Game.renzhuDecision(result: result, primaryWinner: nil, dealerIdx: dealer, renzhuFang: .tenpai) == true)
    }

    @Test("流し満貫: 子が成立 → 親流れ")
    func nagashiNonDealerIsNotRenchan() {
        let result = makeResult(kind: .nagashiMangan, nagashi: [1])
        #expect(Game.renzhuDecision(result: result, primaryWinner: nil, dealerIdx: dealer, renzhuFang: .tenpai) == false)
    }
}

// MARK: - 和了連荘設定

@Suite("shouldRenzhu: 和了連荘")
struct RenzhuHuleTests {

    let dealer = 0

    @Test("親ツモ和了 → 連荘")
    func dealerZimoIsRenchan() {
        let result = makeResult(kind: .zimo, winner: dealer)
        #expect(Game.renzhuDecision(result: result, primaryWinner: dealer, dealerIdx: dealer, renzhuFang: .hule) == true)
    }

    @Test("子ツモ和了 → 親流れ")
    func nonDealerZimoIsNotRenchan() {
        let result = makeResult(kind: .zimo, winner: 1)
        #expect(Game.renzhuDecision(result: result, primaryWinner: 1, dealerIdx: dealer, renzhuFang: .hule) == false)
    }

    @Test("荒牌流局: 親テンパイでも親流れ（和了連荘は流局連荘なし）")
    func pingjuDealerTenpaiIsNotRenchan() {
        let result = makeResult(kind: .pingju, tenpai: [dealer])
        #expect(Game.renzhuDecision(result: result, primaryWinner: nil, dealerIdx: dealer, renzhuFang: .hule) == false)
    }
}

// MARK: - 連荘なし / ノーテン連荘

@Suite("shouldRenzhu: 連荘なし・ノーテン連荘")
struct RenzhuEdgeCaseTests {

    let dealer = 0

    @Test("連荘なし: 親ツモでも親流れ")
    func noneAlwaysFalse() {
        let result = makeResult(kind: .zimo, winner: dealer)
        #expect(Game.renzhuDecision(result: result, primaryWinner: dealer, dealerIdx: dealer, renzhuFang: .none) == false)
    }

    @Test("ノーテン連荘: 子ロンでも連荘")
    func notenAlwaysTrue() {
        let result = makeResult(kind: .rong, winner: 3)
        #expect(Game.renzhuDecision(result: result, primaryWinner: 3, dealerIdx: dealer, renzhuFang: .noten) == true)
    }
}

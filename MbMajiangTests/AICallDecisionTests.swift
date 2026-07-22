//
//  AICallDecisionTests.swift
//  MbMajiangTests
//
//  AIPlayer.evaluateFulouCall（チー・ポン判断）のテスト。

import Testing
@testable import MbMajiang

@Suite("AIPlayer.evaluateFulouCall: 副露判断")
struct AICallDecisionTests {

    private func makeAI(_ labels: [String], kuitanAri: Bool = true) -> AIPlayer {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(labels))
        ai.kuitanAri = kuitanAri
        return ai
    }

    // 3面子(m123,p456,s789) + 塔子2(s12,s45) + 雀頭なし → 1シャンテン（HuleXiantingTestsで検証済みの形）
    private let baseHand = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","s1","s2","s4","s5"]

    @Test("シャンテンが縮むチーは実行される")
    func chiImprovesShantenIsCalled() {
        let ai = makeAI(baseHand)
        let result = ai.evaluateFulouCall(dapai: "s3", isNextPlayer: true, status: GameStatus())
        guard case .chi = result else {
            Issue.record("チーが選択されるべき: \(String(describing: result))")
            return
        }
    }

    @Test("クイタンなし設定で役牌もタンヤオ材料も無いチーは行わない")
    func chiBlockedByYakuSafetyGuard() {
        let ai = makeAI(baseHand, kuitanAri: false)
        let result = ai.evaluateFulouCall(dapai: "s3", isNextPlayer: true, status: GameStatus())
        #expect(result == nil)
    }

    @Test("クイタンあり設定なら同じ手・同じ牌でチーする")
    func chiAllowedWhenKuitanAri() {
        let ai = makeAI(baseHand, kuitanAri: true)
        let result = ai.evaluateFulouCall(dapai: "s3", isNextPlayer: true, status: GameStatus())
        guard case .chi = result else {
            Issue.record("クイタンありならチーが選択されるべき: \(String(describing: result))")
            return
        }
    }

    @Test("上家以外からの捨て牌はチー候補にならない（isNextPlayer=false）")
    func chiNotAllowedWhenNotNextPlayer() {
        let ai = makeAI(baseHand)
        let result = ai.evaluateFulouCall(dapai: "s3", isNextPlayer: false, status: GameStatus())
        #expect(result == nil)
    }

    @Test("手牌と無関係な牌は鳴かない")
    func unrelatedTileIsNotCalled() {
        let ai = makeAI(baseHand)
        let result = ai.evaluateFulouCall(dapai: "z2", isNextPlayer: true, status: GameStatus())
        #expect(result == nil)
    }

    @Test("役牌のポンはクイタンなし設定でも常に許可される")
    func yakuhaiPengAllowedEvenWithoutKuitan() {
        // 2面子(m123,p456) + 役牌対子(z5z5) + 対子(z6z6) + 塔子(s12) + 浮き牌(m9) → 1シャンテン
        let tiles = ["m1","m2","m3","p4","p5","p6","z5","z5","z6","z6","s1","s2","m9"]
        let ai = makeAI(tiles, kuitanAri: false)
        let result = ai.evaluateFulouCall(dapai: "z5", isNextPlayer: false, status: GameStatus())
        guard case .peng = result else {
            Issue.record("役牌(白)のポンは許可されるべき: \(String(describing: result))")
            return
        }
    }

    // MARK: - isYakuSafeCall（役なし副露の回帰バグ修正確認）
    // バグ: 東家が北(役牌でない字牌)をポンしてしまう事象が発生。
    // 原因: クイタンあり設定なら「鳴いた牌自体が么九牌かどうか」を見ずに常に許可していた。

    @Test("役牌でない字牌（北・東家にとって）はクイタンあり設定でも役なし副露として不可")
    func nonYakuhaiHonorBlockedEvenWithKuitanAri() {
        let ai = makeAI(["m1","m2","m3"], kuitanAri: true) // 東家(id:0)・場風東のデフォルト
        #expect(ai.isYakuSafeCall(dapai: "z4", status: GameStatus()) == false)
    }

    @Test("役牌でない老頭牌（么九の数牌）もクイタンあり設定で役なし副露として不可")
    func nonYakuhaiTerminalBlockedEvenWithKuitanAri() {
        let ai = makeAI(["m1","m2","m3"], kuitanAri: true)
        #expect(ai.isYakuSafeCall(dapai: "m9", status: GameStatus()) == false)
    }

    @Test("既に役牌の対子を持っていれば、役牌でない字牌でも副露可能")
    func nonYakuhaiHonorAllowedWithExistingYakuhaiSource() {
        // z6z6（發の対子）を既に保持
        let ai = makeAI(["m1","m2","m3","z6","z6"], kuitanAri: false)
        #expect(ai.isYakuSafeCall(dapai: "z4", status: GameStatus()) == true)
    }

    @Test("役牌でない中張牌（断么九材料）はクイタンあり設定なら副露可能（従来通り）")
    func simpleTileStillAllowedWithKuitanAri() {
        let ai = makeAI(["m1","m2","m3"], kuitanAri: true)
        #expect(ai.isYakuSafeCall(dapai: "p5", status: GameStatus()) == true)
    }

    @Test("役牌でない中張牌はクイタンなし設定・役牌なしなら副露不可（従来通り）")
    func simpleTileBlockedWithoutKuitanAndNoYakuhaiSource() {
        let ai = makeAI(["m1","m2","m3"], kuitanAri: false)
        #expect(ai.isYakuSafeCall(dapai: "p5", status: GameStatus()) == false)
    }
}

//
//  DefenseHeuristicsTests.swift
//  MbMajiangTests
//
//  押し引き（AIPlayer.findSafeDiscard）の危険牌評価強化（スジ読み）のテスト。

import Testing
@testable import MbMajiang

@Suite("AIPlayer.sujiTiles: スジの算出（本スジ/片スジ）")
struct SujiTilesTests {

    private let ai = AIPlayer(id: 0)

    @Test("中膨れの4が捨てられていれば1と7の両方の形が同時に否定され、本スジになる")
    func middleTileGivesBothSidesAsFullSuji() {
        let suji = ai.sujiTiles(from: ["p4"])
        #expect(suji.full == ["p1", "p7"])
        #expect(suji.half.isEmpty)
    }

    @Test("端に近い1が捨てられていても4は片方の形(4-7)が未確認のため片スジに留まる")
    func nearEdgeGivesHalfSujiOnly() {
        let suji = ai.sujiTiles(from: ["p1"])
        #expect(suji.half == ["p4"])
        #expect(suji.full.isEmpty)
    }

    @Test("9が捨てられていても6は片方の形(3-6)が未確認のため片スジに留まる")
    func nineGivesHalfSujiOnly() {
        let suji = ai.sujiTiles(from: ["p9"])
        #expect(suji.half == ["p6"])
        #expect(suji.full.isEmpty)
    }

    @Test("1と7の両方が捨てられていれば4は本スジになる")
    func bothPartnersDiscardedPromotesToFullSuji() {
        let suji = ai.sujiTiles(from: ["p1", "p7"])
        #expect(suji.full == ["p4"])
        #expect(suji.half.isEmpty)
    }

    @Test("字牌はスジの対象にならない")
    func honorTilesHaveNoSuji() {
        let suji = ai.sujiTiles(from: ["z1"])
        #expect(suji.full.isEmpty)
        #expect(suji.half.isEmpty)
    }

    @Test("捨て牌が空ならスジも空")
    func emptyDiscardsGiveEmptySuji() {
        let suji = ai.sujiTiles(from: [])
        #expect(suji.full.isEmpty)
        #expect(suji.half.isEmpty)
    }
}

@Suite("AIPlayer.findSafeDiscard: スジ読みの優先順位")
struct FindSafeDiscardSujiTests {

    // 完全にバラバラな14枚（対子・搭子なし）→ どの牌を切ってもシャンテンは変わらず、
    // 安全度だけで選ばれることを確認しやすい形
    private let scatteredHand = ["m1","m4","m7","p1","p5","p8","s1","s4","s7","z1","z2","z3","z4","z5"]

    private func ai() -> AIPlayer { AIPlayer(id: 0) }

    @Test("現物が無い場合、相手の捨て牌に対するスジ(p4→p1/p7)が選ばれる")
    func sujiChosenWhenNoGenbutsu() {
        let idx = ai().findSafeDiscard(allLabels: scatteredHand, bingpaiCount: scatteredHand.count, genbutsuList: [["p4"]])
        #expect(idx != nil)
        #expect(scatteredHand[idx!] == "p1")
    }

    @Test("現物がある場合はスジより現物が優先される")
    func genbutsuPreferredOverSuji() {
        // m1は現物そのもの、m4はm1のスジ（両方とも手牌にある）→ 現物のm1が優先される
        let idx = ai().findSafeDiscard(allLabels: scatteredHand, bingpaiCount: scatteredHand.count, genbutsuList: [["m1"]])
        #expect(idx != nil)
        #expect(scatteredHand[idx!] == "m1")
    }

    // m1/m7/s1/s7そのものは手牌に含まず、本スジ・片スジの対象牌(m4/s4)だけが手牌にある形
    // → 現物ではなくスジの安全度だけで選ばれることを確認できる
    private let middleTileHand = ["m4","s4","p2","p3","p6","p7","p9","z1","z2","z3","z4","z5","z6","z7"]

    @Test("本スジと片スジが両方候補にある場合、本スジが優先される")
    func fullSujiPreferredOverHalfSuji() {
        // m1・m7の両方が捨てられている → m4は本スジ。s7のみ捨てられている → s4は片スジ止まり。
        // 手牌にはm4・s4がともに含まれるため、本スジのm4が優先されるはず。
        let idx = ai().findSafeDiscard(allLabels: middleTileHand, bingpaiCount: middleTileHand.count, genbutsuList: [["m1", "m7", "s7"]])
        #expect(idx != nil)
        #expect(middleTileHand[idx!] == "m4")
    }

    @Test("本スジが無ければ片スジが選ばれる")
    func halfSujiChosenWhenNoFullSuji() {
        // m1のみ捨てられている（m7は未確認）→ m4は片スジに留まるが、他に安全牌候補が無いため選ばれる
        let idx = ai().findSafeDiscard(allLabels: middleTileHand, bingpaiCount: middleTileHand.count, genbutsuList: [["m1"]])
        #expect(idx != nil)
        #expect(middleTileHand[idx!] == "m4")
    }

    @Test("現物もスジも無ければ字牌が選ばれる")
    func honorFallbackWhenNoGenbutsuOrSuji() {
        // s1に対するスジはs4のみだが手牌にs4があるとスジ扱いになってしまうので、
        // 手牌に含まれないタイルを現物指定して、字牌フォールバックを確認する
        let idx = ai().findSafeDiscard(allLabels: scatteredHand, bingpaiCount: scatteredHand.count, genbutsuList: [["p9"]])
        #expect(idx != nil)
        #expect(scatteredHand[idx!].hasPrefix("z"))
    }
}

@Suite("AIPlayer.findSafeDiscard: 発動シャンテン閾値（テンパイ以外で発動）")
struct FindSafeDiscardShantenThresholdTests {

    private func ai() -> AIPlayer { AIPlayer(id: 0) }

    @Test("1シャンテンでは安全牌探しが発動する（テンパイではないため降りる）")
    func activatesAtIishanten() {
        // 3面子+塔子2+雀頭なし(1シャンテン) + 浮き牌z1
        let hand = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","s1","s2","s4","s5","z1"]
        let idx = ai().findSafeDiscard(allLabels: hand, bingpaiCount: hand.count, genbutsuList: [["z1"]])
        #expect(idx != nil)
        #expect(hand[idx!] == "z1")
    }

    @Test("テンパイでは安全牌探しが発動しない（nilを返し押しにフォールバック）")
    func doesNotActivateAtTenpai() {
        // 4面子+単騎(テンパイ) + 浮き牌z1
        let hand = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","m4","m5","m6","m7","z1"]
        let idx = ai().findSafeDiscard(allLabels: hand, bingpaiCount: hand.count, genbutsuList: [["z1"]])
        #expect(idx == nil)
    }
}

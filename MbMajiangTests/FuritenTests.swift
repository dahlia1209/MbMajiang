//
//  FuritenTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("isFuriten")
struct FuritenTests {

    // m123 m456 p123 s789 z1 のテンパイ手（z1待ち）を持つプレイヤーを作る
    private func makeTenpaiPlayer(he: He) -> Player {
        let bingpai = ["m1","m2","m3","m4","m5","m6","p1","p2","p3","s7","s8","s9","z1"]
        let shoupai = Shoupai(bingpai)
        return Player(id: 0, shoupai: shoupai, he: he)
    }

    @Test("捨て牌にアガリ牌あり → フリテン")
    func furitenWithQipai() {
        let he = He(qipai: [Pai("z1")])
        let player = makeTenpaiPlayer(he: he)
        #expect(player.isFuriten() == true)
    }

    @Test("捨て牌にアガリ牌なし → フリテンなし")
    func noFuritenWithoutQipai() {
        let he = He(qipai: [Pai("p5")])
        let player = makeTenpaiPlayer(he: he)
        #expect(player.isFuriten() == false)
    }

    @Test("アガリ牌を捨てた後に副露された → フリテン（バグ確認）")
    func furitenAfterCalledTile() {
        // z1を捨てたが他プレイヤーに副露された → calledPaiに移動
        let he = He(qipai: [Pai("z1")])
        let a = he.callLast()  // z1がqipaiからcalledPaiへ移動
        // この時点でqipaiは空、calledPaiにz1がある
        #expect(he.qipai.isEmpty)

        let player = makeTenpaiPlayer(he: he)
        // z1はアガリ牌なのでフリテンのはずだが、バグがあるとfalseになる
        #expect(player.isFuriten() == true)
    }

    @Test("副露されていない他の牌のみ → フリテンなし")
    func noFuritenWithOnlyCalledNonWinTile() {
        // p5を捨てて副露された（アガリ牌ではない）
        let he = He(qipai: [Pai("p5")])
        let a = he.callLast()
        let player = makeTenpaiPlayer(he: he)
        #expect(player.isFuriten() == false)
    }

    // MARK: - 副露ありのフリテン判定

    // m1m2m3 ポン後: bingpai = m4m5m6 p1p2p3 s7s8s9 z1z1 (10枚, z1待ち)
    // z1を捨てた後にフリテンになるか確認
    private func makeFulouTenpaiPlayer(he: He) -> Player {
        let bingpai = ["m4","m5","m6","p1","p2","p3","s7","s8","s9","z1"]
        var shoupai = Shoupai(bingpai)
        // m1m1m1のポン副露を追加
        var nakiPai = Pai("m1"); nakiPai.rotated = true
        shoupai.fulou = [[nakiPai, Pai("m1"), Pai("m1")]]
        return Player(id: 0, shoupai: shoupai, he: he)
    }

    @Test("副露ありでアガリ牌を捨てた → フリテン")
    func furitenWithFulou() {
        let he = He(qipai: [Pai("z1")])
        let player = makeFulouTenpaiPlayer(he: he)
        #expect(player.isFuriten() == true)
    }

    @Test("副露ありでアガリ牌を捨てて副露された → フリテン（バグ修正確認）")
    func furitenWithFulouAndCalledTile() {
        let he = He(qipai: [Pai("z1")])
        he.callLast()
        let player = makeFulouTenpaiPlayer(he: he)
        #expect(player.isFuriten() == true)
    }

    @Test("副露ありでアガリ牌でない牌のみ → フリテンなし")
    func noFuritenWithFulou() {
        let he = He(qipai: [Pai("p5")])
        let player = makeFulouTenpaiPlayer(he: he)
        #expect(player.isFuriten() == false)
    }
}

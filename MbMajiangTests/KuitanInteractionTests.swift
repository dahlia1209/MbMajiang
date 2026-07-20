//
//  KuitanInteractionTests.swift
//  MbMajiangTests
//
//  「クイタンなし」設定と副露状態の組み合わせによる断么九成立条件のテスト。
//  ルール: 門前なら kuitanAri 設定に関係なく断么九成立。副露ありの場合のみ
//  kuitanAri 設定に従う（なしなら不成立）。

import Testing
@testable import MbMajiang

@Suite("断么九 × クイタン設定 × 副露状態")
struct KuitanInteractionTests {

    private func ctx(menqian: Bool, kuitanAri: Bool, winTile: String) -> HuleContext {
        HuleContext(
            zhuangfeng: .東, menfeng: .南,
            zimo: false, menqian: menqian,
            lizhi: false, daburi: false, yifa: false,
            qianggang: false, lingshang: false,
            haidi: false, hedi: false,
            tianhu: false, dihu: false,
            winTile: winTile,
            kuitanAri: kuitanAri
        )
    }

    private func has(_ result: (yaku: [Yaku], fu: Int), _ name: String) -> Bool {
        result.yaku.contains { $0.name == name }
    }

    @Test("門前 + クイタンあり → 断么九成立")
    func closedHandWithKuitanAri() {
        let tiles = ["m2","m3","m4","p5","p6","p7","s2","s3","s4","m6","m7","m8","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(menqian: true, kuitanAri: true, winTile: "m5"))
        #expect(has(result, "断么九"))
    }

    @Test("門前 + クイタンなし → それでも断么九成立（門前なら設定の影響を受けない）")
    func closedHandWithKuitanNashi() {
        let tiles = ["m2","m3","m4","p5","p6","p7","s2","s3","s4","m6","m7","m8","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(menqian: true, kuitanAri: false, winTile: "m5"))
        #expect(has(result, "断么九"))
    }

    @Test("副露あり + クイタンあり → 断么九成立")
    func openHandWithKuitanAri() {
        let tiles = ["m2","m3","m4","s2","s3","s4","m6","m7","m8","m5","m5"]
        let result = Hule.getYaku(
            tiles: tiles,
            context: ctx(menqian: false, kuitanAri: true, winTile: "m5"),
            fulouTiles: ["p567"]
        )
        #expect(has(result, "断么九"))
    }

    @Test("副露あり + クイタンなし → 断么九不成立")
    func openHandWithKuitanNashi() {
        let tiles = ["m2","m3","m4","s2","s3","s4","m6","m7","m8","m5","m5"]
        let result = Hule.getYaku(
            tiles: tiles,
            context: ctx(menqian: false, kuitanAri: false, winTile: "m5"),
            fulouTiles: ["p567"]
        )
        #expect(!has(result, "断么九"))
    }
}

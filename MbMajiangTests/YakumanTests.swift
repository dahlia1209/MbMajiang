//
//  YakumanTests.swift
//  MbMajiangTests
//
//  役満（大三元・小四喜・大四喜・字一色・緑一色・清老頭・九蓮宝燈）のテスト。
//  四槓子は HuleGetYakuTests に既存テストがあるため対象外。

import Testing
@testable import MbMajiang

@Suite("役満")
struct YakumanTests {

    private func ctx(
        zhuangfeng: Feng = .東,
        menfeng: Feng = .南,
        zimo: Bool = false,
        menqian: Bool = true,
        winTile: String = "m1"
    ) -> HuleContext {
        HuleContext(
            zhuangfeng: zhuangfeng, menfeng: menfeng,
            zimo: zimo, menqian: menqian,
            lizhi: false, daburi: false, yifa: false,
            qianggang: false, lingshang: false,
            haidi: false, hedi: false,
            tianhu: false, dihu: false,
            winTile: winTile
        )
    }

    private func has(_ result: (yaku: [Yaku], fu: Int), _ name: String) -> Bool {
        result.yaku.contains { $0.name == name }
    }

    private func fan(_ result: (yaku: [Yaku], fu: Int), _ name: String) -> Int? {
        result.yaku.first { $0.name == name }?.fanshu
    }

    @Test("大三元 → 役満(100)")
    func daisangen() {
        // 白z5 発z6 中z7（三元牌すべて暗刻）+ m123 + 雀頭m8
        let tiles = ["z5","z5","z5","z6","z6","z6","z7","z7","z7","m1","m2","m3","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m2"))
        #expect(has(result, "大三元"))
        #expect(fan(result, "大三元") == Yaku.yakuman)
    }

    @Test("小四喜 → 役満(100)（風牌3つが刻子、残り1つが雀頭）")
    func shousuushi() {
        // 東z1 南z2 西z3（暗刻）+ m123 + 雀頭 北z4
        let tiles = ["z1","z1","z1","z2","z2","z2","z3","z3","z3","m1","m2","m3","z4","z4"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m2"))
        #expect(has(result, "小四喜"))
        #expect(fan(result, "小四喜") == Yaku.yakuman)
    }

    @Test("大四喜 → ダブル役満(200)（風牌4つすべて刻子）")
    func daisuushi() {
        // 東南西北すべて暗刻 + 雀頭m5
        let tiles = ["z1","z1","z1","z2","z2","z2","z3","z3","z3","z4","z4","z4","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m5"))
        #expect(has(result, "大四喜"))
        #expect(fan(result, "大四喜") == Yaku.doubleYakuman)
    }

    @Test("字一色 → 役満(100)（字牌のみ）")
    func tsuuiisou() {
        let tiles = ["z1","z1","z1","z2","z2","z2","z5","z5","z5","z6","z6","z6","z7","z7"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z2"))
        #expect(has(result, "字一色"))
        #expect(fan(result, "字一色") == Yaku.yakuman)
    }

    @Test("緑一色 → 役満(100)（索子2,3,4,6,8と發のみ）")
    func ryuuiisou() {
        let tiles = ["s2","s3","s4","s2","s3","s4","s6","s6","s6","s8","s8","s8","z6","z6"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "s4"))
        #expect(has(result, "緑一色"))
        #expect(fan(result, "緑一色") == Yaku.yakuman)
    }

    @Test("清老頭 → 役満(100)（老頭牌のみ）")
    func chinroutou() {
        let tiles = ["m1","m1","m1","m9","m9","m9","p1","p1","p1","s9","s9","s9","p9","p9"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m9"))
        #expect(has(result, "清老頭"))
        #expect(fan(result, "清老頭") == Yaku.yakuman)
    }

    @Test("九蓮宝燈（純正でない） → 役満(100)")
    func chuurenpoutouRegular() {
        // 14枚: m1×3, m2,m3,m4, m5×2（余分）, m6,m7,m8, m9×3。和了牌はm3（余分位置=m5とは異なる）
        let tiles = ["m1","m1","m1","m2","m3","m4","m5","m5","m6","m7","m8","m9","m9","m9"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, menqian: true, winTile: "m3"))
        #expect(has(result, "九蓮宝燈"))
        #expect(fan(result, "九蓮宝燈") == Yaku.yakuman)
        #expect(!has(result, "純正九蓮宝燈"))
    }

    @Test("純正九蓮宝燈 → ダブル役満(200)（和了前が基本形ちょうど）")
    func chuurenpoutouPure() {
        // 14枚: m1×3, m2,m3,m4, m5×2, m6,m7,m8, m9×3。和了牌がm5（余分位置と一致）→ 和了前13枚が基本形ちょうど
        let tiles = ["m1","m1","m1","m2","m3","m4","m5","m5","m6","m7","m8","m9","m9","m9"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, menqian: true, winTile: "m5"))
        #expect(has(result, "純正九蓮宝燈"))
        #expect(fan(result, "純正九蓮宝燈") == Yaku.doubleYakuman)
    }

    // MARK: - 役満の複合

    @Test("大四喜 + 字一色 → 両方成立（複合）")
    func daisuushiWithTsuuiisou() {
        // 東南西北すべて暗刻 + 雀頭 白（全て字牌）
        let tiles = ["z1","z1","z1","z2","z2","z2","z3","z3","z3","z4","z4","z4","z5","z5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z5"))
        #expect(has(result, "大四喜"))
        #expect(has(result, "字一色"))
        #expect(fan(result, "大四喜") == Yaku.doubleYakuman)
        #expect(fan(result, "字一色") == Yaku.yakuman)
    }

    @Test("大三元 + 字一色 → 両方成立（複合）")
    func daisangenWithTsuuiisou() {
        // 白發中すべて暗刻 + 東暗刻 + 雀頭 南（全て字牌）
        let tiles = ["z5","z5","z5","z6","z6","z6","z7","z7","z7","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z2"))
        #expect(has(result, "大三元"))
        #expect(has(result, "字一色"))
        #expect(fan(result, "大三元") == Yaku.yakuman)
        #expect(fan(result, "字一色") == Yaku.yakuman)
    }

    @Test("清老頭 + 四暗刻単騎 → 両方成立（複合、単騎待ちで全暗刻を維持）")
    func chinroutouWithSuuankouTanki() {
        // m1 m9 p1 s9 すべて暗刻 + 単騎待ちp9（和了牌が雀頭のみに影響し、刻子は明刻化されない）
        let tiles = ["m1","m1","m1","m9","m9","m9","p1","p1","p1","s9","s9","s9","p9","p9"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "p9"))
        #expect(has(result, "清老頭"))
        #expect(has(result, "四暗刻単騎待ち"))
        #expect(fan(result, "清老頭") == Yaku.yakuman)
        #expect(fan(result, "四暗刻単騎待ち") == Yaku.doubleYakuman)
    }
}

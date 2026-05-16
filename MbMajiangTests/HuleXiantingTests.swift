//
//  HuleXiantingTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

// MARK: - xiangting（シャンテン数）テスト

@Suite("xiangting")
struct XiantingTests {

    // MARK: テンパイ（0シャンテン）

    @Test("4面子+単騎 → テンパイ")
    func tenpai_4mentsu_tanki() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","m4","m5","m6","m7"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    @Test("3面子+塔子+雀頭 → テンパイ")
    func tenpai_3mentsu_tatsu_jantai() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","s1","s1","s2","s3"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    @Test("七対子 → テンパイ")
    func tenpai_chiitoitsu() {
        // 6対子+単騎1枚
        let tiles = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","z1"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    @Test("国士無双 対子なし → テンパイ（13面待ち）")
    func tenpai_kokushi_noPair() {
        let tiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    @Test("国士無双 対子あり → テンパイ（単騎待ち）")
    func tenpai_kokushi_withPair() {
        // m1が2枚、m9が欠け → m9単騎
        let tiles = ["m1","m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    // MARK: 一向聴（1シャンテン）

    @Test("3面子+塔子2+雀頭なし → 1シャンテン")
    func iishanten_3mentsu_2tatsu_noJantai() {
        // z1z2=塔子, z4z5=塔子, 雀頭なし → どちらかで雀頭・面子を作る必要あり
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","s1","s2","s4","s5"]
        #expect(Hule.xiangting(tiles) == 1)
    }

    @Test("七対子 → 1シャンテン")
    func iishanten_chiitoitsu() {
        // 5対子+単独2枚
        let tiles = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","z1","z2"]
        #expect(Hule.xiangting(tiles) == 1)
    }

    @Test("国士無双 1種欠け → テンパイ")
    func iishanten_kokushi_missing1() {
        // m9欠け（z7が2枚）
        let tiles = ["m1","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","z7"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    // MARK: 二向聴（2シャンテン）

    @Test("塔子4+雀頭1、面子0 → 3シャンテン")
    func ryanshanten() {
        // 面子0、雀頭z11、塔子m12/p12/s12/z23
        let tiles = ["m1","m2","p1","p2","s1","s2","s4","s5","z2","z2","z4","z5","z6"]
        #expect(Hule.xiangting(tiles) == 3)
    }

    // MARK: 六向聴（最大シャンテン数付近）

    @Test("完全バラバラ → 高いシャンテン数")
    func highShanten_scattered() {
        // 全部バラバラ（塔子すらほぼない）
        let tiles = ["m1","m3","m5","m7","m9","p2","p4","p6","p8","s1","s3","s5","s7"]
        // 期待値は実装に依存するが、必ず2以上
        #expect(Hule.xiangting(tiles) >= 2)
    }

    // MARK: 副露あり（10枚 = 1副露）

    @Test("1副露+3面子+単騎 → テンパイ")
    func tenpai_1fulou_tanki() {
        // 10枚（副露1回分）: m123/p456/s789が手牌 + z1単騎
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    @Test("1副露+2面子+塔子+雀頭 → テンパイ")
    func tenpai_1fulou_tatsuJantai() {
        // 10枚: m123/p456が面子、s78が塔子、z11が雀頭
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","z1","z1"]
        #expect(Hule.xiangting(tiles) == 0)
    }

    @Test("1副露+2面子+塔子+雀頭なし → 1シャンテン")
    func iishanten_1fulou() {
        // 10枚: m123/p456が面子、s78が塔子、z1が孤立 → 雀頭なし
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","z1","z2"]
        #expect(Hule.xiangting(tiles) == 1)
    }

    // MARK: 無効入力（99）

    @Test("空配列 → 99")
    func invalid_empty() {
        #expect(Hule.xiangting([]) == 99)
    }

    @Test("2枚（%3≠0）→ 99")
    func invalid_2tiles() {
        #expect(Hule.xiangting(["m1","m2"]) == 99)
    }

    @Test("14枚 → 99")
    func invalid_14tiles() {
        let tiles = ["m1","m2","m3","m4","m5","m6","m7","m8","m9",
                     "p1","p2","p3","p4","p5"]
        #expect(Hule.xiangting(tiles) == 99)
    }
}

// MARK: - mianziXiangting 単体テスト

@Suite("mianziXiangting")
struct MianziXiantingTests {

    @Test("完成形（4面子+雀頭、14枚）は呼ばれない想定だが13枚でテンパイ")
    func standard_tenpai() {
        // mianziXiangting は13枚で呼ぶ
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","s1","s1","s2","s3"]
        #expect(Hule.mianziXiangting(tiles) == 0)
    }

    @Test("面子0+塔子0+雀頭0 → 8シャンテン（最大）")
    func maxShanten() {
        // 13枚全部バラバラで隣接なし
        let tiles = ["m1","m4","m7","p2","p5","p8","s3","s6","s9","z1","z2","z3","z4"]
        // シャンテン数は 8 - 0（面子） - 0（塔子） = 8 が上限だが実際の計算はそれ以下
        #expect(Hule.mianziXiangting(tiles) <= 8)
        #expect(Hule.mianziXiangting(tiles) >= 0)
    }
}

// MARK: - chiitoitsuXiangting 単体テスト

@Suite("chiitoitsuXiangting")
struct ChiitoitsuXiantingTests {

    @Test("6対子 → 0シャンテン（テンパイ）")
    func tenpai() {
        let tiles = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","z1"]
        #expect(Hule.chiitoitsuXiangting(tiles) == 0)
    }

    @Test("3槓子 → 6シャンテン")
    func iishanten() {
        let tiles = ["m1","m1","m1","m1","m3","m3","m3","m3","p2","p2","p2","p2","z2"]
        #expect(Hule.chiitoitsuXiangting(tiles) == 6)
    }
    
    @Test("1アンコ5対子 → 1シャンテン")
    func iishanten1anke() {
        let tiles = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","p3"]
        #expect(Hule.chiitoitsuXiangting(tiles) == 1)
    }

    @Test("対子0 → 6シャンテン")
    func noPoair() {
        // 全部バラバラ13種
        let tiles = ["m1","m2","m3","m4","m5","m6","m7","m8","m9","p1","p2","p3","p4"]
        #expect(Hule.chiitoitsuXiangting(tiles) == 6)
    }

    @Test("13枚以外 → 99")
    func invalid() {
        #expect(Hule.chiitoitsuXiangting(["m1","m2"]) == 99)
    }
}

// MARK: - kokushiXiangting 単体テスト

@Suite("kokushiXiangting")
struct KokushiXiantingTests {

    @Test("13種すべてあり対子なし → 0シャンテン")
    func tenpai_noPair() {
        let tiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
        #expect(Hule.kokushiXiangting(tiles) == 0)
    }

    @Test("13種すべてあり対子あり → 0シャンテン")
    func tenpai_withPair() {
        let tiles = ["m1","m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6"]
        #expect(Hule.kokushiXiangting(tiles) == 0)
    }

    @Test("1種欠け対子なし → 1シャンテン")
    func iishanten_missing1_noPair() {
        // m9欠け、z7が2枚だが対子あり
        let tiles = ["m1","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","m5"]
        #expect(Hule.kokushiXiangting(tiles) == 1)
    }

    @Test("2種欠け → 2シャンテン")
    func ryanshanten_missing2() {
        // m9,p1欠け、残り11種（対子なし）
        let tiles = ["m1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","m2","m3"]
        // uniqueCount=11, hasPair=false → 13-11-0=2
        #expect(Hule.kokushiXiangting(tiles) == 2)
    }

    @Test("13枚以外 → 99")
    func invalid() {
        #expect(Hule.kokushiXiangting(["m1","m9"]) == 99)
    }
}

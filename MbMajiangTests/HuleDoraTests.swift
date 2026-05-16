//
//  HuleDoraTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

// MARK: - akaDoraCount

@Suite("akaDoraCount")
struct AkaDoraCountTests {

    @Test("赤ドラなし → 0")
    func noneAka() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z2","z3"]
        #expect(Hule.akaDoraCount(tiles: tiles) == 0)
    }

    @Test("m0が1枚 → 1")
    func oneAkaMan() {
        #expect(Hule.akaDoraCount(tiles: ["m0","m1","m2"]) == 1)
    }

    @Test("p0が1枚 → 1")
    func oneAkaPin() {
        #expect(Hule.akaDoraCount(tiles: ["p0","p1","p2"]) == 1)
    }

    @Test("s0が1枚 → 1")
    func oneAkaSou() {
        #expect(Hule.akaDoraCount(tiles: ["s0","s1","s2"]) == 1)
    }

    @Test("m0/p0/s0が各1枚 → 3")
    func allThreeAka() {
        #expect(Hule.akaDoraCount(tiles: ["m0","p0","s0"]) == 3)
    }

    @Test("m0が2枚（通常はないが） → 2")
    func twoAkaMan() {
        #expect(Hule.akaDoraCount(tiles: ["m0","m0","m1"]) == 2)
    }

    @Test("z牌は赤ドラ対象外 → 0")
    func zipaiNotAka() {
        #expect(Hule.akaDoraCount(tiles: ["z1","z2","z3","z4","z5","z6","z7"]) == 0)
    }

    @Test("空配列 → 0")
    func empty() {
        #expect(Hule.akaDoraCount(tiles: []) == 0)
    }
}

// MARK: - doraCount（指示牌ベースのドラ）

@Suite("doraCount")
struct DoraCountTests {

    // MARK: 基本動作

    @Test("指示牌なし → 0")
    func noIndicator() {
        let tiles = ["m5","m5","m5","p1","p2","p3"]
        #expect(Hule.doraCount(tiles: tiles, baopaiLabels: []) == 0)
    }

    @Test("指示牌p1 → ドラはp2")
    func p1IndicatorP2Dora() {
        // p1が指示牌 → p2がドラ
        #expect(Hule.doraCount(tiles: ["p2","p3","p4"], baopaiLabels: ["p1"]) == 1)
        #expect(Hule.doraCount(tiles: ["p3","p4","p5"], baopaiLabels: ["p1"]) == 0)
    }

    @Test("指示牌p9 → ドラはp1（wraparound）")
    func p9IndicatorP1Dora() {
        #expect(Hule.doraCount(tiles: ["p1","p2","p3"], baopaiLabels: ["p9"]) == 1)
        #expect(Hule.doraCount(tiles: ["p9","p8","p7"], baopaiLabels: ["p9"]) == 0)
    }

    @Test("指示牌z4 → ドラはz1（風牌wraparound）")
    func z4IndicatorZ1Dora() {
        #expect(Hule.doraCount(tiles: ["z1","z2","z3"], baopaiLabels: ["z4"]) == 1)
        #expect(Hule.doraCount(tiles: ["z4","z4","z4"], baopaiLabels: ["z4"]) == 0)
    }

    @Test("指示牌z7 → ドラはz5（三元牌wraparound）")
    func z7IndicatorZ5Dora() {
        #expect(Hule.doraCount(tiles: ["z5","z6","z7"], baopaiLabels: ["z7"]) == 1)
        #expect(Hule.doraCount(tiles: ["z7","z6"], baopaiLabels: ["z7"]) == 0)
    }

    // MARK: 赤ドラ関連

    @Test("指示牌p4 → ドラはp5とp0（赤五筒もドラ）")
    func p4IndicatorP5AndP0Dora() {
        // p5は通常ドラ
        #expect(Hule.doraCount(tiles: ["p5","p6","p7"], baopaiLabels: ["p4"]) == 1)
        // p0（赤五筒）も指示牌ベースのドラ
        #expect(Hule.doraCount(tiles: ["p0","p6","p7"], baopaiLabels: ["p4"]) == 1)
        // p5とp0が両方あれば2
        #expect(Hule.doraCount(tiles: ["p5","p0","p7"], baopaiLabels: ["p4"]) == 2)
    }

    @Test("指示牌p5 → ドラはp6（p0はドラでない）")
    func p5IndicatorP6DoraNotP0() {
        #expect(Hule.doraCount(tiles: ["p6","p7","p8"], baopaiLabels: ["p5"]) == 1)
        // p0は指示牌p5のドラではない
        #expect(Hule.doraCount(tiles: ["p0","p7","p8"], baopaiLabels: ["p5"]) == 0)
    }

    @Test("赤ドラp0が指示牌のとき → ドラはp6")
    func p0AsIndicator() {
        // p0が指示牌 → p6がドラ
        #expect(Hule.doraCount(tiles: ["p6","p7","p8"], baopaiLabels: ["p0"]) == 1)
        #expect(Hule.doraCount(tiles: ["p5","p4","p3"], baopaiLabels: ["p0"]) == 0)
    }

    // MARK: 複数枚・複数指示牌

    @Test("同じドラ牌が3枚 → 3")
    func threeSameDora() {
        #expect(Hule.doraCount(tiles: ["p2","p2","p2"], baopaiLabels: ["p1"]) == 3)
    }

    @Test("指示牌2枚（槓ドラ）→ 各自加算")
    func twoIndicators() {
        // p1→p2, m1→m2 の2指示牌、手牌にp2とm2が各1枚
        let tiles = ["p2","m2","s3"]
        #expect(Hule.doraCount(tiles: tiles, baopaiLabels: ["p1","m1"]) == 2)
    }

    @Test("指示牌2枚で赤ドラ重複カウントなし")
    func twoIndicatorsNoAkaDuplication() {
        // p4→p5,p0 / m1→m2 の2指示牌
        // 手牌にp0が1枚 → doraCountでは指示牌p4分の+1のみ
        let tiles = ["p0","m3","s3"]
        #expect(Hule.doraCount(tiles: tiles, baopaiLabels: ["p4","m1"]) == 1)
    }

    @Test("存在しない指示牌ラベル → 0")
    func unknownIndicator() {
        #expect(Hule.doraCount(tiles: ["m1","m2","m3"], baopaiLabels: ["x9"]) == 0)
    }
}

// MARK: - akaDoraCount + doraCount の組み合わせ（getYaku内の実際の使い方を模倣）

@Suite("doraCount + akaDoraCount 組み合わせ")
struct CombinedDoraTests {

    @Test("指示牌p4、手牌にp0 → 合計2ドラ（指示牌1 + 赤ドラ1）")
    func p4IndicatorWithAka() {
        let tiles = ["p0","p1","p2"]
        let regular = Hule.doraCount(tiles: tiles, baopaiLabels: ["p4"])
        let aka     = Hule.akaDoraCount(tiles: tiles)
        #expect(regular + aka == 2) // p0: 指示牌ドラ+1, 赤ドラ+1
    }

    @Test("指示牌p5、手牌にp0 → 合計1ドラ（赤ドラのみ）")
    func p5IndicatorWithAka() {
        let tiles = ["p0","p1","p2"]
        let regular = Hule.doraCount(tiles: tiles, baopaiLabels: ["p5"])
        let aka     = Hule.akaDoraCount(tiles: tiles)
        #expect(regular + aka == 1) // p0: 赤ドラ+1のみ（p5の指示牌ドラはp6）
    }

    @Test("指示牌2枚でも赤ドラは1回だけカウント")
    func twoIndicatorsAkaCountedOnce() {
        let tiles = ["p0","m1","s1"]
        let regular = Hule.doraCount(tiles: tiles, baopaiLabels: ["p4","p1"])
        let aka     = Hule.akaDoraCount(tiles: tiles)
        // p0: 指示牌p4のドラ+1 、赤ドラ+1 → 計2（指示牌が2枚でも赤ドラは1回）
        #expect(regular + aka == 2)
    }
}

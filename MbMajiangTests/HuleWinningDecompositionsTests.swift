//
//  HuleWinningDecompositionsTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("winningDecompositions")
struct WinningDecompositionsTests {

    // MARK: - 標準形（4面子+1雀頭）

    @Test("4順子+雀頭 → 分解あり、nShunzi==4 かつ nToitsu==1")
    func fourShunziOnePair() {
        let tiles = ["m1","m2","m3","m4","m5","m6","p7","p8","p9","s1","s2","s3","z1","z1"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.nShunzi == 4 && $0.nToitsu == 1 })
    }

    @Test("4刻子+雀頭（対々和） → 分解あり、nKezi==4 かつ nToitsu==1")
    func fourKeziOnePair() {
        let tiles = ["m1","m1","m1","p2","p2","p2","s3","s3","s3","z1","z1","z1","z2","z2"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.nKezi == 4 && $0.nToitsu == 1 })
    }

    @Test("3順子+1刻子+雀頭 → 分解あり")
    func mixedMentsu() {
        // m123, p456, s789, z1z1z1, z2z2
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.nShunzi == 3 && $0.nKezi == 1 && $0.nToitsu == 1 })
    }

    @Test("雀頭が字牌 → 分解あり")
    func honorPair() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","m7","m8","m9","z5","z5"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.nToitsu == 1 && $0.jantai == "z5" })
    }

    // MARK: - 七対子

    @Test("七対子（全種異なる7対） → isChitoitsu == true の分解あり")
    func chitoitsu() {
        let tiles = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","z1","z1"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.isChitoitsu() })
    }

    @Test("同牌4枚を含む手牌 → isChitoitsu == false（七対子無効）")
    func chitoitsuWithDuplicatePair() {
        // m1×4 は七対子の2対目に使えない
        let tiles = ["m1","m1","m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","z1","z1"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.contains { $0.isChitoitsu() })
    }

    // MARK: - 国士無双

    @Test("国士無双（13種+m1対子） → isKokushimuso == true の分解あり")
    func kokushiWithPair() {
        let tiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","m1"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.isKokushimuso() })
    }

    @Test("国士無双（13種+z7対子） → isKokushimuso == true の分解あり")
    func kokushiWithHonorPair() {
        let tiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","z7"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.isEmpty)
        #expect(result.contains { $0.isKokushimuso() })
    }

    @Test("国士無双崩れ（1種欠け） → 空")
    func kokushiMissing() {
        // m9欠け、z7が2枚
        let tiles = ["m1","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","z7","m2"]
        let result = Hule.winningDecompositions(tiles)
        #expect(!result.contains { $0.isKokushimuso() })
    }

    // MARK: - 複数分解

    @Test("同色4枚×3種+雀頭 → 2通り以上の分解")
    func multipleDecompositions() {
        // m1×4, m2×4, m3×4, z1×2 = 14枚
        // 分解1: m123×4 + z11（4順子）
        // 分解2: m111+m222+m333+m123 + z11（刻子+順子混在）
        let tiles = ["m1","m2","m3","m1","m2","m3","m1","m2","m3","m1","m2","m3","z1","z1"]
        let result = Hule.winningDecompositions(tiles)
        #expect(result.count >= 2)
        #expect(result.contains { $0.nShunzi == 4 && $0.nToitsu == 1 })
        #expect(result.contains { $0.nKezi >= 1 && $0.nShunzi >= 1 && $0.nToitsu == 1 })
    }

    // MARK: - 副露あり

    @Test("1副露（チー） + 手牌11枚 → 分解あり")
    func with1FulouChi() {
        // 手牌11枚: m123/p456/s789 + z11
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1"]
        // 副露: s456（チー）
        let result = Hule.winningDecompositions(tiles, ["s456"])
        #expect(!result.isEmpty)
    }

    @Test("1副露（ポン） + 手牌11枚 → 分解あり")
    func with1FulouPon() {
        // 手牌11枚: m123/p456/s789 + z2z2
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z2","z2"]
        // 副露: z111（ポン）
        let result = Hule.winningDecompositions(tiles, ["z111"])
        #expect(!result.isEmpty)
    }

    @Test("2副露 + 手牌8枚 → 分解あり")
    func with2Fulou() {
        // 手牌8枚: m123/p456 + z1z1
        let tiles = ["m1","m2","m3","p4","p5","p6","z1","z1"]
        let result = Hule.winningDecompositions(tiles, ["s789","m456"])
        #expect(!result.isEmpty)
    }

    // MARK: - 和了でない手（空配列）

    @Test("バラバラな14枚 → 空")
    func notWinning() {
        let tiles = ["m1","m3","m5","m7","p2","p4","p6","p8","s1","s3","s5","z1","z2","z3"]
        #expect(Hule.winningDecompositions(tiles).isEmpty)
    }

    @Test("13枚テンパイ形 → 空（14枚でないため）")
    func tenpai13tiles() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z2","z3"]
        #expect(Hule.winningDecompositions(tiles).isEmpty)
    }

    // MARK: - 無効入力

    @Test("0枚 → 空")
    func emptyInput() {
        #expect(Hule.winningDecompositions([]).isEmpty)
    }

    @Test("1枚 → 空")
    func singleTile() {
        #expect(Hule.winningDecompositions(["m1"]).isEmpty)
    }

    @Test("15枚（奇数で無効） → 空")
    func invalidCount15() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z2","z3","z4","z5"]
        #expect(Hule.winningDecompositions(tiles).isEmpty)
    }
}

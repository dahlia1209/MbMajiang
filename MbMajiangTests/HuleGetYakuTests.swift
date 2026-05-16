//
//  HuleGetYakuTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("getYaku")
struct GetYakuTests {

    private func ctx(
        zhuangfeng: Feng = .東,
        menfeng: Feng = .南,
        zimo: Bool = false,
        menqian: Bool = true,
        lizhi: Bool = false,
        daburi: Bool = false,
        yifa: Bool = false,
        qianggang: Bool = false,
        lingshang: Bool = false,
        haidi: Bool = false,
        hedi: Bool = false,
        tianhu: Bool = false,
        dihu: Bool = false,
        winTile: String = "m1"
    ) -> HuleContext {
        HuleContext(
            zhuangfeng: zhuangfeng, menfeng: menfeng,
            zimo: zimo, menqian: menqian,
            lizhi: lizhi, daburi: daburi, yifa: yifa,
            qianggang: qianggang, lingshang: lingshang,
            haidi: haidi, hedi: hedi,
            tianhu: tianhu, dihu: dihu,
            winTile: winTile
        )
    }

    private func has(_ result: (yaku: [Yaku], fu: Int), _ name: String) -> Bool {
        result.yaku.contains { $0.name == name }
    }

    private func fan(_ result: (yaku: [Yaku], fu: Int), _ name: String) -> Int? {
        result.yaku.first { $0.name == name }?.fanshu
    }

    // MARK: - 非和了・役なし

    @Test("非和了形 → yaku 空")
    func notWinning() {
        let tiles = ["m1","m3","m5","m7","p2","p4","p6","p8","s1","s3","s5","z1","z2","z3"]
        #expect(Hule.getYaku(tiles: tiles, context: ctx()).yaku.isEmpty)
    }

    @Test("副露あり・役なし → yaku 空")
    func noYakuFulou() {
        // m234, p567, s234, m123(チー副露), m66
        let tiles = ["m2","m3","m4","p5","p6","p7","s2","s3","s4","m6","m6"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(menqian: false, winTile: "m6"),
                                  fulouTiles: ["m123"])
        #expect(result.yaku.isEmpty)
    }

    // MARK: - 断么九

    @Test("断么九 → 1翻")
    func tanyao() {
        // m234, p567, s234, m678, m55
        let tiles = ["m2","m3","m4","p5","p6","p7","s2","s3","s4","m6","m7","m8","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m5"))
        #expect(has(result, "断么九"))
        #expect(fan(result, "断么九") == 1)
    }

    @Test("断么九（副露あり） → 1翻")
    func tanyaoFulou() {
        let tiles = ["m2","m3","m4","p5","p6","p7","s2","s3","s4","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(menqian: false, winTile: "m5"),
                                  fulouTiles: ["p456"])
        #expect(has(result, "断么九"))
    }

    // MARK: - 平和

    @Test("平和（リャンメン高端待ち） → 平和あり")
    func pinghu() {
        // m123, m567, p456, s789, m88  winTile=m7（m567の高端）
        let tiles = ["m1","m2","m3","m5","m6","m7","p4","p5","p6","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "m7"))
        #expect(has(result, "平和"))
    }

    @Test("平和（副露あり） → 平和なし")
    func pinghuFulou() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(menqian: false, winTile: "m5"),
                                  fulouTiles: ["m456"])
        #expect(!has(result, "平和"))
    }

    @Test("平和（カンチャン待ち） → 平和なし")
    func pinghuKanchan() {
        // m123, m456, p456, s789, m88  winTile=m5（m456の中央=カンチャン）
        let tiles = ["m1","m2","m3","m4","m5","m6","p4","p5","p6","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(lizhi: true, winTile: "m5"))
        #expect(!has(result, "平和"))
    }

    // MARK: - 一盃口 / 二盃口

    @Test("一盃口 → 1翻")
    func iipeiko() {
        // m123×2, p456, s789, z22
        let tiles = ["m1","m2","m3","m1","m2","m3","p4","p5","p6","s7","s8","s9","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z2"))
        #expect(has(result, "一盃口"))
        #expect(fan(result, "一盃口") == 1)
    }

    @Test("二盃口 → 3翻（一盃口と複合しない）")
    func ryanpeiko() {
        // m123×2, p456×2, z22
        let tiles = ["m1","m2","m3","m1","m2","m3","p4","p5","p6","p4","p5","p6","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z2"))
        #expect(has(result, "二盃口"))
        #expect(fan(result, "二盃口") == 3)
        #expect(!has(result, "一盃口"))
    }

    // MARK: - 七対子

    @Test("七対子 → 2翻")
    func chiitoi() {
        let tiles = ["m1","m1","m5","m5","m3","m3","p1","p1","p5","p5","p3","p3","z1","z1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z1"))
        #expect(has(result, "七対子"))
        #expect(fan(result, "七対子") == 2)
    }
    
    @Test("七対子 + 断么九 → 3翻")
    func chiitoiTanyao() {
        let tiles = ["m2","m2","m5","m5","m3","m3","p2","p2","p5","p5","p3","p3","s3","s3"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "s3"))
        #expect(has(result, "七対子"))
        #expect(fan(result, "七対子") == 2)
        #expect(has(result, "断么九"))
        #expect(fan(result, "断么九") == 1)
    }
    
    @Test("七対子 + 混老頭 → 4翻")
    func chiitoiHonro() {
        let tiles = ["m1","m1","m9","m9","p1","p1","p9","p9","s1","s1","s9","s9","z1","z1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z1"))
        #expect(has(result, "七対子"))
        #expect(fan(result, "七対子") == 2)
        #expect(has(result, "混老頭"))
        #expect(fan(result, "混老頭") == 2)
    }
    
    @Test("七対子 + 混一色 → 5翻")
    func chiitoiHonitsu() {
        let tiles = ["m1","m1","m3","m3","m5","m5","m7","m7","m9","m9","z1","z1","z3","z3"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z3"))
        #expect(has(result, "七対子"))
        #expect(fan(result, "七対子") == 2)
        #expect(has(result, "混一色"))
        #expect(fan(result, "混一色") == 3)
    }
    
    @Test("七対子 + 清一色 → 8翻")
    func chiitoiChinitsu() {
        let tiles = ["m1","m1","m2","m2","m3","m3","m4","m4","m6","m6","m7","m7","m9","m9"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m9"))
        #expect(has(result, "七対子"))
        #expect(fan(result, "七対子") == 2)
        #expect(has(result, "清一色"))
        #expect(fan(result, "清一色") == 6)
    }

    // MARK: - 対対和

    @Test("対対和 → 2翻")
    func toitoi() {
        let tiles = ["m1","m1","m1","p2","p2","p2","s3","s3","s3","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z1"))
        #expect(has(result, "対対和"))
        #expect(fan(result, "対対和") == 2)
    }

    // MARK: - 三暗刻

    @Test("三暗刻（ツモ・副露1） → 2翻")
    func sanankou() {
        // bingpai暗刻×3 + z111ポン副露 + z22
        let tiles = ["m1","m1","m1","p2","p2","p2","s3","s3","s3","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: true, menqian: false, winTile: "z2"),
                                  fulouTiles: ["z111"])
        #expect(has(result, "三暗刻"))
        #expect(fan(result, "三暗刻") == 2)
    }

    // MARK: - 役牌

    @Test("場風（東） → 1翻")
    func yakuhaiBaFeng() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zhuangfeng: .東, menfeng: .南, winTile: "z2"))
        #expect(result.yaku.contains { $0.name.contains("場風") })
        #expect(result.yaku.first { $0.name.contains("場風") }?.fanshu == 1)
    }

    @Test("自風（南） → 1翻")
    func yakuhaiMenFeng() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z2","z2","z2","z3","z3"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zhuangfeng: .東, menfeng: .南, winTile: "z3"))
        #expect(result.yaku.contains { $0.name.contains("自風") })
        #expect(result.yaku.first { $0.name.contains("自風") }?.fanshu == 1)
    }

    @Test("連風牌（東場東家） → 2翻")
    func yakuhaiRenPu() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zhuangfeng: .東, menfeng: .東, winTile: "z2"))
        #expect(result.yaku.contains { $0.name.contains("連風牌") && $0.fanshu == 2 })
    }

    @Test("白 → 1翻")
    func yakuhaiBai() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z5","z5","z5","z3","z3"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z3"))
        #expect(has(result, "白"))
        #expect(fan(result, "白") == 1)
    }

    // MARK: - 三色同順

    @Test("三色同順（門前） → 2翻")
    func sanshokuDoujunMenqian() {
        // m123, p123, s123, m456, z11
        let tiles = ["m1","m2","m3","p1","p2","p3","s1","s2","s3","m4","m5","m6","z1","z1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z1"))
        #expect(has(result, "三色同順"))
        #expect(fan(result, "三色同順") == 2)
    }

    @Test("三色同順（副露） → 1翻")
    func sanshokuDoujunFulou() {
        // m123(副露), p123, s123, m456, z11
        let tiles = ["p1","p2","p3","s1","s2","s3","m4","m5","m6","z1","z1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "z1"),
                                  fulouTiles: ["m123"])
        #expect(has(result, "三色同順"))
        #expect(fan(result, "三色同順") == 1)
    }

    // MARK: - 三色同刻

    @Test("三色同刻 → 2翻")
    func sanshokuDoukou() {
        let tiles = ["m3","m3","m3","p3","p3","p3","s3","s3","s3","s4","s5","s6","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "s3"))
        #expect(has(result, "三色同刻"))
        #expect(fan(result, "三色同刻") == 2)
    }

    // MARK: - 一気通貫

    @Test("一気通貫（門前） → 2翻")
    func ittsuMenqian() {
        // m123, m456, m789, p123, z11
        let tiles = ["m1","m2","m3","m4","m5","m6","m7","m8","m9","p1","p2","p3","z1","z1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z1"))
        #expect(has(result, "一気通貫"))
        #expect(fan(result, "一気通貫") == 2)
    }

    @Test("一気通貫（副露） → 1翻")
    func ittsuFulou() {
        let tiles = ["m4","m5","m6","m7","m8","m9","p1","p2","p3","z1","z1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "z1"),
                                  fulouTiles: ["m123"])
        #expect(has(result, "一気通貫"))
        #expect(fan(result, "一気通貫") == 1)
    }

    // MARK: - 混全帯么九 / 純全帯么九

    @Test("混全帯么九 → 2翻")
    func chanta() {
        // m123, p789, s123, z111, z22
        let tiles = ["m1","m2","m3","p7","p8","p9","s1","s2","s3","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z2"))
        #expect(has(result, "混全帯么九"))
        #expect(fan(result, "混全帯么九") == 2)
    }
    
    @Test("混全帯么九(副露) → 1翻")
    func chantaFulou() {
        // m123, p789, s123, z111, z22
        let tiles = ["p7","p8","p9","s1","s2","s3","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "z2"),
                                  fulouTiles: ["m123"])
        #expect(has(result, "混全帯么九"))
        #expect(fan(result, "混全帯么九") == 1)
    }

    @Test("純全帯么九 → 3翻")
    func junchan() {
        // m123, p789, s123, m789, m11
        let tiles = ["m1","m2","m3","p7","p8","p9","s1","s2","s3","m7","m8","m9","m1","m1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m1"))
        #expect(has(result, "純全帯么九"))
        #expect(fan(result, "純全帯么九") == 3)
    }
    
    @Test("純全帯么九(副露) → 2翻")
    func junchanFulou() {
        // m123, p789, s123, m789, m11
        let tiles = ["p7","p8","p9","s1","s2","s3","m7","m8","m9","m1","m1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "m1"),
                                  fulouTiles: ["m123"])
        #expect(has(result, "純全帯么九"))
        #expect(fan(result, "純全帯么九") == 2)
    }

    // MARK: - 混一色 / 清一色

    @Test("混一色（門前） → 3翻")
    func honitsuMenqian() {
        // m123, m456, m789, z111, z22
        let tiles = ["m1","m2","m3","m4","m5","m6","m7","m8","m9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z2"))
        #expect(has(result, "混一色"))
        #expect(fan(result, "混一色") == 3)
    }

    @Test("混一色（副露） → 2翻")
    func honitsuFulou() {
        let tiles = ["m4","m5","m6","m7","m8","m9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "z2"),
                                  fulouTiles: ["m123"])
        #expect(has(result, "混一色"))
        #expect(fan(result, "混一色") == 2)
    }

    @Test("清一色（門前） → 6翻")
    func chinitsuMenqian() {
        // m123, m456, m789, m111, m22
        let tiles = ["m1","m2","m3","m4","m5","m6","m7","m8","m9","m1","m1","m1","m2","m2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m2"))
        #expect(has(result, "清一色"))
        #expect(fan(result, "清一色") == 6)
        #expect(has(result, "一気通貫"))
    }
    
    @Test("清一色 + 純全帯 + 二盃口 → 12翻")
    func chinitsuJunchan() {
        // m123, m456, m789, m111, m22
        let tiles = ["m1","m1","m1","m1","m2","m2","m3","m3","m7","m7","m8","m8","m9","m9"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m9"))
        #expect(has(result, "清一色"))
        #expect(fan(result, "清一色") == 6)
        #expect(has(result, "純全帯么九"))
        #expect(fan(result, "純全帯么九") == 3)
        #expect(has(result, "二盃口"))
        #expect(fan(result, "二盃口") == 3)
    }
    
    @Test("清一色（副露） → 5翻")
    func chinitsuFulou() {
        // m123, m456, m789, m111, m22
        let tiles = ["m4","m5","m6","m7","m8","m9","m1","m1","m1","m2","m2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "m2"),
                                  fulouTiles: ["m123"])
        #expect(has(result, "清一色"))
        #expect(fan(result, "清一色") == 5)
        #expect(has(result, "一気通貫"))
    }

    // MARK: - 混老頭 / 小三元 / 三槓子

    @Test("混老頭 → 2翻")
    func honroutou() {
        // m111, m999, p111, z111, z22
        let tiles = ["z4","z4"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: true, menqian: false, winTile: "z4"),
                                  fulouTiles: ["m111","m999","p111","z333"])
        #expect(has(result, "混老頭"))
        #expect(has(result, "対対和"))
    }

    @Test("小三元 → 2翻")
    func shousangen() {
        // m123, p456, z555(白), z666(發), z77(中)
        let tiles = ["m1","m2","m3","p4","p5","p6","z5","z5","z5","z6","z6","z6","z7","z7"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "z7"))
        #expect(has(result, "小三元"))
        #expect(fan(result, "小三元") == 2)
        #expect(has(result, "白"))
        #expect(has(result, "發"))
    }

    @Test("三槓子 → 2翻")
    func sankantsu() {
        // bingpai: m222(暗刻) + z11, fulouTiles: 3槓子
        let tiles = ["m2","m2","m2","z1","z1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "z1"),
                                  fulouTiles: ["m1111+","p2222+","s3333-"])
        #expect(has(result, "三槓子"))
        #expect(fan(result, "三槓子") == 2)
    }

    // MARK: - 状況役

    @Test("門前清自摸和 → 1翻")
    func menqianqingzimo() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "z2"))
        #expect(has(result, "門前清自摸和"))
    }

    @Test("門前清自摸和（副露あり） → なし")
    func menqianqingzimoFulou() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: true, menqian: false, winTile: "z1"),
                                  fulouTiles: ["z111"])
        #expect(!has(result, "門前清自摸和"))
    }

    @Test("立直 → 1翻")
    func lizhi() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(lizhi: true, winTile: "z2"))
        #expect(has(result, "立直"))
        #expect(fan(result, "立直") == 1)
    }

    @Test("ダブル立直 → 2翻（立直と複合しない）")
    func daburi() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(daburi: true, winTile: "z2"))
        #expect(has(result, "ダブル立直"))
        #expect(!has(result, "立直"))
        #expect(fan(result, "ダブル立直") == 2)
    }

    @Test("一発 → 1翻")
    func yifa() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(lizhi: true, yifa: true, winTile: "z2"))
        #expect(has(result, "一発"))
        #expect(fan(result, "一発") == 1)
    }

    @Test("嶺上開花 → 1翻")
    func lingshang() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, lingshang: true, winTile: "z2"))
        #expect(has(result, "嶺上開花"))
    }

    @Test("海底摸月 → 1翻")
    func haidi() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, haidi: true, winTile: "z2"))
        #expect(has(result, "海底摸月"))
    }

    @Test("河底撈魚 → 1翻")
    func hedi() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, hedi: true, winTile: "z2"))
        #expect(has(result, "河底撈魚"))
    }

    @Test("槍槓 → 1翻")
    func qianggang() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(qianggang: true, winTile: "z2"))
        #expect(has(result, "槍槓"))
    }

    // MARK: - 役満

    @Test("天和 → 役満(100)")
    func tianhu() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, tianhu: true, winTile: "z2"))
        #expect(has(result, "天和"))
        #expect(fan(result, "天和") == 100)
    }

    @Test("地和 → 役満(100)")
    func dihu() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, dihu: true, winTile: "z2"))
        #expect(has(result, "地和"))
        #expect(fan(result, "地和") == 100)
    }

    @Test("国士無双13面待ち → ダブル役満(200)")
    func kokushi13men() {
        let tiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7","m1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false,winTile: "m1"))
        #expect(has(result, "国士無双十三面待ち"))
        #expect(fan(result, "国士無双十三面待ち") == 200)
    }
    
    @Test("国士無双 → 役満(100)")
    func kokushi() {
        let tiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z6","z7"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false,winTile: "z7"))
        #expect(has(result, "国士無双"))
        #expect(fan(result, "国士無双") == 100)
    }

    @Test("四暗刻（単騎） → ダブル役満(200)")
    func suuankouDanqi() {
        // m111, p222, s333, z111, z22 ツモ → 全暗刻、z22単騎
        let tiles = ["m1","m1","m1","p2","p2","p2","s3","s3","s3","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, winTile: "z2"))
        #expect(has(result, "四暗刻単騎待ち"))
        #expect(fan(result, "四暗刻単騎待ち") == 200)
    }
    
    @Test("四暗刻 → 役満(100)")
    func suuankou() {
        // m111, p222, s333, z111, z22 ツモ → 全暗刻、z22単騎
        let tiles = ["m1","m1","m1","p2","p2","p2","s3","s3","s3","z1","z1","z2","z2","z2"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "z2"))
        #expect(has(result, "四暗刻"))
        #expect(fan(result, "四暗刻") == 100)
    }

    @Test("四槓子 → 役満(100)")
    func suukantsu() {
        // bingpai: z11 のみ（雀頭）、fulouTiles: 4槓子
        let tiles = ["z1","z1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "z1"),
                                  fulouTiles: ["m1111+","p2222+","s3333-","z4444-"])
        #expect(has(result, "四槓子"))
        #expect(fan(result, "四槓子") == 100)
    }

    // MARK: - ドラ

    @Test("役あり + ドラ → ドラが追加される")
    func doraAdded() {
        // 断么九 + 指示牌p1 → p2がドラ
        let tiles = ["m2","m3","m4","p2","p3","p4","s2","s3","s4","m6","m7","m8","m5","m5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m5"), baopai: ["p1"])
        #expect(has(result, "断么九"))
        #expect(has(result, "ドラ"))
    }

    @Test("役なし + ドラのみ → ドラは追加されない")
    func doraWithoutYaku() {
        let tiles = ["m2","m3","m4","p5","p6","p7","s2","s3","s4","m6","m6"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(menqian: false, winTile: "m6"),
                                  baopai: ["m1"],
                                  fulouTiles: ["m123"])
        #expect(!has(result, "ドラ"))
    }

    @Test("立直 + 裏ドラ → 裏ドラが追加される")
    func uradora() {
        // z1→z2がドラ、手牌にz2あり
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(lizhi: true, winTile: "z2"),
                                  libaopai: ["z1"])
        #expect(has(result, "立直"))
        #expect(has(result, "裏ドラ"))
    }

    @Test("立直なし → 裏ドラは追加されない")
    func uradoraWithoutLizhi() {
        let tiles = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(lizhi: false, winTile: "z2"),
                                  libaopai: ["z1"])
        #expect(!has(result, "裏ドラ"))
    }
}

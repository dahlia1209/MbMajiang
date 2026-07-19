//
//  HuleFuCalculationTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("getYaku: 符計算")
struct HuleFuCalculationTests {

    private func ctx(
        zhuangfeng: Feng = .東,
        menfeng: Feng = .南,
        zimo: Bool = false,
        menqian: Bool = true,
        lizhi: Bool = false,
        winTile: String = "m1"
    ) -> HuleContext {
        HuleContext(
            zhuangfeng: zhuangfeng, menfeng: menfeng,
            zimo: zimo, menqian: menqian,
            lizhi: lizhi, daburi: false, yifa: false,
            qianggang: false, lingshang: false,
            haidi: false, hedi: false,
            tianhu: false, dihu: false,
            winTile: winTile
        )
    }

    // MARK: - 平和特例（20符・30符固定）

    @Test("平和ロン → 30符固定（副底20+門前ロン10）")
    func pinghuRon() {
        let tiles = ["m1","m2","m3","m5","m6","m7","p4","p5","p6","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, winTile: "m7"))
        #expect(result.fu == 30)
    }

    @Test("平和ツモ → 20符固定（ツモ符+2が付かない）")
    func pinghuTsumo() {
        let tiles = ["m1","m2","m3","m5","m6","m7","p4","p5","p6","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "m7"))
        #expect(result.fu == 20)
    }

    // MARK: - 待ち符

    @Test("カンチャン待ちロン → 20+2(カンチャン)+10(門前ロン)=32→40符")
    func kanchanRon() {
        let tiles = ["m1","m2","m3","m4","m5","m6","p4","p5","p6","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, winTile: "m5"))
        #expect(result.fu == 40)
    }

    @Test("ペンチャン待ちロン → 20+2(ペンチャン)+10(門前ロン)=32→40符")
    func penchanRon() {
        // m123（1-2から3を待つペンチャン）+ m567 + p789 + s456 + 雀頭s1
        let tiles = ["m1","m2","m3","m5","m6","m7","p7","p8","p9","s4","s5","s6","s1","s1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, winTile: "m3"))
        #expect(result.fu == 40)
    }

    @Test("単騎待ちロン → 20+2(単騎)+10(門前ロン)=32→40符")
    func tankiRon() {
        let tiles = ["m1","m2","m3","m5","m6","m7","p4","p5","p6","s7","s8","s9","s1","s1"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, winTile: "s1"))
        #expect(result.fu == 40)
    }

    // MARK: - 雀頭符

    @Test("役牌雀頭（三元牌）ロン → 20+2(役牌雀頭)+10(門前ロン)=32→40符")
    func yakuhaiPairRon() {
        let tiles = ["m1","m2","m3","m5","m6","m7","p4","p5","p6","s7","s8","s9","z5","z5"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(winTile: "m7"))
        #expect(result.fu == 40)
    }

    @Test("連風牌雀頭（場風=自風=東）ロン → 20+4(連風符)+10(門前ロン)=34→40符")
    func renpuPairRon() {
        let tiles = ["m1","m2","m3","m5","m6","m7","p4","p5","p6","s7","s8","s9","z1","z1"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zhuangfeng: .東, menfeng: .東, winTile: "m7"))
        #expect(result.fu == 40)
    }

    // MARK: - 刻子符（暗刻）

    @Test("暗刻（中張牌）ツモ → 20+4(暗刻中張)+2(ツモ)=26→30符")
    func ankouSimpleTsumo() {
        let tiles = ["p5","p5","p5","m1","m2","m3","m5","m6","m7","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "m7"))
        #expect(result.fu == 30)
    }

    @Test("暗刻（字牌）ツモ → 20+8(暗刻么九)+2(ツモ)=30符（ちょうど）")
    func ankouHonorTsumo() {
        let tiles = ["z6","z6","z6","m1","m2","m3","m5","m6","m7","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "m7"))
        #expect(result.fu == 30)
    }

    // MARK: - 刻子符（明刻）

    @Test("明刻（中張牌・ポン）ロン → 20+2(明刻中張)=22→30符（副露のため門前ロン加算なし）")
    func minkoSimpleRon() {
        let tiles = ["m1","m2","m3","m5","m6","m7","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: false, menqian: false, winTile: "m7"),
                                  fulouTiles: ["p666"])
        #expect(result.fu == 30)
    }

    // MARK: - 槓子符

    @Test("暗槓（中張牌）ツモ → 20+16(暗槓中張)+2(ツモ)=38→40符")
    func ankanSimpleTsumo() {
        let tiles = ["m1","m2","m3","m5","m6","m7","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: true, menqian: true, winTile: "m7"),
                                  fulouTiles: ["p5555+"])
        #expect(result.fu == 40)
    }

    @Test("明槓（字牌）ロン → 20+16(明槓么九)=36→40符")
    func minkanHonorRon() {
        let tiles = ["m1","m2","m3","m5","m6","m7","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: false, menqian: false, winTile: "m7"),
                                  fulouTiles: ["z6666-"])
        #expect(result.fu == 40)
    }

    // MARK: - 副露で符なしの下限

    @Test("副露あり・符加算なしのロン → 最低30符に補正される")
    func openHandRonMinimumFu() {
        let tiles = ["m1","m2","m3","m5","m6","m7","s7","s8","s9","m8","m8"]
        let result = Hule.getYaku(tiles: tiles,
                                  context: ctx(zimo: false, menqian: false, winTile: "m7"),
                                  fulouTiles: ["p456"])
        #expect(result.fu == 30)
    }

    // MARK: - 七対子固定符

    @Test("七対子 → ツモ・ロンによらず25符固定")
    func chiitoitsuFixedFu() {
        let tiles = ["m1","m1","m5","m5","m3","m3","p1","p1","p5","p5","p3","p3","z1","z1"]
        let ronResult  = Hule.getYaku(tiles: tiles, context: ctx(zimo: false, winTile: "z1"))
        let tsumoResult = Hule.getYaku(tiles: tiles, context: ctx(zimo: true, winTile: "z1"))
        #expect(ronResult.fu == 25)
        #expect(tsumoResult.fu == 25)
    }
}

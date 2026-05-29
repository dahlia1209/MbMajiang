//
//  ComputeDefenTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

// MARK: - テスト用ヘルパー

private func yaku(_ fan: Int) -> [Yaku] { [Yaku(name: "test", fanshu: fan)] }
private func yakuman(_ count: Int = 1) -> [Yaku] { (0..<count).map { Yaku(name: "yk\($0)", fanshu: Yaku.yakuman) } }
private func doubleYakumanYaku() -> [Yaku] { [Yaku(name: "dyk", fanshu: Yaku.doubleYakuman)] }

/// fenpei の合計 == lizhibang * 1000（供託は中央から winner へ、零和でない）
private func fenpeiSum(_ r: DefenResult) -> Int { r.fenpei.reduce(0, +) }

// MARK: - 役なし

@Suite("computeDefen: 役なし")
struct ComputeDefenNoYakuTests {

    @Test("役が空なら defen=0・fenpei 全ゼロ")
    func noYakuReturnsZero() {
        let r = Hule.computeDefen(fu: 30, yaku: [], zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(r.defen == 0)
        #expect(r.fenpei == [0, 0, 0, 0])
        #expect(r.effectiveFan == 0)
    }
}

// MARK: - 基本4パターン (30fu 4han)

@Suite("computeDefen: 基本4パターン (30符4翻)")
struct ComputeDefenBasicTests {

    // ① 親ロン (winnerIdx=dealerIdx=0, loserIdx=2)
    @Test("親ロン: 放銃者が oyaRon を払う")
    func dealerRon() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(r.defen == 11600)
        #expect(r.fenpei[0] == 11600)   // winner
        #expect(r.fenpei[2] == -11600)  // loser
        #expect(r.fenpei[1] == 0)
        #expect(r.fenpei[3] == 0)
    }

    // ② 親ツモ (winnerIdx=dealerIdx=0)
    @Test("親ツモ: 子3人が均等払い")
    func dealerTsumo() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(r.defen == 11700)        // 3900 * 3
        #expect(r.fenpei[0] == 11700)
        #expect(r.fenpei[1] == -3900)
        #expect(r.fenpei[2] == -3900)
        #expect(r.fenpei[3] == -3900)
        #expect(fenpeiSum(r) == 0)
    }

    // ③ 子ロン (winnerIdx=1, loserIdx=2, dealerIdx=0)
    @Test("子ロン: 放銃者が koRon を払う")
    func nonDealerRon() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(r.defen == 7700)
        #expect(r.fenpei[1] == 7700)
        #expect(r.fenpei[2] == -7700)
        #expect(r.fenpei[0] == 0)
        #expect(r.fenpei[3] == 0)
    }

    // ④ 子ツモ (winnerIdx=1, dealerIdx=0)
    @Test("子ツモ: 親が koTsumoOya、子が koTsumoKo を払う")
    func nonDealerTsumo() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: true, winnerIdx: 1, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(r.defen == 7900)         // 3900 + 2000 + 2000
        #expect(r.fenpei[1] == 7900)
        #expect(r.fenpei[0] == -3900)    // 親
        #expect(r.fenpei[2] == -2000)
        #expect(r.fenpei[3] == -2000)
        #expect(fenpeiSum(r) == 0)
    }
}

// MARK: - 本場・供託

@Suite("computeDefen: 本場・供託")
struct ComputeDefenHonbaLizhiTests {

    // 本場: ロンは放銃者が 300点/本場 を追加払い
    @Test("子ロン honba=2: 放銃者が +600 払い、winner が +600 受取")
    func ronHonba() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 2, lizhibang: 0)
        #expect(r.defen == 8300)          // 7700 + 600
        #expect(r.fenpei[1] == 8300)
        #expect(r.fenpei[2] == -8300)
        #expect(fenpeiSum(r) == 0)
    }

    // 本場: ツモは全員が 100点/本場 を追加払い
    @Test("親ツモ honba=3: 子3人が各+300 払い、winner が +900 受取")
    func tsumoHonba() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 3, lizhibang: 0)
        #expect(r.defen == 12600)         // 11700 + 900
        #expect(r.fenpei[0] == 12600)
        #expect(r.fenpei[1] == -4200)     // 3900 + 300
        #expect(r.fenpei[2] == -4200)
        #expect(r.fenpei[3] == -4200)
        #expect(fenpeiSum(r) == 0)
    }

    // 供託: winner のみ lizhibang * 1000 を受取（放銃者は関係なし）
    @Test("子ロン lizhibang=2: winner +2000、loser は通常払いのみ")
    func ronLizhibang() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 2)
        #expect(r.defen == 9700)          // 7700 + 2000
        #expect(r.fenpei[1] == 9700)
        #expect(r.fenpei[2] == -7700)     // 放銃者は供託を払わない
        #expect(fenpeiSum(r) == 2000)     // 供託分だけ零和でない
    }

    @Test("子ツモ lizhibang=1: winner +1000、払う側は変わらない")
    func tsumoLizhibang() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: true, winnerIdx: 1, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 1)
        #expect(r.defen == 8900)          // 7900 + 1000
        #expect(r.fenpei[1] == 8900)
        #expect(r.fenpei[0] == -3900)     // 親は供託を払わない
        #expect(r.fenpei[2] == -2000)
        #expect(r.fenpei[3] == -2000)
        #expect(fenpeiSum(r) == 1000)
    }

    @Test("本場+供託の複合: 子ロン honba=1 lizhibang=1")
    func ronHonbaAndLizhibang() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 1, lizhibang: 1)
        #expect(r.defen == 9000)          // 7700 + 300 + 1000
        #expect(r.fenpei[1] == 9000)
        #expect(r.fenpei[2] == -8000)     // 7700 + 300
        #expect(fenpeiSum(r) == 1000)
    }
}

// MARK: - 点数テーブル (満貫〜役満)

@Suite("computeDefen: 満貫〜役満 点数テーブル")
struct ComputeDefenTableTests {

    // 満貫 (5翻)
    @Test("満貫 子ロン=8000, 子ツモ親=4000子=2000, 親ロン=12000, 親ツモ=4000")
    func mangan() {
        let ronKo = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronKo.defen == 8000)

        let tsumoKo = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: true, winnerIdx: 1, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(tsumoKo.defen == 8000)    // 4000 + 2000 + 2000
        #expect(tsumoKo.fenpei[0] == -4000)
        #expect(tsumoKo.fenpei[2] == -2000)

        let ronOya = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronOya.defen == 12000)

        let tsumoOya = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(tsumoOya.defen == 12000)  // 4000 * 3
        #expect(tsumoOya.fenpei[1] == -4000)
    }

    // 跳満 (6-7翻)
    @Test("跳満 子ロン=12000, 親ロン=18000, 親ツモ子払い=6000")
    func haneman() {
        let ronKo = Hule.computeDefen(fu: 30, yaku: yaku(6), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronKo.defen == 12000)

        let ronOya = Hule.computeDefen(fu: 30, yaku: yaku(6), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronOya.defen == 18000)

        let tsumoOya = Hule.computeDefen(fu: 30, yaku: yaku(7), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(tsumoOya.defen == 18000)  // 6000 * 3
        #expect(tsumoOya.fenpei[1] == -6000)
    }

    // 倍満 (8-10翻)
    @Test("倍満 子ロン=16000, 親ロン=24000, 子ツモ親=8000子=4000")
    func baiman() {
        let ronKo = Hule.computeDefen(fu: 30, yaku: yaku(8), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronKo.defen == 16000)

        let ronOya = Hule.computeDefen(fu: 30, yaku: yaku(10), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronOya.defen == 24000)

        let tsumoKo = Hule.computeDefen(fu: 30, yaku: yaku(9), zimo: true, winnerIdx: 1, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(tsumoKo.defen == 16000)   // 8000 + 4000 + 4000
        #expect(tsumoKo.fenpei[0] == -8000)
        #expect(tsumoKo.fenpei[2] == -4000)
    }

    // 三倍満 (11-12翻)
    @Test("三倍満 子ロン=24000, 親ロン=36000, 親ツモ子払い=12000")
    func sanbaiman() {
        let ronKo = Hule.computeDefen(fu: 30, yaku: yaku(11), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronKo.defen == 24000)

        let ronOya = Hule.computeDefen(fu: 30, yaku: yaku(12), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronOya.defen == 36000)

        let tsumoOya = Hule.computeDefen(fu: 30, yaku: yaku(11), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(tsumoOya.defen == 36000)  // 12000 * 3
    }

    // 役満 (13翻以上・通常)
    @Test("役満 子ロン=32000, 親ロン=48000, 親ツモ子払い=16000")
    func yakumanPayments() {
        let ronKo = Hule.computeDefen(fu: 30, yaku: yakuman(), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronKo.defen == 32000)
        #expect(ronKo.effectiveFan == Yaku.yakuman)

        let ronOya = Hule.computeDefen(fu: 30, yaku: yakuman(), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronOya.defen == 48000)

        let tsumoOya = Hule.computeDefen(fu: 30, yaku: yakuman(), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(tsumoOya.defen == 48000)  // 16000 * 3
        #expect(tsumoOya.fenpei[1] == -16000)
    }

    // ダブル役満 (200翻)
    @Test("ダブル役満 子ロン=64000, 親ロン=96000")
    func doubleYakuman() {
        let ronKo = Hule.computeDefen(fu: 30, yaku: doubleYakumanYaku(), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronKo.defen == 64000)
        #expect(ronKo.effectiveFan == Yaku.doubleYakuman)

        let ronOya = Hule.computeDefen(fu: 30, yaku: doubleYakumanYaku(), zimo: false, winnerIdx: 0, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(ronOya.defen == 96000)
    }
}

// MARK: - ルール設定の影響

@Suite("computeDefen: ルール設定")
struct ComputeDefenRuleTests {

    // 切り上げ満貫: 30fu 4han (base=7680) → 7700 → kiriageMangan=true → 8000
    @Test("切り上げ満貫あり: 30符4翻が満貫点数になる")
    func kiriageMangan() {
        let normal = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, kiriageMangan: false)
        #expect(normal.defen == 7700)

        let kiriage = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, kiriageMangan: true)
        #expect(kiriage.defen == 8000)
    }

    @Test("切り上げ満貫なし: 30符4翻は 7700 のまま")
    func noKiriage() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(4), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, kiriageMangan: false)
        #expect(r.defen == 7700)
    }

    // 数え役満なし: 13翻 → 12翻（三倍満）扱い
    @Test("数え役満なし: 13翻が三倍満点数になる")
    func kazoeYakumanOff() {
        let withKazoe = Hule.computeDefen(fu: 30, yaku: yaku(13), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, kazoeYakumanAri: true)
        #expect(withKazoe.defen == 32000)  // 役満

        let noKazoe = Hule.computeDefen(fu: 30, yaku: yaku(13), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, kazoeYakumanAri: false)
        #expect(noKazoe.defen == 24000)    // 三倍満
        #expect(noKazoe.effectiveFan == 12)
    }

    // ダブル役満なし: 200翻 → 100翻（役満）扱い
    @Test("ダブル役満なし: ダブル役満が役満点数になる")
    func doubleYakumanOff() {
        let withDouble = Hule.computeDefen(fu: 30, yaku: doubleYakumanYaku(), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, doubleYakumanAri: true)
        #expect(withDouble.defen == 64000)

        let noDouble = Hule.computeDefen(fu: 30, yaku: doubleYakumanYaku(), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, doubleYakumanAri: false)
        #expect(noDouble.defen == 32000)   // 役満1つ分
        #expect(noDouble.effectiveFan == Yaku.yakuman)
    }

    // 役満複合なし: 役満×2 → 役満1つ分
    @Test("役満複合なし: 複数役満の合算を禁止")
    func yakumanFukugouOff() {
        let twoYakuman = yakuman(2)

        let withFukugou = Hule.computeDefen(fu: 30, yaku: twoYakuman, zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, yakumanFukugouAri: true)
        #expect(withFukugou.defen == 64000)  // ダブル役満

        let noFukugou = Hule.computeDefen(fu: 30, yaku: twoYakuman, zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0, yakumanFukugouAri: false)
        #expect(noFukugou.defen == 32000)    // 役満1つ分
        #expect(noFukugou.effectiveFan == Yaku.yakuman)
    }
}

// MARK: - fenpei 零和不変量

@Suite("computeDefen: fenpei 不変量")
struct ComputeDefenInvariantTests {

    @Test("本場あり・供託なし: fenpei の合計は 0")
    func honbaIsZeroSum() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: true, winnerIdx: 0, loserIdx: nil, dealerIdx: 0, honba: 2, lizhibang: 0)
        #expect(fenpeiSum(r) == 0)
    }

    @Test("供託あり: fenpei の合計 == lizhibang * 1000")
    func lizhiSumEqualsChuatou() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 3)
        #expect(fenpeiSum(r) == 3000)
    }

    @Test("本場+供託: fenpei の合計 == lizhibang * 1000")
    func honbaAndLizhiSum() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: true, winnerIdx: 1, loserIdx: nil, dealerIdx: 0, honba: 4, lizhibang: 2)
        #expect(fenpeiSum(r) == 2000)
    }

    @Test("非関与プレイヤーは fenpei == 0（子ロン）")
    func uninvolvedPlayersZeroRon() {
        let r = Hule.computeDefen(fu: 30, yaku: yaku(5), zimo: false, winnerIdx: 1, loserIdx: 2, dealerIdx: 0, honba: 0, lizhibang: 0)
        #expect(r.fenpei[0] == 0)
        #expect(r.fenpei[3] == 0)
    }
}

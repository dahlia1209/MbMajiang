//
//  KuichikaeTests.swift
//  MbMajiangTests
//
//  喰い替え制限（Player.kuichikaeLabels）のテスト。
//  現物喰い替え: 鳴いた牌そのものを打つこと。スジ喰い替え: チーの際、鳴いた牌と数字的に
//  等価なスジ（例: 2-3-4で4を鳴いたら1を打つこと）。

import Testing
@testable import MbMajiang

@Suite("Player.kuichikaeLabels: 喰い替え制限")
struct KuichikaeTests {

    private func rotatedFulou(_ labels: [String], rotatedIndex: Int) -> [Pai] {
        labels.enumerated().map { i, label in
            var pai = Pai(label)
            if i == rotatedIndex { pai.rotated = true }
            return pai
        }
    }

    private func makePlayer() -> Player { Player(id: 0) }

    // MARK: - 現物喰い替え

    @Test(".none設定でポン → 現物（鳴いた牌そのもの）は禁止")
    func genmotsuForbiddenWithNoneOnPeng() {
        let player = makePlayer()
        let fulou = rotatedFulou(["m5", "m5", "m5"], rotatedIndex: 2)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: false, level: .none)
        #expect(forbidden.contains("m5"))
    }

    @Test(".suji設定でも現物は禁止（スジのみ許可されるだけ）")
    func genmotsuStillForbiddenWithSuji() {
        let player = makePlayer()
        let fulou = rotatedFulou(["m2", "m3", "m4"], rotatedIndex: 2) // m4を鳴いた
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: true, level: .suji)
        #expect(forbidden.contains("m4"))
    }

    @Test(".genmotsu設定なら現物も含めて制限なし")
    func genmotsuAllowedAtMostPermissiveLevel() {
        let player = makePlayer()
        let fulou = rotatedFulou(["m5", "m5", "m5"], rotatedIndex: 2)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: false, level: .genmotsu)
        #expect(forbidden.isEmpty)
    }

    // MARK: - スジ喰い替え（チーのみ）

    @Test(".none設定でチー、安い方（安=lo）の牌を鳴いた → 高い方の外側（hi+1）も禁止")
    func sujiForbiddenWhenCalledLowEnd() {
        // m2-m3-m4 のチーで m2（lo）を鳴いた → m5（hi+1）も打てない
        let player = makePlayer()
        let fulou = rotatedFulou(["m2", "m3", "m4"], rotatedIndex: 0)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: true, level: .none)
        #expect(forbidden.contains("m2")) // 現物
        #expect(forbidden.contains("m5")) // スジ
    }

    @Test(".none設定でチー、高い方（hi）の牌を鳴いた → 安い方の外側（lo-1）も禁止")
    func sujiForbiddenWhenCalledHighEnd() {
        // m2-m3-m4 のチーで m4（hi）を鳴いた → m1（lo-1）も打てない
        let player = makePlayer()
        let fulou = rotatedFulou(["m2", "m3", "m4"], rotatedIndex: 2)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: true, level: .none)
        #expect(forbidden.contains("m4")) // 現物
        #expect(forbidden.contains("m1")) // スジ
    }

    @Test(".suji設定でチー → スジは許可され、現物のみ禁止")
    func sujiAllowedAtSujiLevel() {
        let player = makePlayer()
        let fulou = rotatedFulou(["m2", "m3", "m4"], rotatedIndex: 0)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: true, level: .suji)
        #expect(forbidden == ["m2"])
    }

    @Test("中央の牌（m3）を鳴いた場合はスジ制限が発生しない")
    func middleTileCallHasNoSujiRestriction() {
        let player = makePlayer()
        let fulou = rotatedFulou(["m2", "m3", "m4"], rotatedIndex: 1)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: true, level: .none)
        #expect(forbidden == ["m3"])
    }

    @Test("ポンにはスジ制限が適用されない（現物のみ）")
    func pengHasNoSujiRestrictionEvenAtNoneLevel() {
        let player = makePlayer()
        let fulou = rotatedFulou(["m5", "m5", "m5"], rotatedIndex: 0)
        let forbidden = player.kuichikaeLabels(fulou: fulou, isChi: false, level: .none)
        #expect(forbidden == ["m5"])
    }
}

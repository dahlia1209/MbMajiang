//
//  ResolveDojiHuleTests.swift
//  MbMajiangTests
//
//  同時ロン（ダブロン・トリプルロン・槍槓での同時ロン）の勝者選定ロジックのテスト。
//  通常のロンと槍槓ロンの両方がこのロジックを共有しているため、
//  槍槓側だけ三家和の分岐が抜けていたバグの再発防止も兼ねる。

import Testing
@testable import MbMajiang

@Suite("Game.resolveDojiHule: 同時ロンの勝者選定")
struct ResolveDojiHuleTests {

    @Test("頭跳ね: 放銃者(discarder=0)から見て巡り順が近い方（下家=1,対面=2,上家=3の順）を優先")
    func atamahanePicksCloserInTurnOrder() {
        // hulers=[2,3] のうち、discarder=0から見て巡り順が近いのは2（対面）
        let result = Game.resolveDojiHule(hulerIds: [2, 3], discarder: 0, dojiHuleMax: .atamahane)
        #expect(result == .winners([2]))
    }

    @Test("3人ロン + ダブロン設定(2人まで) → 三家和で流局（バグ修正の中心ケース）")
    func threeHulersWithDoubleRonTriggersSanchahou() {
        let result = Game.resolveDojiHule(hulerIds: [1, 2, 3], discarder: 0, dojiHuleMax: .doubleRon)
        #expect(result == .sanchahou)
    }

    @Test("トリプルロン設定なら3人とも勝者になる")
    func tripleRonAllowsThreeWinners() {
        let result = Game.resolveDojiHule(hulerIds: [1, 2, 3], discarder: 0, dojiHuleMax: .tripleRon)
        #expect(result == .winners([1, 2, 3]))
    }

    @Test("2人ロンはダブロン設定なら三家和にならず両方勝者")
    func twoHulersNeverTriggersSanchahou() {
        let result = Game.resolveDojiHule(hulerIds: [1, 3], discarder: 0, dojiHuleMax: .doubleRon)
        #expect(result == .winners([1, 3]))
    }

    @Test("3人ロン + 頭跳ね設定 → 三家和にはならず1人勝者（atamahaneはそのまま1人に絞る）")
    func threeHulersWithAtamahaneJustPicksOne() {
        let result = Game.resolveDojiHule(hulerIds: [1, 2, 3], discarder: 0, dojiHuleMax: .atamahane)
        if case .winners(let ids) = result {
            #expect(ids.count == 1)
        } else {
            Issue.record("atamahane設定で3人ロンは三家和にならず1人勝者になるべき")
        }
    }

}

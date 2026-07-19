//
//  DaburiTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("Game.computeIsDaburi: ダブル立直判定")
struct ComputeIsDaburiTests {

    private func makePlayers(fulouCounts: [Int]) -> [Player] {
        fulouCounts.enumerated().map { i, count in
            let player = Player(id: i)
            if count > 0 {
                player.shoupai.fulou = [[Pai("m1")]]
            }
            return player
        }
    }

    @Test("最初の打牌 + 全員副露なし → true")
    func firstDiscardNoFulou() {
        let players = makePlayers(fulouCounts: [0, 0, 0, 0])
        #expect(Game.computeIsDaburi(isFirstDiscard: true, players: players) == true)
    }

    @Test("2回目以降の打牌 → false")
    func notFirstDiscard() {
        let players = makePlayers(fulouCounts: [0, 0, 0, 0])
        #expect(Game.computeIsDaburi(isFirstDiscard: false, players: players) == false)
    }

    @Test("他家が副露している → false")
    func otherPlayerHasFulou() {
        let players = makePlayers(fulouCounts: [0, 1, 0, 0])
        #expect(Game.computeIsDaburi(isFirstDiscard: true, players: players) == false)
    }

    @Test("暗槓（fulouに格納される）が入っている → false")
    func ankanCountsAsFulou() {
        let players = makePlayers(fulouCounts: [0, 0, 0, 1])
        #expect(Game.computeIsDaburi(isFirstDiscard: true, players: players) == false)
    }
}

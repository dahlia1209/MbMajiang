//
//  GangFullTests.swift
//  MbMajiangTests
//
//  合計カン数が4に達した場合、5回目以降の暗槓・加槓・明槓を不可にする判定のテスト。

import Testing
@testable import MbMajiang

@Suite("Game.isGangFull: カン回数上限")
struct GangFullTests {

    private func makeGame(gangCounts: [Int]) -> Game {
        let game = Game()
        game.players = gangCounts.enumerated().map { i, count in
            let player = Player(id: i)
            player.shoupai.fulou = (0..<count).map { _ in
                [Pai("m1"), Pai("m1"), Pai("m1"), Pai("m1")]
            }
            return player
        }
        return game
    }

    @Test("誰もカンしていない → false")
    func noGang() {
        let game = makeGame(gangCounts: [0, 0, 0, 0])
        #expect(game.isGangFull == false)
    }

    @Test("合計3回（4未満） → false")
    func threeGangs() {
        let game = makeGame(gangCounts: [1, 1, 1, 0])
        #expect(game.isGangFull == false)
    }

    @Test("1人が合計4回カン → true")
    func fourGangsBySinglePlayer() {
        let game = makeGame(gangCounts: [4, 0, 0, 0])
        #expect(game.isGangFull == true)
    }

    @Test("複数人で合計4回カン → true")
    func fourGangsAcrossPlayers() {
        let game = makeGame(gangCounts: [2, 1, 1, 0])
        #expect(game.isGangFull == true)
    }
}

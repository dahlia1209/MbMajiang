//
//  YifaTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("一発キャンセル")
struct YifaTests {

    private func makePlayer(id: Int = 0) -> Player {
        Player(id: id)
    }

    // MARK: - Player 単体

    @Test("リーチ宣言後は isYifa = true")
    func yifaSetAfterLizhi() {
        let player = makePlayer()
        player.commitLizhi()
        #expect(player.status.isYifa == true)
    }

    @Test("cancelYifa() で isYifa = false になる")
    func yifaClearedByCancelYifa() {
        let player = makePlayer()
        player.commitLizhi()
        player.cancelYifa()
        #expect(player.status.isYifa == false)
    }

    @Test("リーチしていないプレイヤーは cancelYifa() しても影響なし")
    func cancelYifaOnNonRiichiPlayer() {
        let player = makePlayer()
        #expect(player.status.isYifa == false)
        player.cancelYifa()
        #expect(player.status.isYifa == false)
    }

    // MARK: - 複数プレイヤーへの一括キャンセル

    @Test("副露時に全プレイヤーの isYifa が消える")
    func yifaCancelledForAllPlayersOnFulou() {
        let players = (0..<4).map { makePlayer(id: $0) }
        // プレイヤー0・2 がリーチ中
        players[0].commitLizhi()
        players[2].commitLizhi()
        #expect(players[0].status.isYifa == true)
        #expect(players[2].status.isYifa == true)

        // 副露発生 → 全員に cancelYifa（Game.peng/chi/gang の動作を再現）
        players.indices.forEach { players[$0].cancelYifa() }

        #expect(players[0].status.isYifa == false)
        #expect(players[1].status.isYifa == false)
        #expect(players[2].status.isYifa == false)
        #expect(players[3].status.isYifa == false)
    }

    @Test("リーチしていないプレイヤーは副露後も isYifa = false のまま")
    func nonRiichiPlayersUnaffectedByFulou() {
        let players = (0..<4).map { makePlayer(id: $0) }
        // 誰もリーチしていない
        players.indices.forEach { players[$0].cancelYifa() }
        #expect(players.allSatisfy { !$0.status.isYifa })
    }

    @Test("1人だけリーチ中に副露 → その1人の isYifa が消える")
    func singleRiichiCancelledByFulou() {
        let players = (0..<4).map { makePlayer(id: $0) }
        players[1].commitLizhi()

        players.indices.forEach { players[$0].cancelYifa() }

        #expect(players[1].status.isYifa == false)
    }
}

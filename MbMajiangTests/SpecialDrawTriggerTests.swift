//
//  SpecialDrawTriggerTests.swift
//  MbMajiangTests
//
//  特殊な流局（四風連打・四家立直・四槓散了）の発生条件のテスト。

import Testing
@testable import MbMajiang

@Suite("Game.isSuufon: 四風連打")
struct SuufonTests {

    private func makeGame(firstDapai: [String?], fulouCounts: [Int] = [0, 0, 0, 0], tochukuryokuAri: Bool = true) -> Game {
        let settings = GameSettings()
        settings.tochukuryokuAri = tochukuryokuAri
        let game = Game(settings: settings)
        game.players = firstDapai.enumerated().map { i, dapai in
            let player = Player(id: i)
            player.status.firstDapai = dapai
            if fulouCounts[i] > 0 {
                player.shoupai.fulou = [[Pai("m1"), Pai("m2"), Pai("m3")]]
            }
            return player
        }
        return game
    }

    @Test("全員が同じ風牌を第一打 → 四風連打")
    func allSameWind() {
        let game = makeGame(firstDapai: ["z1", "z1", "z1", "z1"])
        #expect(game.isSuufon() == true)
    }

    @Test("1人だけ異なる風牌 → 不成立")
    func differentWind() {
        let game = makeGame(firstDapai: ["z1", "z1", "z2", "z1"])
        #expect(game.isSuufon() == false)
    }

    @Test("風牌ではない数牌 → 不成立")
    func notWindTile() {
        let game = makeGame(firstDapai: ["m1", "m1", "m1", "m1"])
        #expect(game.isSuufon() == false)
    }

    @Test("誰かが副露済み → 不成立")
    func fulouBreaksSuufon() {
        let game = makeGame(firstDapai: ["z1", "z1", "z1", "z1"], fulouCounts: [0, 1, 0, 0])
        #expect(game.isSuufon() == false)
    }

    @Test("まだ全員が第一打を終えていない → 不成立")
    func notAllDiscardedYet() {
        let game = makeGame(firstDapai: ["z1", "z1", "z1", nil])
        #expect(game.isSuufon() == false)
    }

    @Test("途中流局なしの設定 → 条件を満たしていても不成立")
    func disabledBySetting() {
        let game = makeGame(firstDapai: ["z1", "z1", "z1", "z1"], tochukuryokuAri: false)
        #expect(game.isSuufon() == false)
    }
}

@Suite("Game.isSuuchaRiichi: 四家立直")
struct SuuchaRiichiTests {

    private func makeGame(lizhiFlags: [Bool], tochukuryokuAri: Bool = true) -> Game {
        let settings = GameSettings()
        settings.tochukuryokuAri = tochukuryokuAri
        let game = Game(settings: settings)
        game.players = lizhiFlags.enumerated().map { i, isLizhi in
            let player = Player(id: i)
            player.status.isLizhi = isLizhi
            return player
        }
        return game
    }

    @Test("全員リーチ → 四家立直")
    func allRiichi() {
        let game = makeGame(lizhiFlags: [true, true, true, true])
        #expect(game.isSuuchaRiichi() == true)
    }

    @Test("1人でもリーチしていない → 不成立")
    func oneNotRiichi() {
        let game = makeGame(lizhiFlags: [true, true, false, true])
        #expect(game.isSuuchaRiichi() == false)
    }

    @Test("途中流局なしの設定 → 全員リーチでも不成立")
    func disabledBySetting() {
        let game = makeGame(lizhiFlags: [true, true, true, true], tochukuryokuAri: false)
        #expect(game.isSuuchaRiichi() == false)
    }
}

@Suite("Game.isSuukanSanyou: 四槓散了")
struct SuukanSanyouTests {

    private func makeGame(gangCounts: [Int], tochukuryokuAri: Bool = true) -> Game {
        let settings = GameSettings()
        settings.tochukuryokuAri = tochukuryokuAri
        let game = Game(settings: settings)
        game.players = gangCounts.enumerated().map { i, count in
            let player = Player(id: i)
            player.shoupai.fulou = (0..<count).map { _ in
                [Pai("m1"), Pai("m1"), Pai("m1"), Pai("m1")]
            }
            return player
        }
        return game
    }

    @Test("複数人で合計4回カン → 四槓散了")
    func fourGangsAcrossPlayers() {
        let game = makeGame(gangCounts: [2, 1, 1, 0])
        #expect(game.isSuukanSanyou() == true)
    }

    @Test("1人で合計4回カン → 続行（四槓散了にならない）")
    func fourGangsBySinglePlayer() {
        let game = makeGame(gangCounts: [4, 0, 0, 0])
        #expect(game.isSuukanSanyou() == false)
    }

    @Test("合計3回（4未満） → 不成立")
    func lessThanFourGangs() {
        let game = makeGame(gangCounts: [1, 1, 1, 0])
        #expect(game.isSuukanSanyou() == false)
    }

    @Test("途中流局なしの設定 → 複数人で4回でも不成立")
    func disabledBySetting() {
        let game = makeGame(gangCounts: [2, 1, 1, 0], tochukuryokuAri: false)
        #expect(game.isSuukanSanyou() == false)
    }
}

@Suite("Player.isKyuushuCondition: 九種九牌")
struct KyuushuConditionTests {

    private func makePlayer(labels: [String], isFirstDraw: Bool) -> Player {
        let player = Player(id: 0, shoupai: Shoupai(labels))
        player.status.isFirstDraw = isFirstDraw
        return player
    }

    @Test("配牌時に么九牌9種以上 → 九種九牌")
    func ninePlusYaochuu() {
        // m1,m9,p1,p9,s1,s9,z1,z2,z3（9種）+ 残りは適当な中張牌
        let labels = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","m5","m6","p5","p6","s5"]
        let player = makePlayer(labels: labels, isFirstDraw: true)
        #expect(player.isKyuushuCondition() == true)
    }

    @Test("么九牌が8種のみ → 不成立")
    func eightYaochuuOnly() {
        let labels = ["m1","m9","p1","p9","s1","s9","z1","z2","m5","m6","p5","p6","s5","s6"]
        let player = makePlayer(labels: labels, isFirstDraw: true)
        #expect(player.isKyuushuCondition() == false)
    }

    @Test("九種九牌の牌姿でも配牌時（最初のツモ）でなければ不成立")
    func notFirstDraw() {
        let labels = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","m5","m6","p5","p6","s5"]
        let player = makePlayer(labels: labels, isFirstDraw: false)
        #expect(player.isKyuushuCondition() == false)
    }
}

@Suite("Game.canDeclareKyuushu: 九種九牌の全体条件（誰も副露していないこと）")
struct CanDeclareKyuushuTests {

    private func makeGame(fulouCounts: [Int], tochukuryokuAri: Bool = true) -> Game {
        let settings = GameSettings()
        settings.tochukuryokuAri = tochukuryokuAri
        let game = Game(settings: settings)
        game.players = fulouCounts.enumerated().map { i, count in
            let player = Player(id: i)
            if count > 0 {
                player.shoupai.fulou = [[Pai("m1"), Pai("m2"), Pai("m3")]]
            }
            return player
        }
        return game
    }

    @Test("誰も副露していない → 宣言可能")
    func noOneHasCalled() {
        let game = makeGame(fulouCounts: [0, 0, 0, 0])
        #expect(game.canDeclareKyuushu() == true)
    }

    @Test("他の誰かが既に副露している → 宣言不可")
    func someoneAlreadyCalled() {
        let game = makeGame(fulouCounts: [0, 1, 0, 0])
        #expect(game.canDeclareKyuushu() == false)
    }

    @Test("途中流局なしの設定 → 誰も副露していなくても宣言不可")
    func disabledBySetting() {
        let game = makeGame(fulouCounts: [0, 0, 0, 0], tochukuryokuAri: false)
        #expect(game.canDeclareKyuushu() == false)
    }
}

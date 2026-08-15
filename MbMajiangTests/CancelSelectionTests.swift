//
//  CancelSelectionTests.swift
//  MbMajiangTests
//
//  ポン・チー・暗カン・加カン・リーチのボタンを押した際に撤回ボタン（.cancelSelection）が
//  正しく表示・撤回・確定できるかのテスト。暗カン確定後にボタンが残り続けるバグの再発防止も含む。

import Testing
@testable import MbMajiang

@Suite("Game.handlePlayerAction: 選択開始時の撤回ボタン表示")
struct HandlePlayerActionSelectionTests {

    private func makeGame() -> Game {
        let game = Game()
        game.players = (0..<4).map { Player(id: $0) }
        game.status.player = 0
        return game
    }

    @Test("ポンを押すと選択状態に入り、撤回ボタンのみ表示される")
    func pengEntersSelectionWithCancelButton() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.status.availableButtonActions = [.peng, .chi, .cancel]
        game.handlePlayerAction(.peng)
        #expect(human.status.isSelectingPeng == true)
        #expect(human.status.availableButtonActions == [.cancelSelection])
        #expect(human.status.preSelectionActions == [.peng, .chi, .cancel])
    }

    @Test("チーを押すと選択状態に入り、撤回ボタンのみ表示される")
    func chiEntersSelectionWithCancelButton() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.status.availableButtonActions = [.chi, .cancel]
        game.handlePlayerAction(.chi)
        #expect(human.status.isSelectingChi == true)
        #expect(human.status.availableButtonActions == [.cancelSelection])
    }

    @Test("暗カン候補がある状態でアンカンを押すと選択状態に入り、撤回ボタンのみ表示される")
    func angangEntersSelectionWithCancelButton() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.shoupai = Shoupai(["m1","m1","m1","m1","p2","p3","p4","s5","s6","s7","z1","z1","z2"])
        human.status.availableButtonActions = [.angang]
        game.handlePlayerAction(.angang)
        #expect(human.status.isSelectingAngang == true)
        #expect(human.status.availableButtonActions == [.cancelSelection])
    }

    @Test("加カン候補がある状態でカカンを押すと選択状態に入り、撤回ボタンのみ表示される")
    func kagangEntersSelectionWithCancelButton() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.shoupai = Shoupai(["m1","p2","p3","p4","s5","s6","s7","z1","z1","z2","z3","z4","z5"])
        human.shoupai.fulou = [[Pai("m1"), Pai("m1"), Pai("m1")]]
        human.status.availableButtonActions = [.kagang]
        game.handlePlayerAction(.kagang)
        #expect(human.status.isSelectingKagang == true)
        #expect(human.status.availableButtonActions == [.cancelSelection])
    }

    @Test("リーチを押すと選択状態に入り、撤回ボタンのみ表示される")
    func lizhiEntersSelectionWithCancelButton() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.status.availableButtonActions = [.lizhi, .zimo]
        game.handlePlayerAction(.lizhi)
        #expect(human.status.isSelectingRiichi == true)
        #expect(human.status.availableButtonActions == [.cancelSelection])
    }

    @Test("明カンはボタンを押した瞬間に即確定し、撤回ボタンは出ない")
    func minggangCommitsInstantlyWithoutCancelButton() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.status.availableButtonActions = [.minggang, .cancel]
        game.handlePlayerAction(.minggang)
        #expect(human.status.decision == .minggang)
        #expect(human.status.availableButtonActions.isEmpty == true)
    }

    @Test("撤回すると選択前のボタン構成に戻る")
    func cancelSelectionRestoresPreviousActions() {
        let game = makeGame()
        let human = game.humanPlayer!
        human.status.availableButtonActions = [.peng, .chi, .cancel]
        game.handlePlayerAction(.peng)
        #expect(human.status.isSelectingPeng == true)

        game.handlePlayerAction(.cancelSelection)
        #expect(human.status.isSelectingPeng == false)
        #expect(human.status.availableButtonActions == [.peng, .chi, .cancel])
        #expect(human.status.preSelectionActions.isEmpty)
    }
}

@Suite("Player.cancelPendingSelection: 選択フラグの一括リセット")
struct CancelPendingSelectionTests {
    @Test("リーチ・ポン・チー・暗カン・加カンの選択関連状態を全てリセットする")
    func resetsAllSelectionFlags() {
        let player = Player(id: 0)
        player.status.isSelectingRiichi = true
        player.status.lizhiCandidateIndices = [1, 2]
        player.status.decision = .lizhi
        player.status.isSelectingPeng = true
        player.status.selectedPengIndices = [3, 4]
        player.status.isSelectingChi = true
        player.status.selectedChiIndices = [5, 6]
        player.status.isSelectingAngang = true
        player.status.isSelectingKagang = true

        player.cancelPendingSelection()

        #expect(player.status.isSelectingRiichi == false)
        #expect(player.status.lizhiCandidateIndices.isEmpty)
        #expect(player.status.decision == .none)
        #expect(player.status.isSelectingPeng == false)
        #expect(player.status.selectedPengIndices.isEmpty)
        #expect(player.status.isSelectingChi == false)
        #expect(player.status.selectedChiIndices.isEmpty)
        #expect(player.status.isSelectingAngang == false)
        #expect(player.status.isSelectingKagang == false)
    }

    @Test("リーチ以外の理由でdecisionが設定されている場合はクリアしない")
    func doesNotClearUnrelatedDecision() {
        let player = Player(id: 0)
        player.status.decision = .dapai
        player.cancelPendingSelection()
        #expect(player.status.decision == .dapai)
    }
}

@Suite("選択確定時に撤回ボタンが即座にクリアされる")
struct SelectionCompletionClearsButtonsTests {
    @Test("ポン確定時に即座にボタンがクリアされる")
    func selectPengClearsButtonsImmediately() {
        let player = Player(id: 0)
        player.status.isSelectingPeng = true
        player.status.availableButtonActions = [.cancelSelection]
        player.status.preSelectionActions = [.peng, .chi]
        player.selectPeng(0)
        player.selectPeng(1)
        #expect(player.status.decision == .peng)
        #expect(player.status.availableButtonActions.isEmpty)
        #expect(player.status.preSelectionActions.isEmpty)
    }

    @Test("チー確定時に即座にボタンがクリアされる")
    func selectChiClearsButtonsImmediately() {
        let player = Player(id: 0)
        player.status.isSelectingChi = true
        player.status.availableButtonActions = [.cancelSelection]
        player.selectChi(0)
        player.selectChi(1)
        #expect(player.status.decision == .chi)
        #expect(player.status.availableButtonActions.isEmpty)
    }

    @Test("暗カン確定時に即座にボタンがクリアされる")
    func selectAngangClearsButtonsImmediately() {
        let player = Player(id: 0, shoupai: Shoupai(["m1"]))
        player.status.isSelectingAngang = true
        player.status.availableButtonActions = [.cancelSelection]
        player.selectAngang(0)
        #expect(player.status.decision == .angang)
        #expect(player.status.availableButtonActions.isEmpty)
    }

    @Test("加カン確定時に即座にボタンがクリアされる")
    func selectKagangClearsButtonsImmediately() {
        let player = Player(id: 0, shoupai: Shoupai(["m1"]))
        player.status.isSelectingKagang = true
        player.status.availableButtonActions = [.cancelSelection]
        player.selectKagang(0)
        #expect(player.status.decision == .kagang)
        #expect(player.status.availableButtonActions.isEmpty)
    }

    @Test("リーチ打牌確定時に即座にボタンがクリアされる")
    func selectDapaiClearsButtonsImmediately() {
        let player = Player(id: 0)
        player.status.isSelectingRiichi = true
        player.status.availableButtonActions = [.cancelSelection]
        player.selectDapai(0)
        #expect(player.status.decision == .dapai)
        #expect(player.status.availableButtonActions.isEmpty)
    }
}

@Suite("Player.onLingshang: 嶺上フェーズでの選択状態クリア（暗カン後にボタンが残り続けるバグの再発防止）")
struct OnLingshangTests {
    @Test("暗カンの撤回ボタンが残っていても、嶺上フェーズで確実にクリアされる")
    func clearsStaleCancelButtonAfterAngang() {
        let player = Player(id: 0)
        player.status.availableButtonActions = [.cancelSelection]
        player.status.isSelectingAngang = true
        var status = GameStatus()
        status.phase = .lingshang
        player.callback(status: status)
        #expect(player.status.availableButtonActions.isEmpty)
        #expect(player.status.isSelectingAngang == false)
        #expect(player.status.decision == .none)
    }

    @Test("加カン由来の選択状態も嶺上フェーズでクリアされる")
    func clearsStaleStateAfterKagang() {
        let player = Player(id: 0)
        player.status.availableButtonActions = [.cancelSelection]
        player.status.isSelectingKagang = true
        var status = GameStatus()
        status.phase = .lingshang
        player.callback(status: status)
        #expect(player.status.availableButtonActions.isEmpty)
        #expect(player.status.isSelectingKagang == false)
    }
}

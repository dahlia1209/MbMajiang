//
//  GameState.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/02.
//

import Foundation



// MARK: - Game
@Observable
class Game: Identifiable {
    let id = UUID()
    var settings: GameSettings
    var board: Board
    var status: GameStatus
    var players: [Player]
    var isFulouSkipEnabled: Bool = false

    var debugHands: [Int: [String]] = [:] {
        didSet { applyDebugHands() }
    }

    private func applyDebugHands() {
        for (idx, hand) in debugHands {
            guard board.shan.shoupai.indices.contains(idx),
                  players.indices.contains(idx) else { continue }
            let fixed = hand.map { Pai($0) }
            board.shan.shoupai[idx].bingpai = fixed
            players[idx].shoupai.bingpai = fixed
        }
    }

    init(settings: GameSettings = GameSettings(), board: Board = Board(), status: GameStatus = GameStatus()) {
        self.settings = settings
        self.board = board
        self.status = status
        self.players = []
        self.status.riichiAnkanLevel = settings.riichiAnkanLevel
        self.status.notenSengenAri = settings.notenSengenAri
    }
    
    func start() {
        kaiju()
    }
    
    // MARK: - Game Actions
    func kaiju() {
        status.phase = .kaiju
        SoundManager.shared.soundTheme = settings.soundTheme
        // 配給原点を defen に反映
        for i in board.score.defen.indices {
            board.score.defen[i].1 = settings.haikyuGenten
        }
        // idを付与してプレイヤーを初期化（Shoupai/HeはShanと同一参照）
        players = (0..<4).map { i in
            if i == 0 {
                return Player(id: i, shoupai: board.shan.shoupai[i], he: board.shan.he[i])
            }
            let ai = AIPlayer(id: i, shoupai: board.shan.shoupai[i], he: board.shan.he[i])
            ai.cpuLevel = settings.cpuLevel
            ai.getRemainingCounts = { [weak self] in self?.remainingCounts(for: i) ?? [:] }
            ai.getRiichiGenbutsu = { [weak self] in
                guard let self else { return nil }
                let riichiOpponents = self.players.enumerated().filter { idx, p in idx != i && p.status.isLizhi }
                guard !riichiOpponents.isEmpty else { return nil }
                return riichiOpponents.map { idx, _ in
                    var safe = Set(self.board.shan.he[idx].qipai.map { $0.normalized })
                    self.status.afterLizhiDiscards[idx].forEach { safe.insert($0) }
                    return safe
                }
            }
            return ai
        }
        board.score.setQijia(qijia: Int.random(in: 0...3))
        advance()
    }

    func qipai() {
        status.phase = .qipai
        // 局が変わるたびに持ち時間をリセット（一局単位の持ち時間）
        totalTimeRemaining = Double(settings.totalTimeBank)
        status.dapai = nil
        status.zimo = nil

        status.hulePlayer = nil
        status.zhuangfeng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        status.menfengList = board.score.defen.map { $0.0 }
        status.afterLizhiDiscards = [[],[],[],[]]
        status.junDiscards = [[],[],[],[]]

        board.shan = Shan(settings: settings)
        for (i, player) in players.enumerated() {
            player.shoupai=board.shan.shoupai[i]
            player.he=board.shan.he[i]
            player.status=PlayerStatus()
        }
        applyDebugHands()
        SoundManager.shared.playSequence(roundAnnouncementNames(), overlap: 0.15)
        let (roundNames, honbaNames) = roundCutInImageNames()
        roundCutInRoundNames = roundNames
        roundCutInHonbaNames = honbaNames
    }

    private func roundAnnouncementNames() -> [String] {
        var names: [String] = []
        let raw = board.score.round.rawValue
        names.append(raw.hasPrefix("東") ? "tong" : "nan")
        switch raw {
        case "東一局", "南一局": names.append("ikkyoku")
        case "東二局", "南二局": names.append("nikyoku")
        case "東三局", "南三局": names.append("sankyoku")
        case "東四局", "南四局": names.append("yonkyoku")
        default: break
        }
        let h = board.score.honba
        let honbaFiles = ["ipponba", "nihonba", "sanbonba",
                          "yonhonba", "gohonba", "ropponba",
                          "nanahonba", "happonba"]
        if h >= 1 && h <= 8 { names.append(honbaFiles[h - 1]) }
        return names
    }
    
    func zimoHule() {
        SoundManager.shared.play("zimo")
        let idx = status.player
        huleCutInPlayer = idx
        huleCutInImageName = "zimo"
        status.hulePlayer = idx
        primaryRonWinner = idx
        let context = buildHuleContext(player: idx, kind: .zimo)
        let result = buildHuleResult(playerIdx: idx, kind: .zimo, context: context, honba: board.score.honba, lizhibang: board.score.lizhibang, baseDefen: board.score.defen)
        pendingHuleResults.append(result)
        status.phase = .hule
    }

    func ronHule(_ winnerIds: [Int]) {
        SoundManager.shared.play("rong")
        huleCutInPlayer = winnerIds.first
        huleCutInImageName = "rong"
        primaryRonWinner = winnerIds.first
        var currentDefen = board.score.defen
        for (i, winnerId) in winnerIds.enumerated() {
            // 本場は全勝者に適用、供託は頭ハネ（最初）のみ
            let lizhibang = i == 0 ? board.score.lizhibang : 0
            let context = buildHuleContext(player: winnerId, kind: .rong)
            let result  = buildHuleResult(playerIdx: winnerId, kind: .rong, context: context, honba: board.score.honba, lizhibang: lizhibang, baseDefen: currentDefen)
            pendingHuleResults.append(result)
            for j in 0..<4 { currentDefen[j].1 += result.scoreChanges[j] }
        }
        status.phase = .hule
    }
    
    func pingju(kind: HuleResult.Kind = .pingju) {
        computePingjuResult(kind: kind)
        status.phase = .hule
        pingjuCutInActive = true
    }

    //リーチ後に供託を積む処理
    private func processLizhiPayments() {
        for player in players where player.status.pendingLizhiPayment {
            board.score.defen[player.id].1 -= 1000
            board.score.lizhibang += 1
            player.commitLizhi()
        }
    }

    func zimo() {
        guard board.shan.paishu > 0 else {
            status.phase = .pingju
            advance()
            return
        }
        status.lastDapai = nil
        status.phase = .zimo
        status.isLingshang = false
        status.junDiscards[status.player] = []
        infoMessage = nil
        processLizhiPayments()

        if isSuuchaRiichi() {
            pingju(kind: .suuchaRiichi)
            return
        }

        //プレイヤーツモ
        let tile = board.shan.shan.removeLast()
        players[status.player].shoupai.zimo = tile
        status.zimo = tile.label
        status.paishu = board.shan.paishu

        advance()
    }
    
    func lingshangzimo(){
        guard !board.shan.wangpai.lingshang.isEmpty else {
            pingju()
            return
        }
        status.lastDapai = nil

        //カンドラめくり
        if status.gangdoraFlag == .afterZimo {
            if settings.kandoraAri { board.shan.wangpai.revealGangdora() }
            status.gangdoraFlag = .none
        }

        if isSuukanSanyou() {
            pingju(kind: .suukanSanyou)
            return
        }

        status.phase = .zimo
        status.isLingshang = true
        let tile = board.shan.wangpai.lingshang.removeLast()
        players[status.player].shoupai.zimo = tile
        status.zimo = tile.label
        status.paishu = board.shan.paishu
        advance()
    }
    
    // ダブル立直判定: 打牌者にとって最初の打牌であり、かつ全員が副露（暗槓含む）していないこと
    static func computeIsDaburi(isFirstDiscard: Bool, players: [Player]) -> Bool {
        isFirstDiscard && players.allSatisfy { $0.shoupai.fulou.isEmpty }
    }

    func dapai() {
        status.phase = .dapai
        infoMessage = nil
        SoundManager.shared.play("dapai2")
        let player = status.player
        let isFirstDiscard = players[player].status.firstDapai == nil
        let dapai=players[player].dapai()
        status.dapai = dapai.label
        status.lastDapai = (player: player, index: players[player].he.qipai.count - 1)

        //カンドラめくり
        if status.gangdoraFlag == .afterDapai {
            if settings.kandoraAri { board.shan.wangpai.revealGangdora() }
            status.gangdoraFlag = .none
        }

        // リーチ宣言打牌の後処理
        if players[player].status.isSelectingRiichi {
            players[player].status.isDaburi = Game.computeIsDaburi(isFirstDiscard: isFirstDiscard, players: players)
            SoundManager.shared.play("lizhi")
            players[player].pendingLizhi()
            lizhiCutInPlayer = player
        } else if players[player].status.isYifa {
            players[player].cancelYifa()
        }



        // 回転処理（リーチ打牌 or 副露された後の打牌）
        if players[player].status.shouldRotateNextDapai {
            let hasRotated = players[player].he.qipai.contains { $0.rotated }
            if hasRotated {
                players[player].clearRotateFlag()
            } else {
                players[player].rotateLastDapai()
            }
        }

        if lizhiCutInPlayer == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.advance()
            }
        }
    }

    func peng(player fulouPlayer: Int) {
        SoundManager.shared.play("peng")
        showActionBanner("peng", player: fulouPlayer)
        status.lastDapai = nil
        guard players[fulouPlayer].status.selectedPengIndices.count == 2 else { return }
        let dapaiPai = players[status.player].he.callLast()
        if let paoIdx = detectPao(fulouPlayer: fulouPlayer, calledTile: dapaiPai, isMinggang: false) {
            players[fulouPlayer].status.paoPlayerIdx = paoIdx
        }
        let relPos = (fulouPlayer - status.player + 4) % 4
        let tajia: Jia
        switch relPos {
        case 3: tajia = .xiajia
        case 2: tajia = .duimian
        case 1: tajia = .shangjia
        default: tajia = .zijia
        }
        players[fulouPlayer].peng(dapai: dapaiPai, tajia: tajia, kuichikaeLevel: settings.kuichikaeLevel)
        status.player = fulouPlayer
        status.phase = .fulou
        status.junDiscards[fulouPlayer] = []
        players.indices.forEach { players[$0].cancelYifa() }
        processLizhiPayments()
        advance()
    }

    func minggang(player fulouPlayer: Int) {
        SoundManager.shared.play("gang")
        showActionBanner("gang", player: fulouPlayer)
        status.lastDapai = nil
        let dapaiPai = players[status.player].he.callLast()
        if let paoIdx = detectPao(fulouPlayer: fulouPlayer, calledTile: dapaiPai, isMinggang: true) {
            players[fulouPlayer].status.paoPlayerIdx = paoIdx
        }
        let relPos = (fulouPlayer - status.player + 4) % 4
        let tajia: Jia
        switch relPos {
        case 3: tajia = .xiajia
        case 2: tajia = .duimian
        case 1: tajia = .shangjia
        default: tajia = .zijia
        }
        players[fulouPlayer].minggang(dapai: dapaiPai, tajia: tajia)
        status.player = fulouPlayer
        status.gangdoraFlag = .afterDapai
        status.phase = .lingshang
        status.junDiscards[fulouPlayer] = []
        players.indices.forEach { players[$0].cancelYifa() }
        processLizhiPayments()
        advance()
    }

    private func detectPao(fulouPlayer: Int, calledTile: Pai, isMinggang: Bool) -> Int? {
        guard settings.yakumanPaoAri else { return nil }

        let shoupai = players[fulouPlayer].shoupai
        let calledNorm = Pai.normalize(calledTile.label)

        let dragonLabels = Set(["z5", "z6", "z7"])
        let windLabels   = Set(["z1", "z2", "z3", "z4"])

        var existingDragonMelds = Set<String>()
        var existingWindMelds   = Set<String>()
        var existingKanCount    = 0

        for group in shoupai.fulou {
            let norms = group.map { Pai.normalize($0.label) }.filter { $0.count == 2 }
            guard let first = norms.first, Set(norms).count == 1 else { continue }
            if group.count == 4 { existingKanCount += 1 }
            if dragonLabels.contains(first) { existingDragonMelds.insert(first) }
            if windLabels.contains(first)   { existingWindMelds.insert(first) }
        }

        if dragonLabels.contains(calledNorm),
           !existingDragonMelds.contains(calledNorm),
           existingDragonMelds.count == 2 {
            return status.player
        }

        if windLabels.contains(calledNorm),
           !existingWindMelds.contains(calledNorm),
           existingWindMelds.count == 3 {
            return status.player
        }

        if isMinggang && existingKanCount == 3 {
            return status.player
        }

        return nil
    }
    
    func chi(player fulouPlayer: Int) {
        SoundManager.shared.play("chi")
        showActionBanner("chi", player: fulouPlayer)
        status.lastDapai = nil
        guard players[fulouPlayer].status.selectedChiIndices.count == 2 else { return }
        let dapaiPai = players[status.player].he.callLast()
        let relPos = (fulouPlayer - status.player + 4) % 4
        let tajia: Jia
        switch relPos {
        case 3: tajia = .xiajia
        case 2: tajia = .duimian
        case 1: tajia = .shangjia
        default: tajia = .zijia
        }
        players[fulouPlayer].chi(dapai: dapaiPai, tajia: tajia, kuichikaeLevel: settings.kuichikaeLevel)
        status.player = fulouPlayer
        status.phase = .fulou
        status.junDiscards[fulouPlayer] = []
        players.indices.forEach { players[$0].cancelYifa() }
        processLizhiPayments()
        advance()
    }
    
    func angang() {
        SoundManager.shared.play("gang")
        showActionBanner("gang", player: status.player)
        players[status.player].angang()
        status.gangdoraFlag = .afterZimo
        status.phase = .lingshang
        players.indices.forEach { players[$0].cancelYifa() }
        advance()
    }

    func kagang() {
        SoundManager.shared.play("gang")
        showActionBanner("gang", player: status.player)
        status.dapai = players[status.player].status.selectedKagang
        players[status.player].kagang()
        status.gangdoraFlag = .afterZimo
        status.phase = .kagang
        players.indices.forEach { players[$0].cancelYifa() }
        advance()
    }


    
    
    // MARK: - Advance

    var humanPlayer: Player? { players.first(where: { $0.isHuman }) }

    // 全プレイヤーにcallbackを通知し、人間プレイヤーが準備完了次第ゲーム進行を処理
    private func advance() {
        players.forEach { $0.callback(status: self.status) }

        // 副露スキップ有効時、ロンなしの副露ボタンのみなら自動キャンセル
        if isFulouSkipEnabled, let human = humanPlayer {
            let fulouOnly: Set<PlayerButtonAction> = [.chi, .peng, .minggang, .cancel]
            let actions = human.status.availableButtonActions
            if !actions.isEmpty && !actions.contains(.rong) && actions.isSubset(of: fulouOnly) {
                human.status.availableButtonActions = []
                if status.phase == .dapai && (status.player + 1) % 4 == human.id {
                    human.status.decision = .zimo
                }
            }
        }

        if needsHumanInput() {
            // 人間プレイヤーの入力待ち: Player.onActionReady 経由でゲームループを再開
            humanPlayer?.onActionReady = { [weak self] in
                self?.stopTurnTimer()
                DispatchQueue.main.async { self?.processPlayerActions() }
            }
            // 打牌番・ボタン選択（ポン/チー/ロン）どちらもタイマー開始
            startTurnTimer()
        } else {
            DispatchQueue.main.async { [weak self] in self?.processPlayerActions() }
        }
    }

    // 人間プレイヤーが入力待ちか判定（フェーズも考慮）
    private func needsHumanInput() -> Bool {
        guard let human = humanPlayer else { return false }
        guard human.status.decision == .none else { return false }
        // 打牌番（ツモ直後または副露直後）
        let isDapaiTurn = status.player == human.id && (status.phase == .zimo || status.phase == .fulou)
        // ポン・ロン等のボタンが表示されている
        let hasButtons = !human.status.availableButtonActions.isEmpty
        return isDapaiTurn || hasButtons
    }

    // 人間プレイヤーの行動確定を通知（ボタン操作などタップ以外のUIから呼ぶ）
    func resolveHuman() {
        let handler = humanPlayer?.onActionReady
        humanPlayer?.onActionReady = nil
        DispatchQueue.main.async { handler?() }
    }

    // プレイヤーのstatusを読み取り、次のゲームアクションを決定・実行
    private func processPlayerActions() {
        switch status.phase {
        case .kaiju:
            qipai()

        case .qipai:
            status.player = getTongjia()
            zimo()

        case .zimo:
            // 暗槓
            if let actor = players.first(where: { $0.id == status.player && $0.status.decision == .angang }) {
                actor.consumeDecision()
                if isGangFull {
                    (actor as? AIPlayer)?.selectDapai()
                    dapai()
                } else {
                    angang()
                }
                return
            }
            // 加槓
            if let actor = players.first(where: { $0.id == status.player && $0.status.decision == .kagang }) {
                actor.consumeDecision()
                if isGangFull {
                    (actor as? AIPlayer)?.selectDapai()
                    dapai()
                } else {
                    kagang()
                }
                return
            }
            
            // 現在プレイヤー（player 0 または AI）の打牌
            if let actor = players.first(where: { $0.id == status.player && $0.status.decision == .dapai }) {
                actor.consumeDecision()
                dapai()
                return
            }
            
            // ツモアガリ
            if let winner = players.first(where: { $0.id == status.player && $0.status.decision == .hule }) {
                winner.consumeDecision()
                zimoHule()
                return
            }

        case .dapai:
            // 四風連打
            if isSuufon() {
                pingju(kind: .suufon)
                return
            }
            // ロンアガリ（同時和了対応）
            let hulers = players.filter { $0.status.decision == .hule }
            if !hulers.isEmpty {
                hulers.forEach { $0.consumeDecision() }
                switch Game.resolveDojiHule(hulerIds: hulers.map { $0.id }, discarder: status.player, dojiHuleMax: settings.dojiHuleMax) {
                case .sanchahou:
                    pingju(kind: .sanchahou)
                case .winners(let winnerIds):
                    ronHule(winnerIds)
                }
                return
            }

            // カン宣言
            if let fulouPlayer = players.first(where: { $0.status.decision == .minggang }) {
                fulouPlayer.consumeDecision()
                if !isGangFull {
                    minggang(player: fulouPlayer.id)
                    return
                }
                // 5回目のカンは不可: 明槓せず次のアクション判定（ポン・チーなど）へ進む
            }
            
            // ポン（副露）宣言
            if let fulouPlayer = players.first(where: { $0.status.decision == .peng }) {
                peng(player: fulouPlayer.id)
                return
            }
            
            // チー（副露）宣言
            if let fulouPlayer = players.first(where: { $0.status.decision == .chi }) {
                fulouPlayer.consumeDecision()
                chi(player: fulouPlayer.id)
                return
            }
            
            // ポスト処理：同巡フリテン用: 他プレイヤーのjunDiscardsに記録
            // リーチ後フリテン用: 見逃したアガリ牌をafterLizhiDiscardsに記録（ツモ後もリセットしない）
            if let label = status.dapai {
                let normalized = Pai.normalize(label)
                for i in 0..<4 where i != status.player {
                    status.junDiscards[i].append(normalized)
                    if players[i].status.isLizhi {
                        let tiles = players[i].shoupai.visibleLabels.map { Pai.normalize($0) } + [normalized]
                        if !Hule.winningDecompositions(tiles).isEmpty,
                           !status.afterLizhiDiscards[i].contains(normalized) {
                            status.afterLizhiDiscards[i].append(normalized)
                        }
                    }
                }
            }
            
            // 次のツモへ
            guard let actor = players.first(where: { $0.status.decision == .zimo }) else { return }
            actor.consumeDecision()
            status.player = actor.id
            zimo()

        case .fulou:
            // 現在プレイヤー（player 0 または AI）の副露後打牌
            guard let actor = players.first(where: { $0.id == status.player && $0.status.decision == .dapai }) else { return }
            actor.consumeDecision()
            dapai()

        case .kagang:
            // 槍槓：加槓牌でロンできるプレイヤーがいれば和了、いなければ嶺上牌をツモ
            let hulers = players.filter { $0.status.decision == .hule }
            if !hulers.isEmpty {
                hulers.forEach { $0.consumeDecision() }
                switch Game.resolveDojiHule(hulerIds: hulers.map { $0.id }, discarder: status.player, dojiHuleMax: settings.dojiHuleMax) {
                case .sanchahou:
                    pingju(kind: .sanchahou)
                case .winners(let winnerIds):
                    ronHule(winnerIds)
                }
            } else {
                status.phase = .lingshang
                lingshangzimo()
            }

        case .lingshang:
            lingshangzimo()

        case .pingju:
            let tenpaiIndices: [Int]
            if status.notenSengenAri {
                tenpaiIndices = players.indices.filter { i in
                    players[i].status.decision != .noten &&
                    Hule.xiangting(players[i].shoupai.visibleLabels.map { Pai.normalize($0) }) == 0
                }
            } else {
                tenpaiIndices = players.indices.filter { i in
                    Hule.xiangting(players[i].shoupai.visibleLabels.map { Pai.normalize($0) }) == 0
                }
            }
            players.forEach { $0.consumeDecision() }
            computePingjuResult(declaredTenpaiIndices: tenpaiIndices)
            status.phase = .hule
            pingjuCutInActive = true

        default:
            break
        }
    }
    
    // MARK: - Turn Timer

    var turnTimeRemaining: Double = 0
    // 一局ごとに減り続ける持ち時間（0 = 無制限。局が変わるたびに qipai() で設定値をセット）
    var totalTimeRemaining: Double = 0
    var isTurnTimerActive: Bool = false
    private var turnTimer: Timer?

    private func startTurnTimer() {
        stopTurnTimer()
        let hasBank = settings.totalTimeBank > 0
        let bankAvailable = hasBank && totalTimeRemaining > 0
        // 持ち時間がまだ残っている間は一打の猶予（bank300では0＝即座に持ち時間を消費）、
        // 使い切った後は秒読み（postBankTimeLimit）を適用する
        let currentLimit = !hasBank ? settings.turnTimeLimit : (bankAvailable ? settings.turnTimeLimit : settings.postBankTimeLimit)
        guard currentLimit > 0 || bankAvailable else { return }
        turnTimeRemaining = Double(currentLimit)
        isTurnTimerActive = true
        turnTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let hasBank = self.settings.totalTimeBank > 0
            let bankAvailable = hasBank && self.totalTimeRemaining > 0

            if !hasBank {
                // 持ち時間なし: 一打の制限時間のみ
                self.turnTimeRemaining = max(0, self.turnTimeRemaining - 0.1)
                if self.turnTimeRemaining <= 0 {
                    self.stopTurnTimer()
                    self.timeoutDapai()
                }
            } else if bankAvailable {
                // 持ち時間が残っている間: 一打の猶予を使い切ってから持ち時間を消費
                if self.settings.turnTimeLimit > 0 && self.turnTimeRemaining > 0 {
                    self.turnTimeRemaining = max(0, self.turnTimeRemaining - 0.1)
                } else {
                    self.totalTimeRemaining = max(0, self.totalTimeRemaining - 0.1)
                    if self.totalTimeRemaining <= 0 {
                        // 持ち時間を使い切った: 以降は秒読みに切り替える
                        self.turnTimeRemaining = Double(self.settings.postBankTimeLimit)
                        if self.settings.postBankTimeLimit <= 0 {
                            self.stopTurnTimer()
                            self.timeoutDapai()
                        }
                    }
                }
            } else {
                // 持ち時間を使い切った後の秒読み
                self.turnTimeRemaining = max(0, self.turnTimeRemaining - 0.1)
                if self.turnTimeRemaining <= 0 {
                    self.stopTurnTimer()
                    self.timeoutDapai()
                }
            }
        }
    }

    func stopTurnTimer() {
        isTurnTimerActive = false
        turnTimer?.invalidate()
        turnTimer = nil
    }

    private func timeoutDapai() {
        guard let human = humanPlayer else { return }
        let isDapaiTurn = status.player == human.id && (status.phase == .zimo || status.phase == .fulou)
        let hasButtons = !human.status.availableButtonActions.isEmpty

        if isDapaiTurn {
            // .zimo: bingpai.countはツモ牌インデックス（zimo非nil）
            // .fulou: zimo=nilのためbingpai.countは使えず、最後の牌(count-1)をデフォルトにする
            let defaultIndex = status.phase == .fulou
                ? human.shoupai.bingpai.count - 1
                : human.shoupai.bingpai.count
            let index = pendingDapaiIndex ?? defaultIndex
            pendingDapaiIndex = nil
            machiTiles = []
            machiYakuSet = []
            machiFuritenSet = []
            human.selectDapai(index)
        } else if hasButtons {
            // 自動キャンセル: ポン/チー/ロンを辞退（.cancelと同じ処理）
            human.status.availableButtonActions = []
            if status.phase == .dapai && (status.player + 1) % 4 == human.id {
                human.status.decision = .zimo
            }
            resolveHuman()
        }
    }

    // MARK: - Helpers

    func getTongjia() -> Int {
        return board.score.defen.firstIndex(where: { $0.0 == .東 })!
    }
    
    var isSelectingDapai: Bool {
        guard let human = humanPlayer else { return false }
        if human.status.isLizhi {
            // リーチ中: ツモアガリ可能なときのみツモ牌タップを受け付ける
            return status.player == human.id && !human.status.availableButtonActions.isEmpty
        }
        return status.player == human.id && (status.phase == .zimo || status.phase == .fulou)
    }
    
    var isSelectingChi: Bool {
        guard let human = humanPlayer else { return false }
        return status.player != human.id && human.status.isSelectingChi == true
    }
    
    var isSelectingAngang: Bool {
        guard let human = humanPlayer else { return false }
        return status.player == human.id && human.status.isSelectingAngang == true
    }
    
    var isSelectingKagang: Bool {
        guard let human = humanPlayer else { return false }
        return status.player == human.id && human.status.isSelectingKagang == true
    }

    var isSelectingPeng: Bool {
        guard let human = humanPlayer else { return false }
        return status.player != human.id && human.status.isSelectingPeng == true
    }
    



    // MARK: - Player Action Buttons
    // 人間プレイヤーの callback が設定した availableButtonActions をそのまま返す
    var playerActions: Set<PlayerButtonAction> {
        humanPlayer?.status.availableButtonActions ?? []
    }

    // アクションボタンが押された時の処理
    func handlePlayerAction(_ action: PlayerButtonAction) {
        guard let human = humanPlayer else { return }
        let previousActions = human.status.availableButtonActions
        human.status.availableButtonActions = []
        switch action {
        case .cancel:
            // チー/ポン/ロン辞退後、自分のツモ番なら .zimo をセットしてから進める
            if status.phase == .dapai && (status.player + 1) % 4 == human.id {
                human.status.decision = .zimo
            }
            resolveHuman()
        case .zimo:
            human.status.decision = .hule
            resolveHuman()
        case .kyuushu:
            if canDeclareKyuushu() {
                pingju(kind: .kyuushu)
            }
            // 条件を満たさない場合はボタンが消えるだけ（打牌で続行）
        case .rong:
            if human.isFuriten(
                afterLizhiDiscards: status.afterLizhiDiscards[human.id],
                junDiscards: status.junDiscards[human.id]
            ) {
                infoMessage = "フリテン"
                human.status.availableButtonActions = previousActions
            } else {
                human.status.decision = .hule
                resolveHuman()
            }
        case .lizhi:
            human.startRiichiSelection()
        case .peng:
            if human.status.pengCandidates.count == 1 {
                human.status.selectedPengIndices = human.status.pengCandidates[0]
                human.status.decision = .peng
                resolveHuman()
            } else {
                human.startPengSelection()
            }
            
        case .minggang:
            if isGangFull {
                infoMessage = "5回目のカンは不可"
                return
            }
            human.status.decision = .minggang
            resolveHuman()
        case .chi:
            if human.status.chiCandidates.count == 1 {
                human.status.selectedChiIndices = human.status.chiCandidates[0]
                human.status.decision = .chi
                resolveHuman()
            } else {
                human.startChiSelection()
            }
        case .angang:
            if isGangFull {
                infoMessage = "5回目のカンは不可"
                return
            }
            if human.shoupai.gangzi.count == 1 {
                human.prepareAngang(label: human.shoupai.gangzi[0])
                resolveHuman()
            } else if human.shoupai.gangzi.count > 1 {
                human.startAngangSelection()
            } else {
                human.status.decision = .zimo
                resolveHuman()
            }
        case .kagang:
            if isGangFull {
                infoMessage = "5回目のカンは不可"
                return
            }
            if human.shoupai.kagangzi.count == 1 {
                human.prepareKagang(label: human.shoupai.kagangzi[0])
                resolveHuman()
            } else if human.shoupai.kagangzi.count > 1 {
                human.startKagangSelection()
            } else {
                human.status.decision = .zimo
                resolveHuman()
            }

        case .pingju:
            human.status.decision = .pingju
            resolveHuman()
        case .noten:
            human.status.decision = .noten
            resolveHuman()

        default:
            resolveHuman()
        }
    }
    
    // MARK: - 残り牌枚数計算

    /// playerIdx から見た各牌の残り枚数を返す
    /// 見えている牌（自手牌・全員の捨て牌・全員の副露・ドラ表示牌）を差し引いた値
    func remainingCounts(for playerIdx: Int) -> [String: Int] {
        var counts: [String: Int] = [:]
        for suit in ["m", "p", "s"] {
            for n in 1...9 { counts["\(suit)\(n)"] = 4 }
        }
        for n in 1...7 { counts["z\(n)"] = 4 }

        // 赤ドラを分離：通常5の枚数を調整し赤ドラを独立したキーで管理
        let akaDoraCounts = [("m", settings.akadoraMan), ("p", settings.akadoraPin), ("s", settings.akadoraSou)]
        for (suit, aka) in akaDoraCounts where aka > 0 {
            counts["\(suit)5"]! -= aka
            counts["\(suit)0"] = aka
        }

        func subtract(_ label: String) {
            guard label != "_", counts[label] != nil else { return }
            counts[label]! -= 1
        }

        // 自分の手牌（bingpai + zimo + 自分の副露）
        let own = board.shan.shoupai[playerIdx]
        own.bingpai.forEach { subtract($0.label) }
        if let zimo = own.zimo { subtract(zimo.label) }
        for group in own.fulou {
            group.forEach { subtract($0.label) }
        }

        // 全プレイヤーの捨て牌（鳴かれていないもののみ）
        for he in board.shan.he {
            he.qipai.forEach { subtract($0.label) }
        }

        // 他プレイヤーの副露（鳴かれた牌 + 手牌から出た牌）
        for i in 0..<4 where i != playerIdx {
            for group in board.shan.shoupai[i].fulou {
                group.forEach { subtract($0.label) }
            }
        }

        // 見えているドラ表示牌
        board.shan.wangpai.baopai.forEach { subtract($0.label) }

        return counts
    }

    // MARK: - Lizhi Cut-in
    var lizhiCutInPlayer: Int? = nil
    var actionBannerImage: String? = nil
    var actionBannerPlayer: Int? = nil

    // MARK: - Pingju Cut-in
    var pingjuCutInActive: Bool = false

    func dismissPingjuCutIn() {
        pingjuCutInActive = false
        if let result = huleResult, result.kind == .pingju {
            let dealer = getTongjia()
            tenpaiCutInQueue = result.tenpaiPlayers.sorted { ($0 - dealer + 4) % 4 < ($1 - dealer + 4) % 4 }
        }
    }

    // MARK: - Tenpai Cut-in
    var tenpaiCutInQueue: [Int] = []
    var tenpaiCutInCurrentPlayer: Int? { tenpaiCutInQueue.first }

    func dismissTenpaiCutIn() {
        if !tenpaiCutInQueue.isEmpty { tenpaiCutInQueue.removeFirst() }
    }

    // MARK: - Hule Cut-in
    var huleCutInPlayer: Int? = nil
    var huleCutInImageName: String? = nil

    func dismissHuleCutIn() {
        huleCutInPlayer = nil
        huleCutInImageName = nil
    }

    // MARK: - Round Cut-in
    var roundCutInRoundNames: [String] = []
    var roundCutInHonbaNames: [String] = []

    func dismissRoundCutIn() {
        roundCutInRoundNames = []
        roundCutInHonbaNames = []
        advance()
    }

    private func roundCutInImageNames() -> (round: [String], honba: [String]) {
        let raw = board.score.round.rawValue
        var round: [String] = []
        round.append(raw.hasPrefix("東") ? "dong" : "nan")
        switch raw {
        case "東一局", "南一局": round += ["yi", "kyoku"]
        case "東二局", "南二局": round += ["er", "kyoku"]
        case "東三局", "南三局": round += ["san", "kyoku"]
        case "東四局", "南四局": round += ["si", "kyoku"]
        default: break
        }
        let numberImages = ["yi", "er", "san", "si"]
        let h = board.score.honba
        let honba: [String] = (h >= 1 && h <= 4) ? [numberImages[h - 1], "honba"] : []
        return (round, honba)
    }

    func showActionBanner(_ imageName: String, player: Int? = nil, duration: Double = 1.2) {
        actionBannerImage = imageName
        actionBannerPlayer = player
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.actionBannerImage = nil
            self?.actionBannerPlayer = nil
        }
    }

    func dismissLizhiCutIn() {
        lizhiCutInPlayer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.advance()
        }
    }

    // MARK: - Machi Tiles
    var machiTiles: [String] = []
    var machiYakuSet: Set<String> = []
    var machiFuritenSet: Set<String> = []
    var pendingDapaiIndex: Int? = nil

    func checkMachiHasYaku(hand13: [String], winTile: String) -> Bool {
        guard let human = humanPlayer else { return false }
        let zhuangfeng: Feng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        let menfeng: Feng = board.score.defen[0].0
        let normalized = Pai.normalize(winTile)
        let fulouTiles = human.shoupai.fulouTiles
        let context = HuleContext(
            zhuangfeng: zhuangfeng,
            menfeng: menfeng,
            zimo: false,  // メンゼンツモを役として数えない
            menqian: human.status.isMenqian,
            lizhi: human.status.isLizhi,
            daburi: human.status.isDaburi,
            yifa: false, qianggang: false, lingshang: false,
            haidi: false, hedi: false, tianhu: false, dihu: false,
            winTile: normalized,
            renpuFu: settings.renpuFu == .four ? 4 : 2,
            kuitanAri: settings.kuitanAri
        )
        let tiles = (hand13 + [normalized]).sorted()
        let result = Hule.getYaku(
            tiles: tiles,
            context: context,
            baopai: board.shan.wangpai.baopai.map { $0.label },
            libaopai: [],
            fulouTiles: fulouTiles
        )
        
        return !result.yaku.isEmpty
    }

    // MARK: - Hule Result
    var pendingHuleResults: [HuleResult] = []
    var huleResult: HuleResult? { pendingHuleResults.first }
    private var primaryRonWinner: Int? = nil  // 頭ハネ（最近位）勝者のindex
    var gameResult: SummaryResult? = nil
    var infoMessage: String? = nil
    var roundHistory: [RoundRecord] = []

    // アガリ局面情報を生成
    private func buildHuleContext(player: Int?, kind: HuleResult.Kind) -> HuleContext {
        let idx = player ?? 0
        let zhuangfeng: Feng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        let menfeng: Feng = board.score.defen[idx].0
        let winTileLabel: String = {
            switch kind {
            case .zimo: return Pai.normalize(status.zimo ?? "")
            case .rong: return Pai.normalize(status.dapai ?? "")
            default:    return ""
            }
        }()
        return HuleContext(
            zhuangfeng: zhuangfeng,
            menfeng: menfeng,
            zimo: kind == .zimo,
            menqian: players[idx].status.isMenqian,
            lizhi: players[idx].status.isLizhi,
            daburi: players[idx].status.isDaburi,
            yifa: players[idx].status.isYifa && settings.ippatsuAri,
            qianggang: kind == .rong && status.phase == .kagang,
            lingshang: kind == .zimo && status.isLingshang,
            haidi: kind == .zimo && board.shan.paishu == 0,
            hedi: kind == .rong && board.shan.paishu == 0,
            tianhu: kind == .zimo && players[idx].status.firstDapai == nil && idx == getTongjia(),
            dihu:   kind == .zimo && players[idx].status.firstDapai == nil && idx != getTongjia() && players.allSatisfy { $0.shoupai.fulou.isEmpty },
            winTile: winTileLabel,
            renpuFu: settings.renpuFu == .four ? 4 : 2,
            kuitanAri: settings.kuitanAri
        )
    }

    // アガリの結果を生成して返す
    private func buildHuleResult(playerIdx: Int, kind: HuleResult.Kind, context: HuleContext, honba: Int, lizhibang: Int, baseDefen: [(Feng, Int)]) -> HuleResult {
        let player = players[playerIdx]

        let winTile: Pai? = {
            switch kind {
            case .zimo:   return player.shoupai.zimo
            case .rong:   return status.dapai.map { Pai($0) }
            default: return nil
            }
        }()

        let tiles: [String] = {
            switch kind {
            case .zimo:   return player.shoupai.allLabels
            case .rong:   return player.shoupai.visibleLabels + [status.dapai ?? context.winTile]
            default: return []
            }
        }()

        let baopai = board.shan.wangpai.baopai.map { $0.label }
        let libaopai: [String] = {
            guard context.lizhi && settings.uradoraAri else { return [] }
            let limit = settings.kanUraAri ? baopai.count : 1
            return Array(board.shan.wangpai.libaopai.prefix(limit)).map { $0.label }
        }()
        let score = Hule.getYaku(tiles: tiles, context: context, baopai: baopai, libaopai: libaopai, fulouTiles: player.shoupai.fulouTiles)
        let hupai = score.yaku.map { (name: $0.name, fan: $0.fanshu) }
        let fu    = score.fu

        let dealerIdx = getTongjia()
        let loserIdx: Int? = kind == .rong ? status.player : nil
        let defenResult = Hule.computeDefen(
            fu: fu,
            yaku: score.yaku,
            zimo: kind == .zimo,
            winnerIdx: playerIdx,
            loserIdx: loserIdx,
            dealerIdx: dealerIdx,
            honba: honba,
            lizhibang: lizhibang,
            yakumanFukugouAri: settings.yakumanFukugouAri,
            doubleYakumanAri: settings.doubleYakumanAri,
            kazoeYakumanAri: settings.kazoeYakumanAri,
            kiriageMangan: settings.kiriageMangan,
            paoPlayerIdx: players[playerIdx].status.paoPlayerIdx
        )

        let afterScores: [(feng: Feng, points: Int)] = baseDefen
            .enumerated()
            .map { (i, kv) in (feng: kv.0, points: kv.1 + defenResult.fenpei[i]) }

        let displayLibaopai: [Pai] = {
            guard context.lizhi && settings.uradoraAri else { return [] }
            let limit = settings.kanUraAri ? board.shan.wangpai.baopai.count : 1
            return Array(board.shan.wangpai.libaopai.prefix(limit))
        }()

        let basePoints = defenResult.defen - honba * 300 - lizhibang * 1000
        return HuleResult(
            kind: kind,
            hulePlayer: playerIdx,
            bingpai: player.shoupai.bingpai.filter { !$0.hidden },
            fulou: player.shoupai.fulou,
            winTile: winTile,
            baopai: board.shan.wangpai.baopai,
            libaopai: displayLibaopai,
            hupai: hupai,
            fu: fu,
            totalFan: defenResult.effectiveFan,
            points: basePoints,
            scoreChanges: defenResult.fenpei,
            afterScores: afterScores,
            honba: honba,
            lizhibang: lizhibang
        )
    }
    
    //流局時の点数計算
    private static let yaochuLabels: Set<String> = [
        "m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"
    ]

    private func isNagashiMangan(playerIdx: Int) -> Bool {
        guard settings.nagashiManganAri else { return false }
        let he = players[playerIdx].he
        guard !he.qipai.isEmpty else { return false }
        guard he.calledPai.isEmpty else { return false }
        return he.qipai.allSatisfy { Game.yaochuLabels.contains(Pai.normalize($0.label)) }
    }

    private func computePingjuResult(kind: HuleResult.Kind = .pingju, declaredTenpaiIndices: [Int]? = nil) {
        // 流し満貫チェック（荒牌平局のみ）
        if kind == .pingju {
            let nagashiPlayers = players.indices.filter { isNagashiMangan(playerIdx: $0) }
            if !nagashiPlayers.isEmpty {
                computeNagashiManganResult(nagashiPlayers: Array(nagashiPlayers))
                return
            }
        }

        // テンパイ判定（ノーテン宣言あり時は宣言を優先）
        let tenpaiIndices = declaredTenpaiIndices ?? players.indices.filter { i in
            Hule.xiangting(players[i].shoupai.visibleLabels.map { Pai.normalize($0) }) == 0
        }
        // テンパイ料計算 (合計 3000 点)
        let n = tenpaiIndices.count
        var scoreChanges = [Int](repeating: 0, count: 4)
        if settings.notenBatsuAri && n > 0 && n < 4 {
            let gain = 3000 / n
            let loss = 3000 / (4 - n)
            for i in 0..<4 { scoreChanges[i] = tenpaiIndices.contains(i) ? gain : -loss }
        }
        let afterScores = board.score.defen.enumerated()
            .map { (i, kv) in (feng: kv.0, points: kv.1 + scoreChanges[i]) }

        pendingHuleResults.append(HuleResult(
            kind: kind,
            hulePlayer: nil,
            bingpai: [], fulou: [], winTile: nil,
            baopai: board.shan.wangpai.baopai,
            tenpaiPlayers: tenpaiIndices,
            scoreChanges: scoreChanges,
            afterScores: afterScores,
            honba: board.score.honba,
            lizhibang: board.score.lizhibang
        ))
    }

    private func computeNagashiManganResult(nagashiPlayers: [Int]) {
        let dealerIdx = getTongjia()
        var currentDefen = board.score.defen.map { $0.1 }

        for i in nagashiPlayers {
            var scoreChanges = [Int](repeating: 0, count: 4)
            if i == dealerIdx {
                for j in 0..<4 where j != i { scoreChanges[j] -= 4000 }
                scoreChanges[i] += 12000
            } else {
                scoreChanges[dealerIdx] -= 4000
                scoreChanges[i] += 8000
                for j in 0..<4 where j != i && j != dealerIdx { scoreChanges[j] -= 2000 }
            }

            let afterDefen = (0..<4).map { j in currentDefen[j] + scoreChanges[j] }
            let afterScores = board.score.defen.enumerated()
                .map { (j, kv) in (feng: kv.0, points: afterDefen[j]) }

            let points = i == dealerIdx ? 12000 : 8000
            let bingpai = players[i].shoupai.bingpai
            let fulou = players[i].shoupai.fulou.map { $0.filter { $0.label != "_" } }

            var result = HuleResult(
                kind: .nagashiMangan,
                hulePlayer: i,
                bingpai: bingpai,
                fulou: fulou,
                winTile: nil,
                baopai: board.shan.wangpai.baopai,
                hupai: [("流し満貫", 0)],
                fu: 0,
                totalFan: 5,
                points: points,
                scoreChanges: scoreChanges,
                afterScores: afterScores,
                honba: board.score.honba,
                lizhibang: board.score.lizhibang
            )
            result.nagashiManganPlayers = nagashiPlayers
            pendingHuleResults.append(result)

            for j in 0..<4 { currentDefen[j] += scoreChanges[j] }
        }
    }

    // 結果ダイアログを閉じて次の局へ進む
    func dismissHuleResult() {
        guard let result = pendingHuleResults.first else { return }

        let dealerIdx = getTongjia()

        // 点数変動を反映
        for i in 0..<4 {
            board.score.defen[i].1 += result.scoreChanges[i]
        }
        // 和了時は供託を清算（流局・途中流局・流し満貫は持ち越し）
        if result.kind != .pingju && result.kind != .kyuushu && result.kind != .suufon && result.kind != .suuchaRiichi && result.kind != .suukanSanyou && result.kind != .sanchahou && result.kind != .nagashiMangan {
            board.score.lizhibang = 0
        }

        pendingHuleResults.removeFirst()

        // まだ結果が残っている場合は次の結果を表示するだけ（次局処理はしない）
        guard pendingHuleResults.isEmpty else { return }

        // 全結果消化 → 次局処理
        let primaryWinner = primaryRonWinner
        primaryRonWinner = nil

        roundHistory.append(RoundRecord(
            jushu: board.score.round,
            honba: result.honba,
            kind: result.kind,
            hulePlayer: primaryWinner,
            dealerPlayer: dealerIdx,
            scoreChanges: result.scoreChanges,
            lizhiPlayers: []
        ))

        // 連荘 / 次局の判定
        if result.kind == .kyuushu || result.kind == .suufon || result.kind == .suuchaRiichi || result.kind == .suukanSanyou || result.kind == .sanchahou {
            // 途中流局 → renzhuFang に関わらず次局（本場+1）
            board.score.honba += 1
            board.score.nextRound()
        } else {
            let renzhu = shouldRenzhu(result: result, primaryWinner: primaryWinner, dealerIdx: dealerIdx)
            if renzhu {
                board.score.honba += 1
            } else if result.kind == .pingju {
                // 荒牌流局は非連荘でも本場+1
                board.score.honba += 1
                board.score.nextRound()
            } else {
                // 和了・流し満貫は非連荘で本場リセット
                board.score.honba = 0
                board.score.nextRound()
            }
        }

        // 終局チェック（nextRound後）
        if isGameOver() {
            gameResult = buildGameResult()
            return
        }

        //局開始
        qipai()
    }

    private func shouldRenzhu(result: HuleResult, primaryWinner: Int?, dealerIdx: Int) -> Bool {
        Game.renzhuDecision(result: result, primaryWinner: primaryWinner, dealerIdx: dealerIdx, renzhuFang: settings.renzhuFang)
    }

    static func renzhuDecision(result: HuleResult, primaryWinner: Int?, dealerIdx: Int, renzhuFang: GameSettings.RenzhuFang) -> Bool {
        let dealerTenpai = result.tenpaiPlayers.contains(dealerIdx)
        switch renzhuFang {
        case .none:
            return false
        case .hule:
            if result.kind == .pingju { return false }
            if result.kind == .nagashiMangan { return result.nagashiManganPlayers.contains(dealerIdx) }
            return primaryWinner == dealerIdx
        case .tenpai:
            if result.kind == .pingju { return dealerTenpai }
            if result.kind == .nagashiMangan { return result.nagashiManganPlayers.contains(dealerIdx) }
            return primaryWinner == dealerIdx
        case .noten:
            return true
        }
    }

    // 合計カン数が4に達しているか（5回目以降のカンは不可）
    var isGangFull: Bool {
        players.map { $0.shoupai.gangCount }.reduce(0, +) >= 4
    }

    // 同時ロン時の解決結果: 通常のロン・槍槓ロンの両方で共通利用する
    nonisolated enum DojiHuleResolution: Equatable {
        case winners([Int])
        case sanchahou
    }

    // 同時ロンの勝者を決定する（放銃者から見た巡り順優先、3人ロンかつ2人までの設定なら三家和）
    nonisolated static func resolveDojiHule(
        hulerIds: [Int], discarder: Int, dojiHuleMax: GameSettings.DojiHuleMax
    ) -> DojiHuleResolution {
        let sorted = hulerIds.sorted { ($0 - discarder + 4) % 4 < ($1 - discarder + 4) % 4 }
        let maxWinners: Int
        switch dojiHuleMax {
        case .atamahane: maxWinners = 1
        case .doubleRon: maxWinners = 2
        case .tripleRon: maxWinners = 3
        }
        if hulerIds.count == 3 && maxWinners == 2 {
            return .sanchahou
        }
        return .winners(Array(sorted.prefix(maxWinners)))
    }

    func isSuukanSanyou() -> Bool {
        guard settings.tochukuryokuAri else { return false }
        let gangCounts = players.map { $0.shoupai.gangCount }
        let total = gangCounts.reduce(0, +)
        guard total == 4 else { return false }
        return !gangCounts.contains(4)
    }

    func isSuuchaRiichi() -> Bool {
        guard settings.tochukuryokuAri else { return false }
        return players.allSatisfy { $0.status.isLizhi }
    }

    func isSuufon() -> Bool {
        guard settings.tochukuryokuAri else { return false }
        guard players.allSatisfy({ $0.status.firstDapai != nil }) else { return false }
        guard players.allSatisfy({ $0.shoupai.fulou.isEmpty }) else { return false }
        let windTiles: Set<String> = ["z1", "z2", "z3", "z4"]
        guard let first = players[0].status.firstDapai, windTiles.contains(first) else { return false }
        return players.allSatisfy { $0.status.firstDapai == first }
    }

    // 九種九牌が宣言可能か: 途中流局が有効、かつ誰もまだ副露していないこと（最初の一巡が乱れていないこと）
    func canDeclareKyuushu() -> Bool {
        guard settings.tochukuryokuAri else { return false }
        return players.allSatisfy { $0.shoupai.fulou.isEmpty }
    }

    private func isGameOver() -> Bool {
        if settings.tobiEndAri && board.score.defen.contains(where: { $0.1 < 0 }) { return true }
        switch settings.kyokuCount {
        case .ikkokuSen:
            return board.score.round == .東二局 || board.score.round == .終局
        case .tonpuSen:
            return board.score.round == .南一局 || board.score.round == .終局
        case .hanjouSen:
            return board.score.round == .終局
        }
    }

    private func buildGameResult() -> SummaryResult {
        let finalScores = board.score.defen.map { (feng: $0.0, points: $0.1) }

        // 返し点 = 配給原点 + 5000（供託オカの慣例）
        let kaeshi = settings.haikyuGenten + 5000
        // オカ = (返し点 - 配給原点) × 4 ÷ 1000
        let oka = Double((kaeshi - settings.haikyuGenten) * 4) / 1000.0
        // ウマ = settings の順位点（1着, 2着, 3着, 4着）
        let uma = [Double(settings.junkiten1),
                   Double(settings.junikitenRanks[0]),
                   Double(settings.junikitenRanks[1]),
                   Double(settings.junikitenRanks[2])]

        let sorted = finalScores.enumerated().sorted { $0.element.points > $1.element.points }

        var finalPoints = Array(repeating: 0.0, count: 4)
        for (rank, indexed) in sorted.enumerated() {
            let playerIdx = indexed.offset
            let score = indexed.element.points
            var base = Double(score - kaeshi) / 1000.0
            if settings.junkitenRounding { base = base.rounded() }
            finalPoints[playerIdx] = base + uma[rank] + (rank == 0 ? oka : 0.0)
        }

        return SummaryResult(
            roundHistory: roundHistory,
            finalScores: finalScores,
            finalPoints: finalPoints
        )
    }
}



// MARK: - RoundRecord
struct RoundRecord {
    var jushu: Score.Rounds
    var honba: Int
    var kind: HuleResult.Kind
    var hulePlayer: Int?        // 和了プレイヤー index（流局時は nil）
    var dealerPlayer: Int       // 親のプレイヤー index
    var scoreChanges: [Int]     // 各プレイヤーの得点変動 [4]
    var lizhiPlayers: Set<Int>  // リーチしたプレイヤー index の集合
}


// MARK: - GameStatus
enum GangdoraRevealTiming {
    case none
    case afterZimo   // 嶺上牌ツモ後（暗槓）
    case afterDapai  // 打牌後（明槓）
}

struct GameStatus {
    var phase: Actions = .kaiju
    var player: Int = 4
    var dapai: String? = nil
    var zimo: String? = nil
    var hulePlayer: Int? = nil
    var zhuangfeng: Feng = .東
    var gangdoraFlag: GangdoraRevealTiming = .none
    var menfengList: [Feng] = [.東, .南, .西, .北]
    var paishu: Int = 0
    var lastDapai: (player: Int, index: Int)? = nil
    var afterLizhiDiscards: [[String]] = [[],[],[],[]]
    var junDiscards: [[String]] = [[],[],[],[]]
    var riichiAnkanLevel: GameSettings.RiichiAnkanLevel = .noChangeWaiting
    var isLingshang: Bool = false
    var notenSengenAri: Bool = false
}

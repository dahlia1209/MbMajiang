//
//  GameState.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/02.
//

import Foundation



// MARK: - Game
@Observable
class Game {
    var board: Board
    var status: GameStatus
    var players: [Player]
    
    init(board: Board = Board(), status: GameStatus = GameStatus()) {
        self.board = board
        self.status = status
        self.players = []
    }
    
    func start() {
        kaiju()
    }
    
    // MARK: - Game Actions
    func kaiju() {
        status.action = .kaiju
        // idを付与してプレイヤーを初期化（Shoupai/HeはShanと同一参照）
        players = (0..<4).map { i in
            i == 0
            ? Player(id: i, shoupai: board.shan.shoupai[i], he: board.shan.he[i])
            : AIPlayer(id: i, shoupai: board.shan.shoupai[i], he: board.shan.he[i])
        }
        board.score.setQijia(qijia: Int.random(in: 0...3))
        advance()
    }

    func qipai() {
        status.action = .qipai
        status.dapai = nil
        status.zimo = nil
        status.selectedIdx = nil
        status.hulePlayer = nil
        status.zhuangfeng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        status.menfengList = board.score.defen.map { $0.0 }
        
        board.shan = Shan()
        for (i, player) in players.enumerated() {
            player.shoupai=board.shan.shoupai[i]
            player.he=board.shan.he[i]
            player.status=PlayerStatus()
        }
        
        advance()
    }
    
    func hule(player: Int?, kind: HuleResult.Kind) {
        status.hulePlayer = player
        let context = buildHuleContext(player: player, kind: kind)
        computeHuleResult(kind: kind, context: context)
        status.action = .hule
        // advance() は呼ばない（ダイアログ表示・ユーザー操作待ち）
    }

    func zimo() {
        guard !board.shan.shan.isEmpty else {
            hule(player: nil, kind: .pingju)
            return
        }
        status.action = .zimo
        let tile = board.shan.shan.removeLast()
        players[status.player].shoupai.zimo = tile
        status.zimo = tile.label
        advance()
    }
    
    func dapai() {
        status.action = .dapai
        let player = status.player
        let dapai=players[player].dapai()
        status.dapai = dapai.label
        
        // リーチ宣言打牌の後処理
        if players[player].status.isSelectingRiichi {
            players[player].status.isSelectingRiichi = false
            players[player].status.isLizhi = true
            players[player].status.isYifa = true
            // 1000点払い・供託に積む
            board.score.defen[player].1 -= 1000
            board.score.lizhibang += 1
        } else if players[player].status.isYifa {
            // リーチ後の最初の打牌でキャンセル（一発消滅）
            players[player].status.isYifa = false
        }
        
        players[player].status.lizhiCandidateIndices=[]
        players[player].status.isSelectingRiichi = false
        advance()
    }
    
    func peng(player fulouPlayer: Int) {
        status.action = .fulou
        guard let label = status.dapai else { return }
        var dapaiPai = players[status.player].he.qipai.removeLast(); dapaiPai.rotated = true
        let relPos = (fulouPlayer - status.player + 4) % 4
        var peng = [Pai(label), Pai(label)]
        peng.insert(dapaiPai, at: relPos-1)
        players[fulouPlayer].peng(peng)
        status.player = fulouPlayer
        advance()
    }
    
    func chi(player fulouPlayer: Int) {
        status.action = .fulou
        guard players[fulouPlayer].status.selectedChi.count == 2 else { return }
        let chiIndices = players[fulouPlayer].status.selectedChi
        
        var dapaiPai = players[status.player].he.qipai.removeLast(); dapaiPai.rotated = true
        let relPos = (fulouPlayer - status.player + 4) % 4
        var chi = [players[status.player].shoupai.bingpai[chiIndices[0]], players[status.player].shoupai.bingpai[chiIndices[1]]]
        chi.insert(dapaiPai, at: relPos-1)
        players[fulouPlayer].chi(chi)
        status.player = fulouPlayer
        advance()
    }

    
    
    // MARK: - Advance

    var humanPlayer: Player? { players.first(where: { $0.isHuman }) }

    // 全プレイヤーにcallbackを通知し、人間プレイヤーが準備完了次第ゲーム進行を処理
    private func advance() {

        players.forEach { $0.callback(status: self.status) }

        if needsHumanInput() {
            // 人間プレイヤーの入力待ち: Player.onActionReady 経由でゲームループを再開
            humanPlayer?.onActionReady = { [weak self] in
                DispatchQueue.main.async { self?.processPlayerActions() }
            }
        } else {
            DispatchQueue.main.async { [weak self] in self?.processPlayerActions() }
        }
    }

    // 人間プレイヤーが入力待ちか判定（フェーズも考慮）
    private func needsHumanInput() -> Bool {
        guard let human = humanPlayer else { return false }
        guard human.status.action == .none else { return false }
        // 打牌番（ツモ直後または副露直後）
        let isDapaiTurn = status.player == human.id && (status.action == .zimo || status.action == .fulou)
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
        switch status.action {
        case .kaiju:
            qipai()

        case .qipai:
            status.player = getTongjia()
            zimo()

        case .zimo:

            // 現在プレイヤー（player 0 または AI）の打牌
            if let actor = players.first(where: { $0.id == status.player && $0.status.action == .dapai }) {
                actor.status.action = .none
                dapai()
                return
            }
            // AIのツモアガリ
            if let winner = players.first(where: { $0.id == status.player && $0.status.action == .hule }) {
                winner.status.action = .none
                hule(player: winner.id, kind: .zimo)
                return
            }

        case .dapai:
            // ロンアガリ（人間・AI共通）
            if let winner = players.first(where: { $0.status.action == .hule }) {
                winner.status.action = .none
                hule(player: winner.id, kind: .rong)
                return
            }
            // ポン（副露）宣言
            if let fulouPlayer = players.first(where: { $0.status.action == .peng }) {
                peng(player: fulouPlayer.id)
                return
            }
            // チー（副露）宣言
            if let fulouPlayer = players.first(where: { $0.status.action == .chi }) {
                fulouPlayer.status.action = .none
                chi(player: fulouPlayer.id)
                return
            }
            // 次のツモへ
            guard let actor = players.first(where: { $0.status.action == .zimo }) else { return }
            actor.status.action = .none
            status.player = actor.id
            zimo()

        case .fulou:
            // 現在プレイヤー（player 0 または AI）の副露後打牌
            guard let actor = players.first(where: { $0.id == status.player && $0.status.action == .dapai }) else { return }
            actor.status.action = .none
            dapai()

        default:
            break
        }
    }
    
    // MARK: - Helpers
    
    func getTongjia() -> Int {
        return board.score.defen.firstIndex(where: { $0.0 == .東 })!
    }
    
    var canDapai: Bool {
        guard let human = humanPlayer else { return false }
        return status.player == human.id && (status.action == .zimo || status.action == .fulou)
    }
    



    // MARK: - Player Action Buttons
    // 人間プレイヤーの callback が設定した availableButtonActions をそのまま返す
    var playerActions: Set<PlayerButtonAction> {
        humanPlayer?.status.availableButtonActions ?? []
    }

    // アクションボタンが押された時の処理
    func handlePlayerAction(_ action: PlayerButtonAction) {
        guard let human = humanPlayer else { return }
        human.status.availableButtonActions = []
        switch action {
        case .cancel:
            // チー/ポン/ロン辞退後、自分のツモ番なら .zimo をセットしてから進める
            if status.action == .dapai && (status.player + 1) % 4 == human.id {
                human.status.action = .zimo
            }
            resolveHuman()
        case .zimo:
            human.status.action = .hule
            resolveHuman()
        case .rong:
            human.status.action = .hule
            resolveHuman()
        case .lizhi:
            human.status.isSelectingRiichi = true
            human.status.action = .lizhi
            // 牌タップ（selectDapai）が resolveHuman() を呼ぶまで保留継続
        case .peng:
            human.status.action = .peng
            resolveHuman()
        case .chi:
            human.status.isSelectingChi = true
        default:
            resolveHuman()
        }
    }
    
    // MARK: - Hule Result
    var huleResult: HuleResult? = nil
    var summaryResult: SummaryResult? = nil
    var roundHistory: [RoundRecord] = []

    // アガリ局面情報を生成
    private func buildHuleContext(player: Int?, kind: HuleResult.Kind) -> HuleContext {
        let idx = player ?? 0
        let zhuangfeng: Feng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        let menfeng: Feng = board.score.defen[idx].0
        let winTileLabel: String = {
            switch kind {
            case .zimo:   return Hule.normalize(status.zimo ?? "")
            case .rong:   return Hule.normalize(status.dapai ?? "")
            case .pingju: return ""
            }
        }()
        return HuleContext(
            zhuangfeng: zhuangfeng,
            menfeng: menfeng,
            zimo: kind == .zimo,
            menqian: players[idx].status.isMenqian,
            lizhi: players[idx].status.isLizhi,
            daburi: false,
            yifa: players[idx].status.isYifa,
            qianggang: false,
            lingshang: false,
            haidi: kind == .zimo && board.shan.shan.isEmpty,
            hedi: kind == .rong && board.shan.shan.isEmpty,
            tianhu: false,
            dihu: false,
            winTile: winTileLabel
        )
    }

    // 和了・流局時の結果を生成して huleResult にセット
    private func computeHuleResult(kind: HuleResult.Kind, context: HuleContext) {
        let idx = status.hulePlayer ?? 0
        let player = players[idx]

        let winTile: Pai? = {
            switch kind {
            case .zimo:   return player.shoupai.zimo
            case .rong:   return status.dapai.map { Pai($0) }
            case .pingju: return nil
            }
        }()

        let tiles: [String] = {
            switch kind {
            case .zimo:   return player.shoupai.allLabels
            case .rong:   return player.shoupai.visibleLabels + [context.winTile]
            case .pingju: return []
            }
        }()

        let fulouGroups = player.shoupai.fulou.map { $0.map { $0.label } }
        let score    = Hule.getYaku(tiles: tiles, context: context, fulouGroups: fulouGroups)
        let hupai    = score.yaku.map { (name: $0.name, fan: $0.fanshu) }
        let fu       = score.fu
        let totalFan = score.yaku.reduce(0) { $0 + $1.fanshu }

        // 点数計算
        let dealerIdx = getTongjia()
        let loserIdx: Int? = kind == .rong ? status.player : nil
        let defenResult = Hule.computeDefen(
            fu: fu,
            yaku: score.yaku,
            zimo: kind == .zimo,
            winnerIdx: idx,
            loserIdx: loserIdx,
            dealerIdx: dealerIdx,
            honba: board.score.honba,
            lizhibang: board.score.lizhibang
        )

        // 変動後の点数を計算（供託は和了時に清算）
        let afterScores: [(feng: Feng, points: Int)] = board.score.defen
            .enumerated()
            .map { (i, kv) in (feng: kv.0, points: kv.1 + defenResult.fenpei[i]) }

        let basePoints = defenResult.defen - board.score.honba * 300 - board.score.lizhibang * 1000
        huleResult = HuleResult(
            kind: kind,
            hulePlayer: kind == .pingju ? nil : idx,
            bingpai: player.shoupai.bingpai.filter { !$0.hidden },
            winTile: winTile,
            baopai: board.shan.wangpai.baopai,
            hupai: hupai,
            fu: fu,
            totalFan: totalFan,
            points: basePoints,
            scoreChanges: defenResult.fenpei,
            afterScores: afterScores,
            honba: board.score.honba,
            lizhibang: board.score.lizhibang
        )
    }

    // 結果ダイアログを閉じて次の局へ進む
    func dismissHuleResult() {
        guard let result = huleResult else { return }

        let dealerIdx = getTongjia()

        // 点数変動を反映
        for i in 0..<4 {
            board.score.defen[i].1 += result.scoreChanges[i]
        }
        // 和了時は供託を清算（流局は持ち越し）
        if result.kind != .pingju {
            board.score.lizhibang = 0
        }

        // 今局の記録を保存
        roundHistory.append(RoundRecord(
            jushu: board.score.round,
            honba: result.honba,
            kind: result.kind,
            hulePlayer: result.hulePlayer,
            dealerPlayer: dealerIdx,
            scoreChanges: result.scoreChanges,
            lizhiPlayers: []
        ))

        // 終局チェック（南四局終了後）
        if board.score.round == .終局 {
            summaryResult = buildSummaryResult()
            return
        }
        
        // 連荘 / 次局の判定
        if result.kind == .pingju || result.hulePlayer == dealerIdx {
            // 親の和了 or 流局 → 連荘（本場+1）
            board.score.honba += 1
        } else {
            // 子の和了 → 次局（風を回す・本場リセット）
            board.score.honba = 0
            board.score.nextRound()
        }

        huleResult = nil
        
        //局開始
        qipai()
    }

    private func buildSummaryResult() -> SummaryResult {
        let finalScores = board.score.defen.map { (feng: $0.0, points: $0.1) }

        // 最終順位に基づいてポイント計算（ウマ 20/10/-10/-20、オカ 20）
        let uma = [20.0, 10.0, -10.0, -20.0]
        let oka = 20.0
        let sorted = finalScores.enumerated().sorted { $0.element.points > $1.element.points }

        var finalPoints = Array(repeating: 0.0, count: 4)
        for (rank, indexed) in sorted.enumerated() {
            let playerIdx = indexed.offset
            let score = indexed.element.points
            let base = Double(score - 30000) / 1000.0
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
struct GameStatus {
    var action: Actions = .kaiju
    var player: Int = 4
    var dapai: String? = nil
    var selectedIdx: Int? = nil
    var zimo: String? = nil
    var hulePlayer: Int? = nil
    var zhuangfeng: Feng = .東
    var menfengList: [Feng] = [.東, .南, .西, .北]
}



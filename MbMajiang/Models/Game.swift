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
        status.phase = .kaiju
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
        status.phase = .qipai
        status.dapai = nil
        status.zimo = nil

        status.hulePlayer = nil
        status.zhuangfeng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        status.menfengList = board.score.defen.map { $0.0 }
        status.afterLizhiDiscards = [[],[],[],[]]
        status.junDiscards = [[],[],[],[]]
        
        board.shan = Shan()
        for (i, player) in players.enumerated() {
            player.shoupai=board.shan.shoupai[i]
            player.he=board.shan.he[i]
            player.status=PlayerStatus()
        }
        applyDebugHands()

        advance()
    }
    
    func hule(player: Int?, kind: HuleResult.Kind) {
          status.hulePlayer = player
          let context = buildHuleContext(player: player, kind: kind)
          computeHuleResult(kind: kind, context: context)
          status.phase = .hule
      }
    
    func pingju() {
          computePingjuResult()
          status.phase = .hule
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
                  pingju()
                  return
              }
        status.lastDapai = nil
        status.phase = .zimo
        status.junDiscards[status.player] = []
        infoMessage = nil
        processLizhiPayments()

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
            board.shan.wangpai.revealGangdora()
            status.gangdoraFlag = .none
        }
        
        status.phase = .zimo
        let tile = board.shan.wangpai.lingshang.removeLast()
        players[status.player].shoupai.zimo = tile
        status.zimo = tile.label
        status.paishu = board.shan.paishu
        advance()
    }
    
    func dapai() {
        status.phase = .dapai
        infoMessage = nil
        let player = status.player
        let dapai=players[player].dapai()
        status.dapai = dapai.label
        status.lastDapai = (player: player, index: players[player].he.qipai.count - 1)
        
        //カンドラめくり
        if status.gangdoraFlag == .afterDapai {
            board.shan.wangpai.revealGangdora()
            status.gangdoraFlag = .none
        }
        
        // リーチ宣言打牌の後処理
        if players[player].status.isSelectingRiichi {
            players[player].pendingLizhi()
        } else if players[player].status.isYifa {
            players[player].cancelYifa()
        }

        // リーチ後の打牌を記録
        if players[player].status.isLizhi {
            status.afterLizhiDiscards[player].append(Hule.normalize(dapai.label))
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

        advance()
    }
    
    func peng(player fulouPlayer: Int) {
        status.lastDapai = nil
        var dapaiPai = players[status.player].he.qipai.removeLast(); dapaiPai.rotated = true
        let relPos = (fulouPlayer - status.player + 4) % 4
        let tajia: Jia
        switch relPos {
        case 3: tajia = .xiajia
        case 2: tajia = .duimian
        case 1: tajia = .shangjia
        default: tajia = .zijia
        }
        players[fulouPlayer].peng(dapai: dapaiPai, tajia: tajia)
        status.player = fulouPlayer
        status.phase = .fulou
        status.junDiscards[fulouPlayer] = []
        processLizhiPayments()
        advance()
    }
    
    func minggang(player fulouPlayer: Int) {
        status.lastDapai = nil
        var dapaiPai = players[status.player].he.qipai.removeLast(); dapaiPai.rotated = true
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
        processLizhiPayments()
        advance()
    }
    
    func chi(player fulouPlayer: Int) {
        status.lastDapai = nil
        guard players[fulouPlayer].status.selectedChi.count == 2 else { return }
        var dapaiPai = players[status.player].he.qipai.removeLast(); dapaiPai.rotated = true
        let relPos = (fulouPlayer - status.player + 4) % 4
        let tajia: Jia
        switch relPos {
        case 3: tajia = .xiajia
        case 2: tajia = .duimian
        case 1: tajia = .shangjia
        default: tajia = .zijia
        }
        players[fulouPlayer].chi(dapai: dapaiPai, tajia: tajia)
        status.player = fulouPlayer
        status.phase = .fulou
        status.junDiscards[fulouPlayer] = []
        processLizhiPayments()
        advance()
    }
    
    func angang() {
        players[status.player].angang()
        status.gangdoraFlag = .afterZimo
        status.phase = .lingshang
        advance()
    }
    
    func kagang() {
        players[status.player].kagang()
        status.gangdoraFlag = .afterZimo
        status.phase = .lingshang
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
                angang()
                return
            }
            // 加槓
            if let actor = players.first(where: { $0.id == status.player && $0.status.decision == .kagang }) {
                actor.consumeDecision()
                kagang()
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
                hule(player: winner.id, kind: .zimo)
                return
            }

        case .dapai:
            // ロンアガリ
            if let winner = players.first(where: { $0.status.decision == .hule }) {
                winner.consumeDecision()
                hule(player: winner.id, kind: .rong)
                return
            }
            
            // カン宣言
            if let fulouPlayer = players.first(where: { $0.status.decision == .minggang }) {
                fulouPlayer.consumeDecision()
                minggang(player: fulouPlayer.id)
                return
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
            if let label = status.dapai {
                let normalized = Hule.normalize(label)
                for i in 0..<4 where i != status.player {
                    status.junDiscards[i].append(normalized)
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
            
        case .lingshang:
            lingshangzimo()

        default:
            break
        }
    }
    
    // MARK: - Helpers
    
    func getTongjia() -> Int {
        return board.score.defen.firstIndex(where: { $0.0 == .東 })!
    }
    
    var isSelectingDapai: Bool {
        guard let human = humanPlayer else { return false }
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
            if status.phase == .dapai && (status.player + 1) % 4 == human.id {
                human.status.decision = .zimo
            }
            resolveHuman()
        case .zimo:
            human.status.decision = .hule
            resolveHuman()
        case .rong:
            if human.isFuriten (
                afterLizhiDiscards: status.afterLizhiDiscards[human.id],
                junDiscards: status.junDiscards[human.id]
            ) {
                infoMessage = "フリテン"
            } else {
                human.status.decision = .hule
                resolveHuman()
            }
        case .lizhi:
            human.startRiichiSelection()
        case .peng:
            human.status.decision = .peng
            //TODO: 手牌３枚以上の牌選択
            resolveHuman()
        case .minggang:
            human.status.decision = .minggang
            resolveHuman()
        case .chi:
            human.startChiSelection()
        case .angang:
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
            if human.shoupai.kagangzi.count == 1 {
                human.prepareKagang(label: human.shoupai.kagangzi[0])
                resolveHuman()
            } else if human.shoupai.kagangzi.count > 1 {
                human.startKagangSelection()
            } else {
                human.status.decision = .zimo
                resolveHuman()
            }
            
        default:
            resolveHuman()
        }
    }
    
    // MARK: - Hule Result
    var huleResult: HuleResult? = nil
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
            case .zimo: return Hule.normalize(status.zimo ?? "")
            case .rong: return Hule.normalize(status.dapai ?? "")
            default:    return ""
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

    // アガリの結果を生成して huleResult にセット
    private func computeHuleResult(kind: HuleResult.Kind, context: HuleContext) {
        let idx = status.hulePlayer ?? 0
        let player = players[idx]

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
            case .rong:   return player.shoupai.visibleLabels + [context.winTile]
            default: return []
            }
        }()


        let baopai   = board.shan.wangpai.baopai.map { $0.label }
        let libaopai = context.lizhi
            ? Array(board.shan.wangpai.libaopai.prefix(baopai.count)).map { $0.label }
            : []
        let score = Hule.getYaku(tiles: tiles, context: context, baopai: baopai, libaopai: libaopai,fulouTiles: player.shoupai.fulouTiles)
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
            hulePlayer: idx,
            bingpai: player.shoupai.bingpai.filter { !$0.hidden },
            fulou: player.shoupai.fulou,
            winTile: winTile,
            baopai: board.shan.wangpai.baopai,
            libaopai: context.lizhi
                ? Array(board.shan.wangpai.libaopai.prefix(board.shan.wangpai.baopai.count))
                : [],
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
    
    //流局時の点数計算
    private func computePingjuResult() {
          // テンパイ判定
          let tenpaiIndices = players.indices.filter { i in
              Hule.xiangting(players[i].shoupai.visibleLabels.map { Hule.normalize($0) }) == 0
          }
          // テンパイ料計算 (合計 3000 点)
          let n = tenpaiIndices.count
          var scoreChanges = [Int](repeating: 0, count: 4)
          if n > 0 && n < 4 {
              let gain = 3000 / n
              let loss = 3000 / (4 - n)
              for i in 0..<4 { scoreChanges[i] = tenpaiIndices.contains(i) ? gain : -loss }
          }
          let afterScores = board.score.defen.enumerated()
              .map { (i, kv) in (feng: kv.0, points: kv.1 + scoreChanges[i]) }
                      
          huleResult = HuleResult(
              kind: .pingju,
              hulePlayer: nil,
              bingpai: [], fulou: [], winTile: nil,
              baopai: board.shan.wangpai.baopai,
              tenpaiPlayers: tenpaiIndices,
              scoreChanges: scoreChanges,
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

        // 連荘 / 次局の判定
        let dealerTenpai = result.tenpaiPlayers.contains(dealerIdx)
        if result.kind == .pingju && dealerTenpai {
            // 流局・親テンパイ → 連荘（本場+1）
            board.score.honba += 1
        } else if result.kind == .pingju && !dealerTenpai {
            // 流局・親ノーテン → 次局（風を回す・本場+1）
            board.score.honba += 1
            board.score.nextRound()
        } else if result.hulePlayer == dealerIdx {
            // 親の和了 → 連荘（本場+1）
            board.score.honba += 1
        } else {
            // 子の和了 → 次局（風を回す・本場リセット）
            board.score.honba = 0
            board.score.nextRound()
        }

        huleResult = nil

        // 終局チェック（nextRound後）
        if board.score.round == .終局 {
            gameResult = buildGameResult()
            return
        }

        //局開始
        qipai()
    }

    private func buildGameResult() -> SummaryResult {
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
}

//
//  GameState.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/02.
//

import Foundation

// MARK: - Shoupai
@Observable
class Shoupai{
    var bingpai:[Pai]=[]
    var zimo:Pai?
    
    init(bingpai: [Pai]=[], zimo: Pai? = nil) {
        self.bingpai = bingpai
        self.zimo = zimo
    }
    
    init(_ bingpai: [String] = [],_ zimo: String? = nil) {
        self.bingpai = bingpai.map { Pai($0) }
        self.zimo = zimo.map {  Pai($0) }
    }
    
    func takeZimo() -> Pai? {
        let value = self.zimo
        self.zimo = nil
        return value
    }
    
    func lipai() {
        bingpai = (bingpai + [zimo].compactMap { $0 }).filter { !$0.hidden }
        self.sortpai()
        zimo = nil
    }
    
    // bingpaiをスーツ・数字順に並び替え（zimoはそのまま）
    func sortpai() {
        bingpai.sort { Shoupai.sortKey($0.label) < Shoupai.sortKey($1.label) }
    }
    
    // 並び替えキー: 萬子→筒子→索子→字牌、赤牌(0)は4と5の間
    private static func sortKey(_ label: String) -> Int {
        guard label.count == 2 else { return 9999 }
        let suitBase: [Character: Int] = ["m": 0, "p": 100, "s": 200, "z": 300]
        let suit = label.first!
        let numChar = label.last!
        let numOrder = numChar == "0" ? 45 : (Int(String(numChar)) ?? 99) * 10
        return (suitBase[suit] ?? 400) + numOrder
    }

    // 表示中の bingpai ラベル（hidden 除外）
    var visibleLabels: [String] { bingpai.filter { !$0.hidden }.map { $0.label } }

    // ツモ和了判定用: bingpai + zimo の14枚ラベル
    var allLabels: [String] { visibleLabels + (zimo.map { [$0.label] } ?? []) }
}

// MARK: - Pai
struct Pai: Hashable {
    var label: String = "_"
    var alt: String = "_"
    var hidden: Bool = false
    var revealed:Bool=true
    
    init(_ code: String) {
        let value = paiTable[code]
        self.label = value != nil ? code : "_"
        self.alt = value ?? "_"
    }
    
}

// MARK: - Score
struct Score {
    var round: Rounds = .東一局
    var honba: Int = 0
    var lizhibang: Int = 0
    var defen: [(Feng, Int)] = [
        (.東, 25000),
        (.南, 25000),
        (.西, 25000),
        (.北, 25000)
    ]
    
    enum Rounds:String {
        case 東一局="東一局"
        case 東二局="東二局"
        case 東三局="東三局"
        case 東四局="東四局"
        case 南一局="南一局"
        case 南二局="南二局"
        case 南三局="南三局"
        case 南四局="南四局"
        case 終局="終局"
        
        var next: Rounds {
            switch self {
            case .東一局: return .東二局
            case .東二局: return .東三局
            case .東三局: return .東四局
            case .東四局: return .南一局
            case .南一局: return .南二局
            case .南二局: return .南三局
            case .南三局: return .南四局
            case .南四局, .終局: return .終局
            }
        }
    }
    
    mutating func setQijia(qijia: Int) {
        self.defen[qijia].0 = .東
        self.defen[(qijia+1) % 4].0 = .東.next
        self.defen[(qijia+2) % 4].0 = .東.next.next
        self.defen[(qijia+3) % 4].0 = .東.next.next.next
    }
    
    func rotationFeng()->[(Feng, Int)]{
        return self.defen.map { ($0.0.next, $0.1) }
    }
    
    mutating func nextRound(){
        self.round = self.round.next
        self.defen = self.rotationFeng()
    }
}

// MARK: - He
@Observable
class He{
    var qipai:[Pai]=[]
    
    init(qipai: [Pai]=[]) {
        self.qipai = qipai
    }
}

// MARK: - Wangpai
struct Wangpai{
    var baopai:[Pai]=[]
    var libaopai:[Pai]=[]
    var lingshang:[Pai]=[]
    
    init(baopai: [Pai]=[], libaopai: [Pai]=[], lingshang: [Pai]=[]) {
        self.baopai = baopai
        self.libaopai = libaopai
        self.lingshang = lingshang
    }
    
    init(wangpai:[Pai]){
        self.lingshang = Array(wangpai[0..<4])
        self.baopai = Array(wangpai[4..<5])
        self.libaopai = Array(wangpai[5..<14])
    }
    
}

// MARK: - Shan
struct Shan {
    var shan: [Pai]=[]
    var wangpai: Wangpai=Wangpai()
    var he: [He] = []
    var shoupai:[Shoupai] = []
    
    func makePai() -> [Pai] {
        var pais: [Pai] = []
        
        for suit in ["m", "p", "s"] {
            for num in 1...9 {
                for _ in 0..<4 {
                    pais.append(Pai("\(suit)\(num)"))
                }
            }
        }
        for num in 1...7 {
            for _ in 0..<4 {
                pais.append(Pai("z\(num)"))
            }
        }
        return pais
    }
    
    init(_ auto: Bool=true,shan: [Pai]=[], wangpai: Wangpai=Wangpai(), he: [He]=[], shoupai: [Shoupai]=[]) {
        if (auto) {
            let allPai = makePai()
            let shuffled = allPai.shuffled()
            
            self.wangpai = Wangpai(wangpai:Array(shuffled.prefix(14)))
            self.shoupai = (0..<4).map { i in
                let s = Shoupai(bingpai: Array(shuffled[(14 + i * 13)..<(14 + (i + 1) * 13)]))
                s.sortpai()
                return s
            }
            
            self.shan = Array(shuffled.dropFirst(66))
            self.he = (0..<4).map { _ in He() }
        }else{
            self.shan = shan
            self.wangpai = wangpai
            self.he = he
            self.shoupai = shoupai
        }
    }
    
}

// MARK: - Board
struct Board{
    var shan:Shan
    var score:Score
    
    init(shan: Shan=Shan(), score: Score=Score()) {
        self.shan = shan
        self.score = score
    }
}

// MARK: - Player
@Observable
class Player {
    var id: Int
    var shoupai: Shoupai
    var he: He
    var status: PlayerStatus = PlayerStatus()
    
    init(id: Int = 0, shoupai: Shoupai = Shoupai(bingpai: []), he: He = He()) {
        self.id = id
        self.shoupai = shoupai
        self.he = he
    }
    
    func callback(status: GameStatus) {
        switch status.action {
        case .kaiju:  onKaiju(status)
        case .qipai:  onQipai(status)
        case .zimo:   onZimo(status)
        case .dapai:  onDapai(status)
        default:      break
        }
    }

    func onKaiju(_ status: GameStatus) {
        self.status.action = .none
        self.status.availableButtonActions = []
    }

    func onQipai(_ status: GameStatus) {
        self.status.action = .none
        self.status.availableButtonActions = []
    }

    func onZimo(_ status: GameStatus) {
        if self.id == status.player {
            if self.status.isLizhi {
                // リーチ中: ツモ和了できる場合のみボタン表示、それ以外は自動ツモ切り
                let tiles = self.shoupai.allLabels
                if Hule.isHule(tiles) && hasYaku(tiles: tiles, isZimo: true, status: status) {
                    self.status.availableButtonActions = [.zimo, .cancel]
                } else {
                    // ボタンなし → processPlayerActions がツモ切りを実行
                    self.status.action = .dapai
                    self.status.selectedIdx = self.shoupai.bingpai.count  // ツモ牌のインデックス
                    self.status.availableButtonActions = []
                }
            } else {
                var buttons: Set<PlayerButtonAction> = []
                let tiles = self.shoupai.allLabels
                if Hule.isHule(tiles) && hasYaku(tiles: tiles, isZimo: true, status: status) {
                    buttons.insert(.zimo)
                    buttons.insert(.cancel)
                }
                // 門前テンパイなら .lizhi を表示
                if canDeclareRiichi() {
                    buttons.insert(.lizhi)
                    if buttons.isEmpty { buttons.insert(.cancel) }
                }
                self.status.availableButtonActions = buttons
            }
        } else {
            self.status.action = .none
            self.status.availableButtonActions = []
        }
    }

    func hasYaku(tiles: [String], isZimo: Bool, dapai: String? = nil, status: GameStatus) -> Bool {
        let menfeng = status.menfengList.indices.contains(id) ? status.menfengList[id] : .東
        let context = HuleContext(
            zhuangfeng: status.zhuangfeng,
            menfeng: menfeng,
            zimo: isZimo,
            menqian: true,
            lizhi: self.status.isLizhi,
            daburi: false,
            yifa: false,
            qianggang: false,
            lingshang: false,
            haidi: false,
            hedi: false,
            tianhu: false,
            dihu: false,
            winTile: isZimo ? Hule.normalize(self.shoupai.zimo?.label ?? "") : Hule.normalize(dapai ?? "")
        )
        return !Hule.getYaku(tiles: tiles, context: context).yaku.isEmpty
    }

    // テンパイかつ門前なら立直宣言可能（点数チェックは Game 側で行う）
    func canDeclareRiichi() -> Bool {
        // 14枚のうちいずれか1枚を切ってシャンテン0になる牌があればテンパイ
        let all = shoupai.allLabels.map { Hule.normalize($0) }
        guard all.count == 14 else { return false }
        return all.indices.contains { i in
            var rest = all
            rest.remove(at: i)
            return Hule.xiangting(rest) == 0
        }
    }

    func onDapai(_ status: GameStatus) {
        // 次の手番が自分なら .zimo をセット
        if (status.player + 1) % 4 == self.id {
            self.status.action = .zimo
        } else {
            self.status.action = .none
        }
        // ロン可能かチェック（自分以外の打牌のみ）
        if self.id != status.player,
           let label = status.dapai {
            let tiles = self.shoupai.visibleLabels + [label]
            if Hule.isHule(tiles) && hasYaku(tiles: tiles, isZimo: false, dapai: label, status: status) {
                self.status.availableButtonActions = [.rong, .cancel]
            } else {
                self.status.availableButtonActions = []
            }
        } else {
            self.status.availableButtonActions = []
        }
    }
}

// MARK: - AIPlayer
class AIPlayer: Player {
    // callback は Player のものを使う（on* メソッドをオーバーライドして挙動を変える）

    override func onKaiju(_ status: GameStatus) {
        self.status.action = .none
    }

    // qipai後の最初のツモ割り当てはprocessPlayerActions側で行うため、ここでは何もしない
    override func onQipai(_ status: GameStatus) {
        self.status.action = .none
    }

    override func onZimo(_ status: GameStatus) {
        if isCurrentId(status.player) {
            let tiles = self.shoupai.allLabels
            if Hule.isHule(tiles) && hasYaku(tiles: tiles, isZimo: true, status: status) {
                self.status.action = .hule  // ツモアガリ
            } else {
                selectDapai()
            }
        } else {
            self.status.action = .none
        }
    }

    override func onDapai(_ status: GameStatus) {
        // ロン判定を優先
        if !isCurrentId(status.player),
           let label = status.dapai {
            let tiles = self.shoupai.visibleLabels + [label]
            if Hule.isHule(tiles) && hasYaku(tiles: tiles, isZimo: false, dapai: label, status: status) {
                self.status.action = .hule
                return
            }
        }
        if isNextId(status.player) {
            self.status.action = .zimo
        } else {
            self.status.action = .none
        }
    }

    // シャンテン数が最小になる牌を選んで打牌する
    func selectDapai() {
        // bingpai(13枚) + zimo(1枚) の計14枚を正規化したラベル配列を作る
        let bingpai = shoupai.bingpai.filter { !$0.hidden }
        var allLabels = bingpai.map { Hule.normalize($0.label) }
        if let zimo = shoupai.zimo {
            allLabels.append(Hule.normalize(zimo.label))
        }

        // 14枚でない場合はツモ切りにフォールバック
        guard allLabels.count == 14 else {
            self.status.action = .dapai
            self.status.selectedIdx = shoupai.bingpai.count
            return
        }

        var bestIdx = shoupai.bingpai.count  // デフォルトはツモ切り
        var bestShanten = Int.max

        // 各牌を1枚ずつ除いた13枚でシャンテン数を計算
        for i in 0..<allLabels.count {
            var remaining = allLabels
            remaining.remove(at: i)
            let shanten = Hule.xiangting(remaining)
            if shanten < bestShanten {
                bestShanten = shanten
                bestIdx = i < bingpai.count ? i : shoupai.bingpai.count
            }
        }

        self.status.action = .dapai
        self.status.selectedIdx = bestIdx
    }
    
    func isCurrentId(_ currentPlayer: Int) -> Bool {
        return self.id == currentPlayer
    }
    
    func isNextId(_ currentPlayer: Int) -> Bool {
        return self.id == (currentPlayer + 1) % 4
    }
}

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
        advance()
    }
    
    func qipai() {
        status.action = .qipai
        board.score.setQijia(qijia: Int.random(in: 0...3))
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
        guard board.shan.shan.count > 0 else {
            // 牌山が尽きたら流局
            hule(player: nil, kind: .pingju)
            return
        }
        status.action = .zimo
        let zimo = popShan()
        players[status.player].shoupai.zimo = zimo
        status.zimo = zimo.label
        advance()
    }
    
    func dapai(_ index: Int = 99) {
        status.action = .dapai
        let player = status.player
        let bingpaiCount = players[player].shoupai.bingpai.count
        let isZimoDapai = index >= bingpaiCount
        
        let dapai: Pai
        if isZimoDapai {
            dapai = players[player].shoupai.zimo!
            players[player].he.qipai.append(dapai)
            players[player].shoupai.zimo?.hidden = true
        } else {
            dapai = players[player].shoupai.bingpai[index]
            players[player].he.qipai.append(dapai)
            players[player].shoupai.bingpai[index].hidden = true
        }
        status.dapai = dapai.label
        status.selectedIdx = index

        // リーチ宣言打牌の後処理
        if isSelectingRiichi {
            isSelectingRiichi = false
            players[player].status.isLizhi = true
            players[player].status.isYifa = true
            // 1000点払い・供託に積む
            board.score.defen[player].1 -= 1000
            board.score.lizhibang += 1
            // 新ドラ公開（王牌に未公開のドラ表示牌があれば追加）
//            revealNextDora()
        } else if players[player].status.isYifa {
            // リーチ後の最初の打牌でキャンセル（一発消滅）
            players[player].status.isYifa = false
        }

        advance()
    }

    private func revealNextDora() {
        let revealed = board.shan.wangpai.baopai.count
        // libaopai[0〜4] がリーチドラ表示牌（最大5枚）
        if revealed < board.shan.wangpai.libaopai.count {
            let next = board.shan.wangpai.libaopai[revealed - 1]
            board.shan.wangpai.baopai.append(next)
        }
    }
    
    // MARK: - Advance
    
    // 全プレイヤーにcallbackを通知し、非同期でゲーム進行を処理
    private func advance() {
        status.zhuangfeng = board.score.round.rawValue.hasPrefix("東") ? .東 : .南
        status.menfengList = board.score.defen.map { $0.0 }
        players.forEach { $0.callback(status: self.status) }
        DispatchQueue.main.async { [weak self] in
            self?.processPlayerActions()
        }
    }
    
    // プレイヤーのstatusを読み取り、次のゲームアクションを決定・実行
    private func processPlayerActions() {
        switch status.action {
        case .kaiju:
            // 開局後は起家決めへ
            qipai()
            
        case .qipai:
            // 東家（tongjia）から最初のツモ
            status.player = getTongjia()
            zimo()
            
        case .zimo:
            // プレイヤー0（人間）のリーチ中自動ツモ切り
            if status.player == 0,
               let p0 = players.first(where: { $0.id == 0 }),
               p0.status.action == .dapai {
                let idx = p0.status.selectedIdx ?? 99
                p0.status.action = .none
                dapai(idx)
                return
            }
            // プレイヤー0（人間）はUI操作待ち
            guard status.player != 0 else { return }
            // AIがツモアガリを選択した場合
            if let winner = players.first(where: { $0.id == status.player && $0.status.action == .hule }) {
                winner.status.action = .none
                hule(player: winner.id, kind: .zimo)
                return
            }
            // 現在プレイヤーのAIが打牌を決定済みか確認
            guard let actor = players.first(where: { $0.id == status.player && $0.status.action == .dapai }) else { return }
            let idx = actor.status.selectedIdx ?? 99
            actor.status.action = .none
            dapai(idx)

        case .dapai:
            // player 0 がボタン表示中なら操作を待つ
            if let player0 = players.first(where: { $0.id == 0 }),
               !player0.status.availableButtonActions.isEmpty {
                return
            }
            // AIがロンアガリを選択した場合（player 0 以外）
            if let winner = players.first(where: { $0.id != 0 && $0.status.action == .hule }) {
                winner.status.action = .none
                hule(player: winner.id, kind: .rong)
                return
            }
            // 次にツモするプレイヤーを探す
            guard let actor = players.first(where: { $0.status.action == .zimo }) else { return }
            actor.status.action = .none
            // 打牌したプレイヤーの手牌を整理してからツモへ
            players[status.player].shoupai.lipai()
            status.player = actor.id
            zimo()
            
        default:
            break
        }
    }
    
    // MARK: - Helpers
    
    func getTongjia() -> Int {
        return board.score.defen.firstIndex(where: { $0.0 == .東 })!
    }
    
    func popShan() -> Pai {
        return board.shan.shan.removeLast()
    }
    
    var canDapai: Bool {
        status.player == 0 && status.action == .zimo
    }
    
    func sortpai() {
        players[0].shoupai.sortpai()
    }
    
    // MARK: - Hule Result

    var huleResult: HuleResult? = nil
    var summaryResult: SummaryResult? = nil
    var roundHistory: [RoundRecord] = []

    // リーチ宣言牌を選択中か（true の間、手牌タップがリーチ打牌になる）
    var isSelectingRiichi: Bool = false

    // テンパイを維持できる打牌候補のインデックス（bingpai index + ツモ=bingpai.count）
    var lizhiCandidateIndices: Set<Int> {
        guard isSelectingRiichi else { return [] }
        let all = players[0].shoupai.allLabels.map { Hule.normalize($0) }
        guard all.count == 14 else { return [] }
        var result: Set<Int> = []
        let bingpaiCount = players[0].shoupai.bingpai.count
        for i in all.indices {
            var rest = all
            rest.remove(at: i)
            if Hule.xiangting(rest) == 0 {
                // bingpai 内の index はそのまま、ツモ牌は bingpaiCount として扱う
                result.insert(i < bingpaiCount ? i : bingpaiCount)
            }
        }
        return result
    }

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
            menqian: true,
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

        let score    = Hule.getYaku(tiles: tiles, context: context)
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
        print("defenResult",defenResult)

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

    // MARK: - Player Action Buttons

    // player 0 の callback が設定した availableButtonActions をそのまま返す
    var playerActions: Set<PlayerButtonAction> {
        guard let player0 = players.first(where: { $0.id == 0 }) else { return [] }
        return player0.status.availableButtonActions
    }

    // アクションボタンが押された時の処理
    func handlePlayerAction(_ action: PlayerButtonAction) {
        // ボタンを閉じる
        players.first(where: { $0.id == 0 })?.status.availableButtonActions = []
        switch action {
        case .cancel:
            processPlayerActions()  // キャンセル: 通常フローを再開
        case .zimo:
            hule(player: 0, kind: .zimo)
        case .rong:
            hule(player: 0, kind: .rong)
        case .lizhi:
            isSelectingRiichi = true
            // ボタンを非表示にして牌選択待ちへ（processPlayerActions は呼ばない）
        default:
            break
        }
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
        if result.kind == .pingju || result.hulePlayer == dealerIdx {
            // 親の和了 or 流局 → 連荘（本場+1）
            board.score.honba += 1
        } else {
            // 子の和了 → 次局（風を回す・本場リセット）
            board.score.honba = 0
            board.score.nextRound()
        }

        huleResult = nil
        isSelectingRiichi = false

        // 終局チェック（南四局終了後）
        if board.score.round == .終局 {
            summaryResult = buildSummaryResult()
            return
        }

        // 新しい牌山・手牌を生成してプレイヤーを再初期化
        board.shan = Shan()
        players = (0..<4).map { i in
            i == 0
            ? Player(id: i, shoupai: board.shan.shoupai[i], he: board.shan.he[i])
            : AIPlayer(id: i, shoupai: board.shan.shoupai[i], he: board.shan.he[i])
        }

        // 起家をランダムに変えずに qipai 状態から再開
        // processPlayerActions が getTongjia() でツモ開始プレイヤーを決める
        status.action = .qipai
        status.dapai = nil
        status.zimo = nil
        status.selectedIdx = nil
        status.hulePlayer = nil
        advance()
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

// MARK: - HuleResult
struct HuleResult {
    enum Kind { case zimo, rong, pingju }

    var kind: Kind
    var hulePlayer: Int?       // 和了プレイヤー index（流局時は nil）
    var bingpai: [Pai]         // 手牌（表示用・hidden除去済み）
    var winTile: Pai?          // 和了牌（ツモ牌 or ロン牌）
    var baopai: [Pai]          // ドラ表示牌
    var hupai: [(name: String, fan: Int)] = []  // 役一覧（未実装時は空）
    var fu: Int = 0
    var totalFan: Int = 0
    var points: Int = 0
    var scoreChanges: [Int]    // 各プレイヤーの得点変動 [0...3]（未実装時は 0）
    var afterScores: [(feng: Feng, points: Int)]  // 変動後の得点
    var honba: Int
    var lizhibang: Int
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

// MARK: - SummaryResult
struct SummaryResult {
    var roundHistory: [RoundRecord]
    var finalScores: [(feng: Feng, points: Int)]  // プレイヤー index 順
    var finalPoints: [Double]                            // ウマ・オカ込み最終ポイント
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

// MARK: - PlayerStatus
struct PlayerStatus {
    var action: Actions = .none
    var dapai: String? = nil
    var selectedIdx: Int? = nil
    var zimo: String? = nil
    var availableButtonActions: Set<PlayerButtonAction> = []
    var isLizhi: Bool = false
    var isYifa: Bool = false
}

// MARK: - Actions
enum Actions {
    case kaiju
    case dapai
    case hule
    case zimo
    case lizhi
    case fulou
    case qipai
    case none
    
}

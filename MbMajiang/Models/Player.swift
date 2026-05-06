//
//  Player.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation

// MARK: - Player
@Observable
class Player {
    var id: Int
    var shoupai: Shoupai
    var he: He
    var status: PlayerStatus = PlayerStatus()
    var isHuman: Bool { true }
    // Game.advance() がセット → アクション確定時に呼んでゲームループを再開
    var onActionReady: (() -> Void)?
    
    init(id: Int = 0, shoupai: Shoupai = Shoupai(bingpai: []), he: He = He()) {
        self.id = id
        self.shoupai = shoupai
        self.he = he
    }
    
    
    func callback(status: GameStatus) {
        switch status.phase {
        case .kaiju:  onKaiju(status)
        case .qipai:  onQipai(status)
        case .zimo:   onZimo(status)
        case .dapai:  onDapai(status)
        case .fulou:  onFulou(status)
        default:      break
        }
    }
    
    func onKaiju(_ status: GameStatus) {
        self.status.decision = .none
        self.status.availableButtonActions = []
    }
    
    func onQipai(_ status: GameStatus) {
        self.status = PlayerStatus()  
    }
    
    func onZimo(_ status: GameStatus) {
        if self.id == status.player {
            if self.status.isLizhi {
                // リーチ中: ツモ和了できる場合のみボタン表示、それ以外は自動ツモ切り
                let tiles = self.shoupai.allLabels
                if hasYaku(tiles: tiles, isZimo: true, status: status) {
                    self.status.availableButtonActions = [.zimo]
                }
                
                
                if self.status.availableButtonActions.isEmpty{
                    // ボタンなし → processPlayerActions がツモ切りを実行
                    self.status.decision = .dapai
                    self.status.selectedIdx = self.shoupai.bingpai.count
                    self.status.availableButtonActions = []
                }
                
                
            } else {
                var buttons: Set<PlayerButtonAction> = []
                let tiles = self.shoupai.allLabels
                if hasYaku(tiles: tiles, isZimo: true, status: status) {
                    buttons.insert(.zimo)
                    buttons.insert(.cancel)
                }
                // 門前テンパイなら .lizhi を表示
                if status.paishu >= 4 && canDeclareRiichi() {
                    self.status.lizhiCandidateIndices=lizhiCandidateIndices()
                    buttons.insert(.lizhi)
                    if buttons.isEmpty { buttons.insert(.cancel) }
                }
                self.status.availableButtonActions = buttons
            }
            
            //暗カン
            if status.paishu >= 1 && (!shoupai.gangzi.isEmpty) {
                self.status.availableButtonActions = [.angang]
            }
            //加カン
            if status.paishu >= 1 && (!shoupai.kagangzi.isEmpty) {
                self.status.availableButtonActions = [.kagang]
            }
            
        } else {
            self.status.decision = .none
            self.status.availableButtonActions = []
        }
    }
    
    
    func onDapai(_ status: GameStatus) {
        self.status.chiCandidates = []
        let isNextPlayer = (status.player + 1) % 4 == self.id

        guard self.id != status.player, let label = status.dapai else {
            self.status.availableButtonActions = []
            self.status.decision = .none
            return
        }

        var buttons: Set<PlayerButtonAction> = []

        // ロン判定
        let tiles = self.shoupai.visibleLabels + [label]
        if hasYaku(tiles: tiles, isZimo: false, dapai: label, status: status) {
            buttons.insert(.rong)
        }

        // ポン・カン判定（リーチ中・牌切れは不可）
        if !self.status.isLizhi && status.paishu >= 1 {
            let normalized = Hule.normalize(label)
            let matchCount = shoupai.bingpai.filter {
                !$0.hidden && Hule.normalize($0.label) == normalized
            }.count
            if matchCount >= 2 {
                buttons.insert(.peng)
            }
            if matchCount >= 3 {
                buttons.insert(.minggang)
            }
        }

        // チー判定（上家からのみ、リーチ中・牌切れは不可）
        if isNextPlayer && !self.status.isLizhi && status.paishu >= 1 {
            let candidates = findChiCandidates(dapai: label)
            if !candidates.isEmpty {
                buttons.insert(.chi)
                self.status.chiCandidates = candidates
            }
        }

        if !buttons.isEmpty {
            buttons.insert(.cancel)
            self.status.decision = .none  // ユーザー入力待ち（.zimoは辞退/チー確定後にセット）
        } else if isNextPlayer {
            self.status.decision = .zimo
        } else {
            self.status.decision = .none
        }
        self.status.availableButtonActions = buttons
    }
    
    /// 上家の打牌でチー可能な手牌インデックスペアを列挙する
    func findChiCandidates(dapai: String) -> [[Int]] {
        let norm = Hule.normalize(dapai)
        guard norm.count == 2, let suitChar = norm.first, suitChar != "z",
              let n = Int(String(norm.last!)) else { return [] }
        let suit = String(suitChar)
        
        // bingpai から指定ラベルの最初の visible インデックスを返す（excluding で除外可）
        func findIdx(_ label: String, excluding: [Int] = []) -> Int? {
            shoupai.bingpai.indices.first { i in
                !shoupai.bingpai[i].hidden &&
                !excluding.contains(i) &&
                Hule.normalize(shoupai.bingpai[i].label) == label
            }
        }
        
        var candidates: [[Int]] = []
        // [n-2, n-1, n]: 手牌に n-2 と n-1 が必要
        if n >= 3, let i1 = findIdx("\(suit)\(n-2)"),
           let i2 = findIdx("\(suit)\(n-1)", excluding: [i1]) {
            candidates.append([i1, i2])
        }
        // [n-1, n, n+1]: 手牌に n-1 と n+1 が必要
        if n >= 2 && n <= 8, let i1 = findIdx("\(suit)\(n-1)"),
           let i2 = findIdx("\(suit)\(n+1)") {
            candidates.append([i1, i2])
        }
        // [n, n+1, n+2]: 手牌に n+1 と n+2 が必要
        if n <= 7, let i1 = findIdx("\(suit)\(n+1)"),
           let i2 = findIdx("\(suit)\(n+2)", excluding: [i1]) {
            candidates.append([i1, i2])
        }
        return candidates
    }
    
    func onFulou(_ status: GameStatus) {
        self.status.availableButtonActions = []
        // 副露したプレイヤー（player 0）は UI タップで打牌するため action は none のまま
        self.status.decision = .none
    }
    
    func peng(dapai: Pai, tajia: Jia, startIdx: Int = 0) {
          let pengCandidate = shoupai.getPengCandidate(dapai.label).sorted(by: >)
          guard pengCandidate.count >= 2, startIdx + 1 < pengCandidate.count || pengCandidate.count == 2 else { return }
                                                           
          let selected = pengCandidate.count >= 3
              ? Array(pengCandidate[startIdx..<(startIdx + 2)])
              : pengCandidate
       
          var peng = selected.map { shoupai.bingpai.remove(at: $0) }
          switch tajia {
          case .shangjia: peng.insert(dapai, at: 0)
          case .duimian:  peng.insert(dapai, at: 1)
          default:        peng.append(dapai)
          }
          shoupai.fulou.insert(peng, at: 0)
          shoupai.lipai()
          status.isMenqian = false
      }
    
    func minggang(dapai:Pai,tajia:Jia){
        let minggangCandidate = shoupai.getMinggangCandidate(dapai.label).sorted(by: >)
        guard minggangCandidate.count == 3 else {return}
        var minggang = minggangCandidate.map{shoupai.bingpai.remove(at: $0)}
        switch tajia {
          case .shangjia: minggang.insert(dapai, at: 0)
          case .duimian:  minggang.insert(dapai, at: 1)
          default:        minggang.append(dapai)
          }
        shoupai.fulou.insert(minggang, at: 0)
        shoupai.lipai()
        status.isMenqian = false
    }
    
    func angang() {
        guard let selectedAngang = status.selectedAngang else { return }
        shoupai.lipai()
        let indices = shoupai.allLabels.indices.filter { shoupai.allLabels[$0] == selectedAngang }.sorted(by: >)
        guard indices.count == 4 else { return }
        var angang = indices.map { shoupai.bingpai.remove(at: $0) }
        angang[0].revealed = false
        angang[3].revealed = false
        shoupai.fulou.insert(angang, at: 0)
        shoupai.lipai()
        status.selectedAngang = nil
    }
    
    func kagang() {
        guard let selectedKagang = status.selectedKagang else { return }
        shoupai.lipai()
        guard let index = shoupai.allLabels.indices.firstIndex(where: { shoupai.allLabels[$0] == selectedKagang }) else { return }
        let kapai = shoupai.bingpai.remove(at: index)
        let normalized = Hule.normalize(selectedKagang)
        guard let fulouIndex = shoupai.fulou.indices.firstIndex(where: { i in shoupai.fulou[i].count == 3 && shoupai.fulou[i].allSatisfy { Hule.normalize($0.label) == normalized }
        }) else { return }
        shoupai.fulou[fulouIndex].insert(kapai, at: 0)
        shoupai.lipai()
        status.selectedKagang = nil
    }

    
    func chi(dapai: Pai, tajia: Jia = .shangjia) {
        let chiCandidate = status.selectedChi.sorted(by: >)
        guard chiCandidate.count == 2 else { return }
        var chi = chiCandidate.map { shoupai.bingpai.remove(at: $0) }
        switch tajia {
        case .shangjia: chi.insert(dapai, at: 0)
        case .duimian:  chi.insert(dapai, at: 1)
        default:        chi.append(dapai)
        }
        shoupai.fulou.insert(chi, at: 0)
        shoupai.lipai()
        status.isMenqian = false
        status.selectedChi = []
    }
    
    func dapai()->Pai{
        let bingpaiCount = shoupai.bingpai.count
        let isZimoDapai = status.selectedIdx ?? 99 >= bingpaiCount
        
        let dapai: Pai
        if isZimoDapai {
            dapai = shoupai.zimo!
            he.qipai.append(dapai)
            shoupai.zimo?.hidden = true
        } else {
            dapai = shoupai.bingpai[status.selectedIdx!]
            he.qipai.append(dapai)
            shoupai.bingpai[status.selectedIdx!].hidden = true
        }
        shoupai.lipai()
        
        return dapai
    }
    
    func consumeDecision() {
        status.decision = .none
    }
    
    func hasYaku(tiles: [String], isZimo: Bool, dapai: String? = nil, status: GameStatus) -> Bool {
        let menfeng = status.menfengList.indices.contains(id) ? status.menfengList[id] : .東
        let context = HuleContext(
            zhuangfeng: status.zhuangfeng,
            menfeng: menfeng,
            zimo: isZimo,
            menqian: self.status.isMenqian,
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
        return !Hule.getYaku(tiles: tiles, context: context, fulouTiles: shoupai.fulouTiles).yaku.isEmpty
    }
    
    func isFuriten(afterLizhiDiscards:[String]=[],junDiscards:[String]=[]) -> Bool {
        let currentTiles = shoupai.visibleLabels.map { Hule.normalize($0) }
        let target = Set(he.qipai.map { Hule.normalize($0.label) } + afterLizhiDiscards + junDiscards)
        //捨て牌にアガリ牌が含まれていないか確認
        return target.contains { label in
            let allTiles = currentTiles + [label]
            guard allTiles.count >= 2 && (allTiles.count - 2) % 3 == 0 else { return false }
            return !Hule.winningDecompositions(allTiles).isEmpty
        }
    }
    
    // テンパイかつ門前なら立直宣言可能（点数チェックは Game 側で行う）
    func canDeclareRiichi() -> Bool {
        guard status.isMenqian else { return false }
        let all = shoupai.allLabels.map { Hule.normalize($0) }
        return all.indices.contains { i in
            var rest = all
            rest.remove(at: i)
            let xiangting = Hule.xiangting(rest)
            return xiangting == 0
        }
    }
    
    func commitLizhi() {
        status.shouldRotateNextDapai = true
        status.isLizhi = true
        status.isYifa = true
        status.pendingLizhiPayment = false
    }
    
    func pendingLizhi() {
        status.shouldRotateNextDapai = true
        status.isSelectingRiichi = false
        status.lizhiCandidateIndices = []
        status.pendingLizhiPayment = true
    }

    func rotateLastDapai() {
        let lastIdx = he.qipai.count - 1
        guard lastIdx >= 0 else { return }
        he.qipai[lastIdx].rotated = true
    }

    func clearRotateFlag() {
        status.shouldRotateNextDapai = false
    }

    func cancelYifa() {
        status.isYifa = false
    }

    func startChiSelection() {
        status.isSelectingChi = true
    }

    func startRiichiSelection() {
        status.isSelectingRiichi = true
        status.decision = .lizhi
    }

    func startAngangSelection() {
        status.isSelectingAngang = true
    }
    
    func startKagangSelection() {
        status.isSelectingKagang = true
    }

    func prepareAngang(label: String) {
        status.selectedAngang = label
        status.decision = .angang
    }

    func prepareKagang(label: String) {
        status.selectedKagang = label
        status.decision = .kagang
    }

    func selectDapai(_ index: Int) {
        status.decision = .dapai
        status.selectedIdx = index
        onActionReady?()
        onActionReady = nil
    }
    
    func selectChi(_ index: Int) {
        status.selectedChi.append(index)
        guard status.selectedChi.count >= 2 else { return }

        status.isSelectingChi = false
        status.decision = .chi
        onActionReady?()
        onActionReady = nil
    }
    
    func selectAngang(_ index: Int) {
        let label = shoupai.allLabels[index]
        status.selectedAngang = label
        status.isSelectingAngang = false
        status.decision = .angang
        status.selectedIdx = index
        onActionReady?()
        onActionReady = nil
    }
    
    func selectKagang(_ index: Int) {
        let label = shoupai.allLabels[index]
        status.selectedKagang = label
        status.isSelectingKagang = false
        status.decision = .kagang
        status.selectedIdx = index
        onActionReady?()
        onActionReady = nil
    }
    
    func lizhiCandidateIndices()-> Set<Int> {
        let all = shoupai.allLabels.map { Hule.normalize($0) }
        guard all.count >= 2, (all.count - 2) % 3 == 0 else {return [] }
        var result: Set<Int> = []
        let bingpaiCount = shoupai.bingpai.count
        for i in all.indices {
            var rest = all
            rest.remove(at: i)
            if Hule.xiangting(rest) == 0 {
                result.insert(i < bingpaiCount ? i : bingpaiCount)
            }
        }
        return result
    }
    
}

// MARK: - AIPlayer
class AIPlayer: Player {
    override var isHuman: Bool { false }
    
    override func onKaiju(_ status: GameStatus) {
        self.status.decision = .none
    }
    
    // qipai後の最初のツモ割り当てはprocessPlayerActions側で行うため、ここでは何もしない
//    override func onQipai(_ status: GameStatus) {
//        self.status = PlayerStatus()
//    }
    
    override func onZimo(_ status: GameStatus) {
        if isCurrentId(status.player) {
            let tiles = self.shoupai.allLabels
            if hasYaku(tiles: tiles, isZimo: true, status: status) {
                self.status.decision = .hule  // ツモアガリ
            } else {
                selectDapai()
            }
        } else {
            self.status.decision = .none
        }
    }
    
    override func onDapai(_ status: GameStatus) {
        // ロン判定を優先
        if !isCurrentId(status.player),
           let label = status.dapai {
            let tiles = self.shoupai.visibleLabels + [label]
            if hasYaku(tiles: tiles, isZimo: false, dapai: label, status: status) &&
               !isFuriten(
                   afterLizhiDiscards: status.afterLizhiDiscards[self.id],
                   junDiscards: status.junDiscards[self.id]
               ) {
                self.status.decision = .hule
                return
            }
        }
        if isNextId(status.player) {
            self.status.decision = .zimo
        } else {
            self.status.decision = .none
        }
    }
    
    override func onFulou(_ status: GameStatus) {
        self.status.availableButtonActions = []
        if isCurrentId(status.player) {
            // 副露（ポン）後の打牌: シャンテン数最小の牌を選ぶ
            selectDapai()
        } else {
            self.status.decision = .none
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
            self.status.decision = .dapai
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
        
        self.status.decision = .dapai
        self.status.selectedIdx = bestIdx
    }
    
    func isCurrentId(_ currentPlayer: Int) -> Bool {
        return self.id == currentPlayer
    }
    
    func isNextId(_ currentPlayer: Int) -> Bool {
        return self.id == (currentPlayer + 1) % 4
    }
    
    
}


// MARK: - PlayerStatus
struct PlayerStatus {
    var decision: Actions = .none
    var dapai: String? = nil
    var selectedIdx: Int? = nil
    var zimo: String? = nil
    var availableButtonActions: Set<PlayerButtonAction> = []
    var isLizhi: Bool = false
    var isYifa: Bool = false
    var isMenqian: Bool = true
    var chiCandidates: [[Int]] = []
    var lizhiCandidateIndices: Set<Int>=[]
    var isSelectingRiichi:Bool = false
    var isSelectingChi:Bool = false
    var isSelectingAngang:Bool = false
    var isSelectingKagang:Bool = false
    var isSelectingDapai:Bool = false
    var selectedChi: [Int] = []
    var selectedAngang: String? = nil
    var selectedKagang: String? = nil
    var shouldRotateNextDapai: Bool = false
    var pendingLizhiPayment: Bool = false
}

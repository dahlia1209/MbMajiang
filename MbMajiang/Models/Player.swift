//
//  Player.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation

// MARK: - Perf logging
private func t() -> Double { Date().timeIntervalSince1970 * 1000 }
private func perfLog(_ label: String, _ start: Double, extra: String = "") {
    let dt = t() - start
    if dt >= 0.5 {
        print(String(format: "[PERF] %@ %.2fms%@", label, dt, extra.isEmpty ? "" : " | \(extra)"))
    }
}

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
            let _tOnZimo = t()
            self.status.forbiddenDapaiLabels = []
            if self.status.isLizhi {
                // リーチ中: ツモ和了できる場合のみボタン表示、それ以外は自動ツモ切り
                let tiles = self.shoupai.allLabels
                let _t1 = t(); let _ = hasYaku(tiles: tiles, isZimo: true, status: status)
                perfLog("p\(id).hasYaku(lizhi-zimo)", _t1)
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
                let _t2 = t()
                if hasYaku(tiles: tiles, isZimo: true, status: status) {
                    buttons.insert(.zimo)
                    buttons.insert(.cancel)
                }
                perfLog("p\(id).hasYaku(zimo)", _t2)
                // 門前テンパイなら .lizhi を表示
                if status.paishu >= 4 {
                    let _t3 = t()
                    let canRiichi = canDeclareRiichi()
                    perfLog("p\(id).canDeclareRiichi", _t3, extra: "-> \(canRiichi)")
                    if canRiichi {
                        let _t4 = t()
                        self.status.lizhiCandidateIndices = lizhiCandidateIndices()
                        perfLog("p\(id).lizhiCandidateIndices", _t4)
                        buttons.insert(.lizhi)
                        if buttons.isEmpty { buttons.insert(.cancel) }
                    }
                }
                // 九種九牌
                if isKyuushuCondition() {
                    buttons.insert(.kyuushu)
                }
                self.status.availableButtonActions = buttons
            }
            perfLog("p\(id).onZimo total", _tOnZimo, extra: "turn=\(he.qipai.count)")
            
            //暗カン
            if status.paishu >= 1 && (!shoupai.gangzi.isEmpty) {
                self.status.availableButtonActions = [.angang]
            }
            //加カン
            if status.paishu >= 1 && (!shoupai.kagangzi.isEmpty) {
                self.status.availableButtonActions = [.kagang]
            }

            self.status.isFirstDraw = false

        } else {
            self.status.decision = .none
            self.status.availableButtonActions = []
        }
    }
    
    
    func onDapai(_ status: GameStatus) {
        self.status.chiCandidates = []
        self.status.pengCandidates = []
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
            let normalized = Pai.normalize(label)
            let matchCount = shoupai.bingpai.filter {
                !$0.hidden && Pai.normalize($0.label) == normalized
            }.count
            if matchCount >= 2 {
                let candidates = findPengCandidates(dapai: label)
                if !candidates.isEmpty {
                    buttons.insert(.peng)
                    self.status.pengCandidates = candidates
                }
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
    
    /// 上家の打牌でチー可能な手牌インデックスペアを全列挙する
    func findChiCandidates(dapai: String) -> [[Int]] {
        let norm = Pai.normalize(dapai)
        guard norm.count == 2, let suitChar = norm.first, suitChar != "z",
              let n = Int(String(norm.last!)) else { return [] }
        let suit = String(suitChar)

        func findAllIdx(_ label: String) -> [Int] {
            shoupai.bingpai.indices.filter {
                !shoupai.bingpai[$0].hidden &&
                shoupai.bingpai[$0].normalized == label
            }
        }

        var candidates: [[Int]] = []
        // [n-2, n-1, n]
        if n >= 3 {
            for i1 in findAllIdx("\(suit)\(n-2)") {
                for i2 in findAllIdx("\(suit)\(n-1)") where i2 != i1 {
                    candidates.append([i1, i2])
                }
            }
        }
        // [n-1, n, n+1]
        if n >= 2 && n <= 8 {
            for i1 in findAllIdx("\(suit)\(n-1)") {
                for i2 in findAllIdx("\(suit)\(n+1)") {
                    candidates.append([i1, i2])
                }
            }
        }
        // [n, n+1, n+2]
        if n <= 7 {
            for i1 in findAllIdx("\(suit)\(n+1)") {
                for i2 in findAllIdx("\(suit)\(n+2)") where i2 != i1 {
                    candidates.append([i1, i2])
                }
            }
        }
        return candidates
    }
    
    func findPengCandidates(dapai: String)-> [[Int]] {
        let candidates = shoupai.getPengCandidate(dapai)
        return candidates.indices.flatMap { i in
            candidates[(i + 1)...].indices.map { j in [candidates[i], candidates[j]] }
        }
    }
    
    
    func onFulou(_ status: GameStatus) {
        self.status.availableButtonActions = []
        // 副露したプレイヤー（player 0）は UI タップで打牌するため action は none のまま
        self.status.decision = .none
    }
    
    func peng(dapai: Pai, tajia: Jia,
              kuichikaeLevel: GameSettings.KuichikaeLevel = .none) {
          let selected: [Int]
          if !status.selectedPengIndices.isEmpty {
              selected = status.selectedPengIndices.sorted(by: >)
          } else {
              let candidates = shoupai.getPengCandidate(dapai.label).sorted(by: >)
              guard candidates.count >= 2 else { return }
              selected = Array(candidates.prefix(2))
          }

          var peng = selected.map { shoupai.bingpai.remove(at: $0) }
          switch tajia {
          case .shangjia: peng.insert(dapai, at: 0)
          case .duimian:  peng.insert(dapai, at: 1)
          default:        peng.append(dapai)
          }
          shoupai.fulou.insert(peng, at: 0)
          shoupai.lipai()
          status.isMenqian = false
          status.selectedPengIndices = []
          status.forbiddenDapaiLabels = kuichikaeLabels(fulou: shoupai.fulou[0], isChi: false, level: kuichikaeLevel)
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
        let norm = Pai.normalize(selectedAngang)
        let normalized = shoupai.normalizedAllLabels
        let indices = normalized.indices.filter { normalized[$0] == norm }.sorted(by: >)
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
        let normalized = Pai.normalize(selectedKagang)
        guard let fulouIndex = shoupai.fulou.indices.firstIndex(where: { i in shoupai.fulou[i].count == 3 && shoupai.fulou[i].allSatisfy { $0.normalized == normalized }
        }) else { return }
        shoupai.fulou[fulouIndex].insert(kapai, at: 0)
        shoupai.lipai()
        status.selectedKagang = nil
    }

    
    func chi(dapai: Pai, tajia: Jia = .shangjia,
             kuichikaeLevel: GameSettings.KuichikaeLevel = .none) {
        let chiCandidate = status.selectedChiIndices.sorted(by: >)
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
        status.selectedChiIndices = []
        status.forbiddenDapaiLabels = kuichikaeLabels(fulou: shoupai.fulou[0], isChi: true, level: kuichikaeLevel)
    }

    private func kuichikaeLabels(fulou: [Pai], isChi: Bool, level: GameSettings.KuichikaeLevel) -> Set<String> {
        guard level != .genmotsu else { return [] }
        guard let rotated = fulou.first(where: { $0.rotated }) else { return [] }
        let genmotsu = rotated.normalized
        var forbidden: Set<String> = [genmotsu]

        if isChi && level == .none {
            let norms = fulou.map { $0.normalized }
            guard let suit = norms.first?.first.map(String.init), suit != "z" else { return forbidden }
            let nums = norms.compactMap { n -> Int? in
                guard n.count == 2 else { return nil }
                return Int(String(n.last!))
            }.sorted()
            guard nums.count == 3,
                  let rotNum = Int(String(genmotsu.last!)) else { return forbidden }
            let lo = nums[0]; let hi = nums[2]
            if rotNum == lo, hi + 1 <= 9 { forbidden.insert("\(suit)\(hi + 1)") }
            if rotNum == hi, lo - 1 >= 1  { forbidden.insert("\(suit)\(lo - 1)") }
        }
        return forbidden
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

        if status.firstDapai == nil { status.firstDapai = Pai.normalize(dapai.label) }

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
            winTile: isZimo ? self.shoupai.zimo?.normalized ?? "" : Pai.normalize(dapai ?? "")
        )
        return !Hule.getYaku(tiles: tiles, context: context, fulouTiles: shoupai.fulouTiles).yaku.isEmpty
    }
    
    func isFuriten(afterLizhiDiscards:[String]=[],junDiscards:[String]=[]) -> Bool {
        let _t0 = t()
        let currentTiles = shoupai.visibleLabels.map { Pai.normalize($0) }
        let target = Set(he.qipai.map { $0.normalized } + afterLizhiDiscards + junDiscards)
        //捨て牌にアガリ牌が含まれていないか確認
        let result = target.contains { label in
            let allTiles = currentTiles + [label]
            guard allTiles.count >= 2 && (allTiles.count - 2) % 3 == 0 else { return false }
            return !Hule.winningDecompositions(allTiles).isEmpty
        }
        perfLog("p\(id).isFuriten", _t0, extra: "discard=\(he.qipai.count) unique=\(target.count) -> \(result)")
        return result
    }
    
    func isKyuushuCondition() -> Bool {
        guard status.isFirstDraw else { return false }
        let yaojiu: Set<String> = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
        return yaojiu.filter { shoupai.normalizedAllLabels.contains($0) }.count >= 9
    }

    // テンパイかつ門前なら立直宣言可能（点数チェックは Game 側で行う）
    func canDeclareRiichi() -> Bool {
        guard status.isMenqian else { return false }
        let all = shoupai.allLabels.map { Pai.normalize($0) }
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

    func startPengSelection() {
        status.isSelectingPeng = true
    }

    func selectPeng(_ index: Int) {
        status.selectedPengIndices.append(index)
        guard status.selectedPengIndices.count >= 2 else { return }
        status.isSelectingPeng = false
        status.decision = .peng
        onActionReady?()
        onActionReady = nil
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
        status.selectedChiIndices.append(index)
        guard status.selectedChiIndices.count >= 2 else { return }

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
        let all = shoupai.allLabels.map { Pai.normalize($0) }
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
            // ツモ和了判定
            if hasYaku(tiles: tiles, isZimo: true, status: status) {
                self.status.decision = .hule
                return
            }
            // リーチ中はツモ切り（手牌変更不可）
            if self.status.isLizhi {
                self.status.decision = .dapai
                self.status.selectedIdx = shoupai.bingpai.count
                return
            }
            // 門前テンパイならリーチ宣言
            if status.paishu >= 4 && canDeclareRiichi() {
                self.status.isSelectingRiichi = true
                selectDapai()
                return
            }
            // 通常打牌
            selectDapai()
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
        let _t0 = t()
        // bingpai(13枚) + zimo(1枚) の計14枚を正規化したラベル配列を作る
        let bingpai = shoupai.bingpai.filter { !$0.hidden }
        var allLabels = bingpai.map { $0.normalized }
        if let zimo = shoupai.zimo {
            allLabels.append(zimo.normalized)
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
        perfLog("p\(id).selectDapai", _t0, extra: "shanten=\(bestShanten) turn=\(he.qipai.count)")
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
    var pengCandidates: [[Int]] = []
    var lizhiCandidateIndices: Set<Int>=[]
    var isSelectingRiichi:Bool = false
    var isSelectingChi:Bool = false
    var isSelectingAngang:Bool = false
    var isSelectingKagang:Bool = false
    var isSelectingDapai:Bool = false
    var isSelectingPeng:Bool = false
    var selectedPengIndices: [Int] = []
    var selectedChiIndices: [Int] = []
    var selectedAngang: String? = nil
    var selectedKagang: String? = nil
    var shouldRotateNextDapai: Bool = false
    var pendingLizhiPayment: Bool = false
    var forbiddenDapaiLabels: Set<String> = []
    var isFirstDraw: Bool = true
    var firstDapai: String? = nil
}

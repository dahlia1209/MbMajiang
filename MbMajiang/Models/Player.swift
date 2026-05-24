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
        case .kagang: onKagang(status)
        case .pingju: onPingju(status)
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
            self.status.forbiddenDapaiLabels = []
            var buttons: Set<PlayerButtonAction> = []

            if self.status.isLizhi {
                // リーチ中: ツモ和了できる場合のみボタン表示
                let tiles = self.shoupai.allLabels
                if hasYaku(tiles: tiles, isZimo: true, status: status) {
                    buttons.insert(.zimo)
                }
            } else {
                let tiles = self.shoupai.allLabels
                if hasYaku(tiles: tiles, isZimo: true, status: status) {
                    buttons.insert(.zimo)
                    buttons.insert(.cancel)
                }
                // 門前テンパイなら .lizhi を表示
                if status.paishu >= 4 && canDeclareRiichi() {
                    self.status.lizhiCandidateIndices = lizhiCandidateIndices()
                    buttons.insert(.lizhi)
                }
                // 九種九牌
                if isKyuushuCondition() {
                    buttons.insert(.kyuushu)
                }
            }

            // 暗カン（リーチ中はriichiAnkanLevelでフィルタ）
            let angangCandidates: Set<String>
            if self.status.isLizhi {
                angangCandidates = Set(Hule.validAngangLabels(
                    bingpaiLabels: shoupai.visibleLabels,
                    fulouTiles: shoupai.fulouTiles,
                    gangziCandidates: shoupai.gangzi,
                    level: status.riichiAnkanLevel
                ))
            } else {
                angangCandidates = Set(shoupai.gangzi)
            }
            self.status.validAngangLabels = angangCandidates
            if status.paishu >= 1 && !angangCandidates.isEmpty {
                buttons.insert(.angang)
            }
            // 加カン
            if status.paishu >= 1 && !shoupai.kagangzi.isEmpty {
                buttons.insert(.kagang)
            }

            self.status.availableButtonActions = buttons

            // リーチ中でボタンなし → 自動ツモ切り
            if self.status.isLizhi && buttons.isEmpty {
                self.status.decision = .dapai
                self.status.selectedIdx = self.shoupai.bingpai.count
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

    func onKagang(_ status: GameStatus) {
        guard self.id != status.player, let label = status.dapai else {
            self.status.availableButtonActions = []
            self.status.decision = .none
            return
        }
        let tiles = self.shoupai.visibleLabels + [label]
        if hasYaku(tiles: tiles, isZimo: false, dapai: label, status: status) {
            self.status.availableButtonActions = [.rong, .cancel]
            self.status.decision = .none
        } else {
            self.status.availableButtonActions = []
            self.status.decision = .none
        }
    }

    func onPingju(_ status: GameStatus) {
        guard status.notenSengenAri && !self.status.isLizhi else {
            self.status.availableButtonActions = []
            self.status.decision = .pingju
            return
        }
        let isTenpai = Hule.xiangting(shoupai.visibleLabels.map { Pai.normalize($0) }) == 0
        if isTenpai {
            self.status.availableButtonActions = [.pingju, .noten]
            self.status.decision = .none
        } else {
            self.status.availableButtonActions = []
            self.status.decision = .pingju
        }
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
            qianggang: !isZimo && status.phase == .kagang,
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
        let currentTiles = shoupai.visibleLabels.map { Pai.normalize($0) }
        let target = Set(he.qipai.map { $0.normalized } + afterLizhiDiscards + junDiscards)
        //捨て牌にアガリ牌が含まれていないか確認
        return target.contains { label in
            let allTiles = currentTiles + [label]
            guard allTiles.count >= 2 && (allTiles.count - 2) % 3 == 0 else { return false }
            return !Hule.winningDecompositions(allTiles).isEmpty
        }
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
    var cpuLevel: GameSettings.CpuLevel = .level1
    var getRemainingCounts: (() -> [String: Int])?
    /// リーチ中の相手がいればプレイヤーごとの現物セット配列を返す、いなければ nil
    var getRiichiGenbutsu: (() -> [Set<String>]?)?
    
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
    
    override func onKagang(_ status: GameStatus) {
        guard !isCurrentId(status.player), let label = status.dapai else {
            self.status.decision = .none
            return
        }
        let tiles = self.shoupai.visibleLabels + [label]
        if hasYaku(tiles: tiles, isZimo: false, dapai: label, status: status) &&
           !isFuriten(
               afterLizhiDiscards: status.afterLizhiDiscards[self.id],
               junDiscards: status.junDiscards[self.id]
           ) {
            self.status.decision = .hule
        } else {
            self.status.decision = .none
        }
    }

    override func onPingju(_ status: GameStatus) {
        self.status.decision = .pingju
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
    
    // シャンテン数最小化（Level 1）または有効牌受け入れ枚数最大化（Level 2）で打牌を選ぶ
    func selectDapai() {
        let bingpai = shoupai.bingpai.filter { !$0.hidden }
        var allLabels = bingpai.map { $0.normalized }
        if let zimo = shoupai.zimo {
            allLabels.append(zimo.normalized)
        }

        guard allLabels.count == 14 else {
            self.status.decision = .dapai
            self.status.selectedIdx = shoupai.bingpai.count
            return
        }

        // Level 2: 降り判断（リーチ相手がいてシャンテン2以上なら安全牌優先）
        if cpuLevel == .level2, let genbutsuList = getRiichiGenbutsu?() {
            if let safeIdx = findSafeDiscard(allLabels: allLabels, bingpaiCount: bingpai.count, genbutsuList: genbutsuList) {
                self.status.decision = .dapai
                self.status.selectedIdx = safeIdx
                return
            }
        }

        let remaining: [String: Int] = cpuLevel == .level2 ? (getRemainingCounts?() ?? [:]) : [:]

        var bestIdx = shoupai.bingpai.count
        var bestShanten = Int.max
        var bestAcceptance = -1

        for i in 0..<allLabels.count {
            var hand13 = allLabels
            hand13.remove(at: i)
            let shanten = Hule.xiangting(hand13)
            let acceptance = remaining.isEmpty ? 0 : effectiveTileAcceptance(hand13: hand13, currentShanten: shanten, remainingCounts: remaining)

            if shanten < bestShanten || (shanten == bestShanten && acceptance > bestAcceptance) {
                bestShanten = shanten
                bestAcceptance = acceptance
                bestIdx = i < bingpai.count ? i : shoupai.bingpai.count
            }
        }

        self.status.decision = .dapai
        self.status.selectedIdx = bestIdx
    }

    /// 降りモード: シャンテン2以上のときに安全牌インデックスを返す（テンパイ/1シャンテンはnil→押し）
    /// 優先順位: 1.全員現物（積集合）2.誰かの現物（和集合）3.字牌 4.該当なし→nil
    private func findSafeDiscard(allLabels: [String], bingpaiCount: Int, genbutsuList: [Set<String>]) -> Int? {
        var bestShanten = Int.max
        for i in 0..<allLabels.count {
            var hand13 = allLabels; hand13.remove(at: i)
            bestShanten = min(bestShanten, Hule.xiangting(hand13))
        }
        guard bestShanten >= 2 else { return nil }

        func mapIdx(_ i: Int) -> Int { i < bingpaiCount ? i : bingpaiCount }

        // 安全牌候補セットの中でシャンテン損が最小のインデックスを探す
        func bestIdx(in safeSet: Set<String>) -> Int? {
            var best: Int? = nil
            var bestS = Int.min
            for i in 0..<allLabels.count where safeSet.contains(allLabels[i]) {
                var hand13 = allLabels; hand13.remove(at: i)
                let s = Hule.xiangting(hand13)
                if s > bestS { bestS = s; best = mapIdx(i) }
            }
            return best
        }

        // 1. 全員現物（積集合）
        let allSafe = genbutsuList.dropFirst().reduce(genbutsuList[0]) { $0.intersection($1) }
        if let idx = bestIdx(in: allSafe) { return idx }

        // 2. 誰かの現物（和集合）
        let anySafe = genbutsuList.reduce(Set<String>()) { $0.union($1) }
        if let idx = bestIdx(in: anySafe) { return idx }

        // 3. 字牌
        let jihai = Set(allLabels.filter { $0.hasPrefix("z") })
        if let idx = bestIdx(in: jihai) { return idx }

        return nil
    }

    // hand13（13枚・正規化済み）に対して有効牌の残り総枚数を返す
    // 各牌種について「加牌して最適打牌すればシャンテンが下がるか」を評価する
    private func effectiveTileAcceptance(hand13: [String], currentShanten: Int, remainingCounts: [String: Int]) -> Int {
        // 赤ドラを正規化済み牌にまとめる（"m0" → "m5" など）
        var normalizedRemaining: [String: Int] = [:]
        for (label, count) in remainingCounts where count > 0 {
            let norm = Pai.normalize(label)
            normalizedRemaining[norm, default: 0] += count
        }

        var total = 0
        for (tile, count) in normalizedRemaining where count > 0 {
            let hand14 = hand13 + [tile]
            // hand14 から 1 枚ずつ除いた 13 枚でシャンテンが下がるか確認
            var improved = false
            for removeIdx in hand14.indices {
                var test = hand14
                test.remove(at: removeIdx)
                if Hule.xiangting(test) < currentShanten {
                    improved = true
                    break
                }
            }
            if improved { total += count }
        }
        return total
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
    var paoPlayerIdx: Int? = nil        // パオ責任者インデックス（大三元・大四喜・四槓子）
    var isDaburi: Bool = false          // ダブル立直フラグ
    var validAngangLabels: Set<String> = []  // リーチ後の暗槓可能牌ラベル
}

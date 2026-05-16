//
//  Shan.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation


// MARK: - Shoupai
@Observable
class Shoupai{
    var bingpai:[Pai]=[]
    var zimo:Pai?
    var fulou:[[Pai]]=[]
    
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

    // fulou を parseFulouTiles 用のコンパクト文字列配列に変換
    // 刻子: "m999"、順子: "p123"、暗槓: "z1111+"、明槓: "z3333-"
    // 赤牌(0)はそのまま保持。parseFulouTiles 側で 0→5 に正規化する。
    var fulouTiles: [String] {
        fulou.compactMap { group in
            let labels = group.map { $0.label }
                              .filter { $0 != "_" && $0.count == 2 }
            guard labels.count >= 3,
                  let suitChar = labels.first?.first else { return nil }
            let suit = String(suitChar)
            let nums = labels.compactMap { Int(String($0.last!)) }
            let normNums = nums.map { $0 == 0 ? 5 : $0 }

            if labels.count == 4 && Set(normNums).count == 1 {
                let suffix = group.contains { $0.rotated } ? "-" : "+"
                return suit + nums.map { String($0) }.joined() + suffix
            } else if labels.count == 3 && Set(normNums).count == 1 {
                return suit + nums.map { String($0) }.joined()
            } else if labels.count == 3 && suit != "z" {
                return suit + normNums.sorted().map { String($0) }.joined()
            }
            return nil
        }
    }

    // 表示中の bingpai ラベル（hidden 除外）
    var visibleLabels: [String] { bingpai.filter { !$0.hidden }.map { $0.label } }

    // bingpai + zimo
    var allLabels: [String] { visibleLabels + (zimo.map { [$0.label] } ?? []) }
    
    var normalizedAllLabels: [String] { allLabels.map{Pai.normalize($0)} }
    
    var gangCount: Int {
        fulou.filter { $0.count == 4 }.count
    }

    var gangzi: [String] {
        Dictionary(grouping: normalizedAllLabels, by: { $0 })
            .filter { $0.value.count >= 4 }
            .compactMap { $0.value.first }
    }

    // ポン済みグループに追加できる手牌ラベルを返す（加槓候補）
    var kagangzi: [String] {
        let pengNormLabels = Set(
            fulou
                .filter { $0.count == 3 && Set($0.map { $0.normalized }).count == 1 }
                .compactMap { $0.first.map { $0.normalized} }
        )
        return Dictionary(grouping: normalizedAllLabels, by: { $0 })
            .filter { pengNormLabels.contains($0.key) }
            .compactMap { $0.value.first }
    }
    
    func getPengCandidate(_ label: String) -> [Int] {
        let norm = Pai.normalize(label)
        let normalized = normalizedAllLabels
        let indices = normalized.indices.filter { normalized[$0] == norm }
        guard indices.count >= 2 else { return [] }
        return indices
    }

    func getMinggangCandidate(_ label: String) -> [Int] {
        let norm = Pai.normalize(label)
        let normalized = normalizedAllLabels
        let indices = normalized.indices.filter { normalized[$0] == norm }
        guard indices.count >= 3 else { return [] }
        return indices
    }
}

// MARK: - Pai
struct Pai: Hashable {
    var label: String = "_"
    var alt: String = "_"
    var hidden: Bool = false
    var revealed: Bool = true
    var rotated: Bool = false

    init(_ code: String) {
        let value = paiTable[code]
        self.label = value != nil ? code : "_"
        self.alt = value ?? "_"
    }
    
    var normalized: String {
        return Pai.normalize(label)
    }
    
    static func normalize(_ label: String) -> String {
        guard label.count == 2, label.last == "0" else { return label }
        return "\(label.first!)5"
    }
}


// MARK: - He
@Observable
class He{
    var qipai:[Pai]=[]
    private(set) var calledPai:[Pai]=[]

    init(qipai: [Pai]=[]) {
        self.qipai = qipai
    }

    /// 他プレイヤーに副露されたとき呼ぶ。河から牌を取り除き calledPai に記録する
    func callLast() -> Pai {
        var pai = qipai.removeLast()
        pai.rotated = true
        calledPai.append(pai)
        return pai
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
    
    mutating func revealGangdora(){
        guard !libaopai.isEmpty else {return}
        let baopai = libaopai.removeFirst()
        self.baopai.append(baopai)
    }
}

// MARK: - Shan
struct Shan {
    var shan: [Pai]=[]
    var wangpai: Wangpai=Wangpai()
    var he: [He] = []
    var shoupai:[Shoupai] = []
    
    func makePai(settings: GameSettings = GameSettings()) -> [Pai] {
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

        // 各スーツの赤ドラ枚数分だけ suit5 を suit0 に置換
        let akaCounts = [("m", settings.akadoraMan), ("p", settings.akadoraPin), ("s", settings.akadoraSou)]
        for (suit, count) in akaCounts {
            var replaced = 0
            for i in pais.indices {
                guard replaced < count else { break }
                if pais[i].label == "\(suit)5" {
                    pais[i] = Pai("\(suit)0")
                    replaced += 1
                }
            }
        }

        return pais
    }

    init(_ auto: Bool=true, settings: GameSettings = GameSettings(), shan: [Pai]=[], wangpai: Wangpai=Wangpai(), he: [He]=[], shoupai: [Shoupai]=[]) {
        if (auto) {
            let allPai = makePai(settings: settings)
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
    
    mutating func popShan() -> Pai {
        return self.shan.removeLast()
    }
    
    var paishu: Int {
        return shan.count - (4 - wangpai.lingshang.count)
    }
    
}

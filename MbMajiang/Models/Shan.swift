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
    var revealed: Bool = true
    var rotated: Bool = false

    init(_ code: String) {
        let value = paiTable[code]
        self.label = value != nil ? code : "_"
        self.alt = value ?? "_"
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
    
    mutating func popShan() -> Pai {
        return self.shan.removeLast()
    }
    
//    private func revealNextDora() {
//        let revealed = board.shan.wangpai.baopai.count
//        // libaopai[0〜4] がリーチドラ表示牌（最大5枚）
//        if revealed < board.shan.wangpai.libaopai.count {
//            let next = board.shan.wangpai.libaopai[revealed - 1]
//            board.shan.wangpai.baopai.append(next)
//        }
//    }
    
}

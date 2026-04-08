//
//  GameState.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/02.
//

import Foundation

// MARK: - Shoupai
struct Shoupai{
    var bingpai:[Pai]=[]
    var zimo:Pai?
    
    init(_ bingpai: [Pai]=[], _ zimo: Pai? = nil) {
        self.bingpai = bingpai
        self.zimo = zimo
    }
    
    init(_ bingpai: [String] = [],_ zimo: String? = nil) {
        self.bingpai = bingpai.map { Pai($0) }
        self.zimo = zimo.map {  Pai($0) }
    }
    
    mutating func takeZimo() -> Pai? {
        let value = self.zimo
        self.zimo = nil
            return value
        }
    
    
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
    
    enum Feng:String{
        case 東="東"
        case 南="南"
        case 西="西"
        case 北="北"
        
        var next: Feng {
            switch self {
            case .東: return .南
            case .南: return .西
            case .西: return .北
            case .北: return .東
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
struct He{
    var qipai:[Pai]=[]
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
        
        // 数牌（萬子・筒子・索子）
        for suit in ["m", "p", "s"] {
            for num in 1...9 {
                for _ in 0..<4 {
                    pais.append(Pai("\(suit)\(num)"))
                }
            }
        }
        
        // 字牌
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
                Shoupai(Array(shuffled[(14 + i * 13)..<(14 + (i + 1) * 13)]))
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

// MARK: - Game
@Observable
class Game{
    var board:Board=Board()
    var status:GameStatus=GameStatus()
    var onAction: ((GameStatus) -> Void)?
    
    func nextPlayer() -> Int {
            switch self.status.action {
            case .qipai:
                return getTongjia()
            case .fulou:
                return self.status.player
            default:
                return (self.status.player + 1) % 4
            }
        }
    
    init() {

        }
    
    func start() {
            kaiju()
        }
    
    
     func kaiju(){
        self.status.action = .kaiju
        self.status.player = 4
        onAction?(self.status)
    }
    
     func qipai(){
        self.status.action = .qipai
        self.status.player = 4
        self.board.score.setQijia(qijia: Int.random(in: 0...3))
        onAction?(self.status)
    }
    
     func zimo(){
        self.status.action = .zimo
        
        let zimo=self.popShan()
        self.board.shan.shoupai[self.status.player].zimo=zimo
        self.status.zimo=self.board.shan.shoupai[self.status.player].zimo?.label
        onAction?(self.status)
    }
    
    func dapai(_ index: Int = 99) {
        self.status.action = .dapai
        
        if index == 99 {
                // zimoを打牌
                let dapai = self.board.shan.shoupai[self.status.player].zimo!
                self.board.shan.he[self.status.player].qipai.append(dapai)
                self.board.shan.shoupai[self.status.player].zimo?.hidden = true  // 非表示に
            } else {
                // bingpaiから打牌
                let dapai = self.board.shan.shoupai[self.status.player].bingpai[index]
                self.board.shan.he[self.status.player].qipai.append(dapai)
                self.board.shan.shoupai[self.status.player].bingpai[index].hidden = true  // 非表示に
            }
        
        let dapai = index == 99
            ? self.board.shan.shoupai[self.status.player].zimo!
            : self.board.shan.shoupai[self.status.player].bingpai[index]
        
        
        self.status.dapai = dapai.label
        self.status.selectedIdx = index
        
        onAction?(self.status)
    }
    
    func getTongjia()->Int{
        return self.board.score.defen.firstIndex(where: { $0.0 == .東 })!
    }
    
     func popShan()->Pai{
        return self.board.shan.shan.removeLast()
    }

}

struct GameStatus{
    var action:Actions = .kaiju
    var player:Int = 4
    var dapai:String?=nil
    var selectedIdx:Int?=nil
    var zimo:String?=nil
}

enum Actions {
    case kaiju
    case dapai
    case hule
    case zimo
    case lizhi
    case fulou
    case qipai
}

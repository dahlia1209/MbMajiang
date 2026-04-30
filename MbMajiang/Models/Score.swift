//
//  Score.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation

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
        return self.defen.map { ($0.0.prev, $0.1) }
    }
    
    mutating func nextRound(){
        self.round = self.round.next
        self.defen = self.rotationFeng()
    }
}

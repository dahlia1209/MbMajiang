//
//  Board.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation
// MARK: - Board
struct Board{
    var shan:Shan
    var score:Score
    
    init(shan: Shan=Shan(), score: Score=Score()) {
        self.shan = shan
        self.score = score
    }
}

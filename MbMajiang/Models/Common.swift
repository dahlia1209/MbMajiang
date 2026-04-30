//
//  Common.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/20.
//

import Foundation

// MARK: - Feng（風牌）
enum Feng: Int {
    case 東 = 1, 南 = 2, 西 = 3, 北 = 4

    var label: String {
        switch self { case .東: return "東"; case .南: return "南"; case .西: return "西"; case .北: return "北" }
    }

    var next: Feng {
        switch self { case .東: return .南; case .南: return .西; case .西: return .北; case .北: return .東 }
    }

    var prev: Feng {
        switch self { case .東: return .北; case .南: return .東; case .西: return .南; case .北: return .西 }
    }
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
    case chi
    case peng
    case none
    
}

// MARK: - Jia
enum Jia{
    case xiajia
    case duimian
    case shangjia
    case zijia
}


//
//  GameErrors.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/04.
//

import Foundation

enum GameError: Error {
    case paiNotFound(key: String)

}

// エラーメッセージを一元管理
extension GameError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .paiNotFound(let key):
            return "'\(key)' は存在しない牌です"

        }
    }
}

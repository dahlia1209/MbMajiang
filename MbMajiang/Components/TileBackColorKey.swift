//
//  TileBackColorKey.swift
//  MbMajiang
//

import SwiftUI

private struct TileBackColorKey: EnvironmentKey {
    static let defaultValue: GameSettings.TileBackAppearance = .solid(GameSettings.TileBackColor.gold.color)
}

extension EnvironmentValues {
    var tileBackColor: GameSettings.TileBackAppearance {
        get { self[TileBackColorKey.self] }
        set { self[TileBackColorKey.self] = newValue }
    }
}

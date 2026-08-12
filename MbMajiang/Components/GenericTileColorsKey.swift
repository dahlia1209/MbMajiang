//
//  GenericTileColorsKey.swift
//  MbMajiang
//

import SwiftUI

private struct GenericTileColorsKey: EnvironmentKey {
    static let defaultValue: GameSettings.GenericTileColors = GameSettings().genericTileColors
}

extension EnvironmentValues {
    var genericTileColors: GameSettings.GenericTileColors {
        get { self[GenericTileColorsKey.self] }
        set { self[GenericTileColorsKey.self] = newValue }
    }
}

//
//  TileThemeKey.swift
//  MbMajiang
//

import SwiftUI

private struct TileThemeKey: EnvironmentKey {
    static let defaultValue: GameSettings.TileTheme = .standard
}

extension EnvironmentValues {
    var tileTheme: GameSettings.TileTheme {
        get { self[TileThemeKey.self] }
        set { self[TileThemeKey.self] = newValue }
    }
}

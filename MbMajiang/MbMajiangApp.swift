//
//  MbMajiangApp.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/03/29.
//

import SwiftUI

@main
struct MbMajiangApp: App {
    @State private var settings = GameSettings.load()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TitleView()
                .environment(settings)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                SoundManager.shared.stopBGM()
            }
        }
    }
}

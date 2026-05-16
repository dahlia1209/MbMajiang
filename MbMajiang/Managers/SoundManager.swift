//
//  SoundManager.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/05/14.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]

    func play(_ name: String) {
        let url = ["mp3", "wav"].lazy.compactMap {
            Bundle.main.url(forResource: name, withExtension: $0, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: $0)
        }.first
        guard let url else { return }
        if players[name] == nil {
            players[name] = try? AVAudioPlayer(contentsOf: url)
            players[name]?.prepareToPlay()
        }
        players[name]?.stop()
        players[name]?.currentTime = 0
        players[name]?.play()
    }
}

//
//  SoundManager.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/05/14.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    var soundTheme: GameSettings.SoundTheme = .original

    private var players: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }
    }

    func play(_ action: String) {
        let name = soundTheme.soundName(for: action)
        preload(name)
        guard let player = players[name] else { return }
        player.stop()
        player.currentTime = 0
        player.play()
    }

    func playSequence(_ names: [String], overlap: TimeInterval = 0) {
        names.forEach { preload($0) }
        var offset: TimeInterval = 0
        for name in names {
            let dur = players[name]?.duration ?? 0
            let d = offset
            DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                self?.play(name)
            }
            offset += max(dur - overlap, 0)
        }
    }

    func playBGM(_ name: String, volume: Float = 0.5) {
        guard let url = urlFor(name) else { return }
        bgmPlayer?.stop()
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.volume = volume
        bgmPlayer?.prepareToPlay()
        bgmPlayer?.play()
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    func duration(for name: String) -> TimeInterval {
        preload(name)
        return players[name]?.duration ?? 0
    }

    private func preload(_ name: String) {
        guard players[name] == nil, let url = urlFor(name) else { return }
        players[name] = try? AVAudioPlayer(contentsOf: url)
        players[name]?.prepareToPlay()
    }

    private func urlFor(_ name: String) -> URL? {
        let parts = name.split(separator: "/", omittingEmptySubsequences: true)
        let fileName = String(parts.last ?? Substring(name))
        let subdir = parts.count > 1
            ? "Sounds/" + parts.dropLast().joined(separator: "/")
            : "Sounds"
        return ["wav", "mp3"].lazy.compactMap {
            Bundle.main.url(forResource: fileName, withExtension: $0, subdirectory: subdir)
            ?? Bundle.main.url(forResource: fileName, withExtension: $0)
        }.first
    }
}

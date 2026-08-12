//
//  PlayerLifetimeStats.swift
//  MbMajiang
//

import Foundation

/// 自分（プレイヤー index 0）の通算成績。ゲームモード（半荘戦・東風戦・一局戦）ごとに集計する。
struct PlayerLifetimeStats: Codable {

    struct ModeStats: Codable {
        var gameCount: Int = 0
        var roundCount: Int = 0
        var totalPoints: Double = 0
        var rankCounts: [Int] = [0, 0, 0, 0]   // index0=1位 ... index3=4位
        var bestScore: Int? = nil
        var agariCount: Int = 0
        var agariPointsTotal: Int = 0
        var lizhiCount: Int = 0
        var fulouCount: Int = 0
        var houjuuCount: Int = 0
        var houjuuPointsTotal: Int = 0
        var yakuCounts: [String: Int] = [:]

        // MARK: - 導出項目（表示用）。対局実績がない場合は0を返す
        var averageRank: Double {
            guard gameCount > 0 else { return 0 }
            let sum = 1 * rankCounts[0] + 2 * rankCounts[1] + 3 * rankCounts[2] + 4 * rankCounts[3]
            return Double(sum) / Double(gameCount)
        }
        var topRate: Double       { rate(rankCounts[0], of: gameCount) }
        var rentaiRate: Double    { rate(rankCounts[0] + rankCounts[1], of: gameCount) }
        var lastAvoidRate: Double { rate(gameCount - rankCounts[3], of: gameCount) }
        var fulouRate: Double     { rate(fulouCount, of: roundCount) }
        var lizhiRate: Double     { rate(lizhiCount, of: roundCount) }
        var agariRate: Double     { rate(agariCount, of: roundCount) }
        var houjuuRate: Double    { rate(houjuuCount, of: roundCount) }
        var averageAgariPoints: Double  { average(agariPointsTotal, of: agariCount) }
        var averageHoujuuPoints: Double { average(houjuuPointsTotal, of: houjuuCount) }

        private func rate(_ n: Int, of d: Int) -> Double {
            guard d > 0 else { return 0 }
            return Double(n) / Double(d) * 100
        }
        private func average(_ n: Int, of d: Int) -> Double {
            guard d > 0 else { return 0 }
            return Double(n) / Double(d)
        }
    }

    var hanjouSen = ModeStats()
    var tonpuSen  = ModeStats()
    var ikkokuSen = ModeStats()

    subscript(mode: GameSettings.KyokuCount) -> ModeStats {
        get {
            switch mode {
            case .hanjouSen: return hanjouSen
            case .tonpuSen:  return tonpuSen
            case .ikkokuSen: return ikkokuSen
            }
        }
        set {
            switch mode {
            case .hanjouSen: hanjouSen = newValue
            case .tonpuSen:  tonpuSen  = newValue
            case .ikkokuSen: ikkokuSen = newValue
            }
        }
    }

    // MARK: - Persistence
    private static let storageKey = "playerLifetimeStats"

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    static func load() -> PlayerLifetimeStats {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(PlayerLifetimeStats.self, from: data)
        else { return PlayerLifetimeStats() }
        return decoded
    }

    /// 指定モードの成績を読み込み → 変更 → 保存する
    static func update(mode: GameSettings.KyokuCount, _ body: (inout ModeStats) -> Void) {
        var stats = load()
        var modeStats = stats[mode]
        body(&modeStats)
        stats[mode] = modeStats
        stats.save()
    }
}

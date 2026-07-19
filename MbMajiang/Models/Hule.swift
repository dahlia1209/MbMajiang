//
//  Hule.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/11.
//

import Foundation



// MARK: - BlockCounts（ブロック種別×スートのカウント配列）
struct BlockCounts: Hashable {
    var shunzi:     [String: [Int]]  // 順子 (m/p/s): 開始番号-1 が index (有効 0〜6)
    var mingkezi:   [String: [Int]]  // 明刻 (m/p/s/z)
    var ankezi:     [String: [Int]]  // 暗刻 (m/p/s/z)
    var minggangzi: [String: [Int]]  // 明槓 (m/p/s/z)
    var angangzi:   [String: [Int]]  // 暗槓 (m/p/s/z)
    var ryanmen:    [String: [Int]]  // リャンメン (m/p/s)
    var penchan:    [String: [Int]]  // ペンチャン (m/p/s)
    var kanchan:    [String: [Int]]  // カンチャン (m/p/s)
    var toitsu:     [String: [Int]]  // 対子 (m/p/s/z)
    var isolated:   [String: [Int]]  // 孤立牌 (m/p/s/z)
    
    // 刻子（明刻＋暗刻）
    var kezi: [String: [Int]] {
        var result: [String: [Int]] = [:]
        for suit in ["m", "p", "s"] {
            result[suit] = zip(ankezi[suit]!, mingkezi[suit]!).map { $0 + $1 }
        }
        result["z"] = zip(ankezi["z"]!, mingkezi["z"]!).map { $0 + $1 }
        return result
    }
    
    // 槓子（明槓＋暗槓）
    var gangzi: [String: [Int]] {
        var result: [String: [Int]] = [:]
        for suit in ["m", "p", "s"] {
            result[suit] = zip(angangzi[suit]!, minggangzi[suit]!).map { $0 + $1 }
        }
        result["z"] = zip(angangzi["z"]!, minggangzi["z"]!).map { $0 + $1 }
        return result
    }
    
    var nShunzi:   Int { shunzi.values.flatMap { $0 }.reduce(0, +) }
    var nKezi:     Int { kezi.values.flatMap { $0 }.reduce(0, +) }
    var nAnkezi:   Int { ankezi.values.flatMap { $0 }.reduce(0, +) }
    var nGangzi:   Int { gangzi.values.flatMap { $0 }.reduce(0, +) }
    var nAngangzi: Int { angangzi.values.flatMap { $0 }.reduce(0, +) }
    var nToitsu:   Int { toitsu.values.flatMap { $0 }.reduce(0, +) }
    var jantai:    String { getJantai() }
    var nYaojiu:   Int { getNYaojiu() }
    var nZipai:    Int { kezi["z"]?.reduce(0, +) ?? 0 }
    
    init() {
        let s9 = [Int](repeating: 0, count: 9)
        let s7 = [Int](repeating: 0, count: 7)
        shunzi     = ["m": s9, "p": s9, "s": s9]
        mingkezi   = ["m": s9, "p": s9, "s": s9, "z": s7]
        ankezi     = ["m": s9, "p": s9, "s": s9, "z": s7]
        minggangzi = ["m": s9, "p": s9, "s": s9, "z": s7]
        angangzi   = ["m": s9, "p": s9, "s": s9, "z": s7]
        ryanmen    = ["m": s9, "p": s9, "s": s9]
        penchan    = ["m": s9, "p": s9, "s": s9]
        kanchan    = ["m": s9, "p": s9, "s": s9]
        toitsu     = ["m": s9, "p": s9, "s": s9, "z": s7]
        isolated   = ["m": s9, "p": s9, "s": s9, "z": s7]
    }
    
    private func getJantai() -> String{
        for suit in ["m", "p", "s", "z"] {
            guard let arr = toitsu[suit] else { continue }
            for (i, cnt) in arr.enumerated() where cnt > 0 {
                return "\(suit)\(i + 1)"
            }
        }
        return ""
    }
    
    private func getNYaojiu () -> Int {
        var count = 0
        for suit in ["m", "p", "s"] {
            if let arr = shunzi[suit]  { count += arr[0] + arr[6] }
            if let arr = gangzi[suit]    { count += arr[0] + arr[8] }
            if let arr = kezi[suit]    { count += arr[0] + arr[8] }
            if let arr = ryanmen[suit] { count += arr[0] + arr[7] }
            if let arr = penchan[suit] { count += arr.reduce(0, +) }
            if let arr = kanchan[suit] { count += arr[0] + arr[6] }
            if let arr = toitsu[suit]  { count += arr[0] + arr[8] }
            if let arr = isolated[suit]{ count += arr[0] + arr[8] }
        }
        if let arr = gangzi["z"]     { count += arr.reduce(0, +) }
        if let arr = kezi["z"]     { count += arr.reduce(0, +) }
        if let arr = toitsu["z"]   { count += arr.reduce(0, +) }
        if let arr = isolated["z"] { count += arr.reduce(0, +) }
        return count
    }
    
    func isChitoitsu() -> Bool {
        guard nToitsu == 7 else { return false }
        for suit in ["m", "p", "s", "z"] {
            if let arr = toitsu[suit], arr.contains(where: { $0 >= 2 }) {
                return false
            }
        }
        return true
    }
    
    func isKokushimuso() -> Bool {
        guard nShunzi == 0, nKezi == 0, nGangzi == 0 else { return false }
        guard nToitsu == 1 else { return false }
        let j = jantai
        guard j.first == "z" || j.hasSuffix("1") || j.hasSuffix("9") else { return false }
        let yaojiu: [(String, Int)] = [
            ("m",0),("m",8),("p",0),("p",8),("s",0),("s",8),
            ("z",0),("z",1),("z",2),("z",3),("z",4),("z",5),("z",6)
        ]
        for (suit, idx) in yaojiu {
            let total = (isolated[suit]?[idx] ?? 0) + (toitsu[suit]?[idx] ?? 0)
            guard total > 0 else { return false }
        }
        return true
    }

}



// MARK: - HuleContext（アガリの局面情報）
struct HuleContext {
    var zhuangfeng: Feng   // 場風
    var menfeng: Feng      // 自風
    var zimo: Bool         // ツモ和了か
    var menqian: Bool      // 門前か（副露なし）
    var lizhi: Bool        // 立直か
    var daburi: Bool       // ダブル立直か
    var yifa: Bool         // 一発か
    var qianggang: Bool    // 槍槓か
    var lingshang: Bool    // 嶺上開花か
    var haidi: Bool        // 海底か（ツモ）
    var hedi: Bool         // 河底か（ロン）
    var tianhu: Bool       // 天和か
    var dihu: Bool         // 地和か
    var winTile: String    // アガリ牌（正規化済み）
    var renpuFu: Int = 4  // 連風牌の雀頭符 (2 or 4)
    var kuitanAri: Bool = true  // 食い断あり
}

// MARK: - Yaku（役）
struct Yaku {
    let name: String
    let fanshu: Int  // 翻数（役満=100, ダブル役満=200）
    
    static let yakuman = 100
    static let doubleYakuman = 200
}

// MARK: - DefenResult（点数計算結果）
struct DefenResult {
    let defen: Int         // 勝者の獲得点数（本場・供託込み）
    let fenpei: [Int]      // 各プレイヤーの点数変動 [0...3]
    let effectiveFan: Int  // 設定反映後の有効翻数（表示用）
}

// MARK: - Hule
struct Hule {    
    // ドラ枚数を数える（baopaiTable を使用）
    // baopaiLabels はドラ表示牌ラベルの配列
    static func akaDoraCount(tiles: [String]) -> Int {
        tiles.filter { ["m0","p0","s0"].contains($0) }.count
    }

    static func doraCount(tiles: [String], baopaiLabels: [String]) -> Int {
        var count = 0
        for indicator in baopaiLabels {
            guard let doraTiles = baopaiTable[indicator] else { continue }
            for tile in tiles {
                if doraTiles.contains(tile) { count += 1 }
            }
        }
        return count
    }
    
    // MARK: - シャンテン数
    static func xiangting(_ tiles: [String]) -> Int {
        guard tiles.count >= 1 && (13 - tiles.count) % 3 == 0 else { return 99 }
        let fulou = (13 - tiles.count) / 3
        var xiangting = mianziXiangting(tiles)
        if fulou == 0 {
            xiangting = min(xiangting, chiitoitsuXiangting(tiles))
            xiangting = min(xiangting, kokushiXiangting(tiles))
      }
        return xiangting
    }
    
    static func chiitoitsuXiangting(_ tiles: [String]) -> Int {
        guard tiles.count == 13 else { return 99 }
        var counts: [String: Int] = [:]
        for tile in tiles { counts[tile, default: 0] += 1 }
        let pairCount = counts.values.filter { $0 >= 2 }.count
        let solo = counts.values.filter { $0 == 1 }.count
        return 6 - pairCount + max(7 - (pairCount + solo),0)
    }
    
    // スーツ1種の (面子数, 搭子数, 雀頭あり) を表す軽量型
    private struct SB: Hashable { var m, t: Int; var j: Bool }

    // 1スーツのカウント配列から SB の全組み合わせをバックトラックで列挙
    private static func suitBlocks(_ counts: [Int], canSeq: Bool) -> [SB] {
        var c = counts
        var out = Set<SB>()
        func bt(_ pos: Int, _ m: Int, _ t: Int, _ j: Bool) {
            var p = pos
            while p < c.count && c[p] == 0 { p += 1 }
            guard p < c.count else { out.insert(SB(m: m, t: t, j: j)); return }
            // 刻子
            if c[p] >= 3 { c[p] -= 3; bt(p, m+1, t, j); c[p] += 3 }
            // 順子
            if canSeq && p+2 < c.count && c[p+1] > 0 && c[p+2] > 0 {
                c[p] -= 1; c[p+1] -= 1; c[p+2] -= 1
                bt(p, m+1, t, j)
                c[p] += 1; c[p+1] += 1; c[p+2] += 1
            }
            // 対子 → 雀頭（まだ雀頭なし）
            if c[p] >= 2 && !j { c[p] -= 2; bt(p, m, t, true); c[p] += 2 }
            // 対子 → 搭子
            if c[p] >= 2 { c[p] -= 2; bt(p, m, t+1, j); c[p] += 2 }
            // 両面 / 辺張搭子
            if canSeq && p+1 < c.count && c[p+1] > 0 {
                c[p] -= 1; c[p+1] -= 1; bt(p, m, t+1, j); c[p] += 1; c[p+1] += 1
            }
            // 嵌張搭子
            if canSeq && p+2 < c.count && c[p+2] > 0 {
                c[p] -= 1; c[p+2] -= 1; bt(p, m, t+1, j); c[p] += 1; c[p+2] += 1
            }
            // 孤立牌（pos の残り全枚をスキップ）
            let s = c[p]; c[p] = 0; bt(p, m, t, j); c[p] = s
        }
        bt(0, 0, 0, false)
        return Array(out)
    }

    static func mianziXiangting(_ tiles: [String]) -> Int {
        guard tiles.count >= 1 && (13 - tiles.count) % 3 == 0 else { return 99 }
        let fulou = (13 - tiles.count) / 3
        let base  = 8 - fulou * 2
        let sc = tilesToSuitCounts(tiles)

        // スーツごとに (面子, 搭子, 雀頭) の組み合わせを列挙
        let mSet = suitBlocks(sc.m, canSeq: true)
        let pSet = suitBlocks(sc.p, canSeq: true)
        let sSet = suitBlocks(sc.s, canSeq: true)
        let zSet = suitBlocks(sc.z, canSeq: false)

        var best = base
        for mc in mSet { for pc in pSet { for sc2 in sSet { for zc in zSet {
            // 雀頭は全体で最大1つ
            let jCount = (mc.j ? 1 : 0) + (pc.j ? 1 : 0) + (sc2.j ? 1 : 0) + (zc.j ? 1 : 0)
            guard jCount <= 1 else { continue }
            let mentsu = mc.m + pc.m + sc2.m + zc.m
            let tatsu  = mc.t + pc.t + sc2.t + zc.t
            let cap = (4 - fulou) - mentsu
            let s1 = base - 2 * mentsu - min(tatsu, cap)
            let s2 = jCount == 1 ? s1 - 1 : s1
            best = min(best, min(s1, s2))
        }}}}
        return best
    }
    
    // 国士無双シャンテン数: 13 - 种類数 - 対子有無
    static func kokushiXiangting(_ tiles: [String]) -> Int {
        guard tiles.count == 13 else { return 99 }
        let yaochuTiles = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
        let tileSet = Set(tiles)
        let uniqueCount = yaochuTiles.filter { tileSet.contains($0) }.count
        var counts: [String: Int] = [:]
        for tile in tiles { counts[tile, default: 0] += 1 }
        let hasPair = yaochuTiles.contains { (counts[$0] ?? 0) >= 2 }
        return 13 - uniqueCount - (hasPair ? 1 : 0)
    }
    
    // スート別カウント配列に変換 (0-indexed: [0]=1牌, ..., [8]=9牌, z は7要素)
    static func tilesToSuitCounts(_ tiles: [String]) -> (m: [Int], p: [Int], s: [Int], z: [Int]) {
        var mC = Array(repeating: 0, count: 9)
        var pC = Array(repeating: 0, count: 9)
        var sC = Array(repeating: 0, count: 9)
        var zC = Array(repeating: 0, count: 7)
        for tile in tiles {
            guard tile.count == 2, let num = Int(String(tile.last!)), num >= 1 else { continue }
            switch tile.first! {
            case "m": if num <= 9 { mC[num-1] += 1 }
            case "p": if num <= 9 { pC[num-1] += 1 }
            case "s": if num <= 9 { sC[num-1] += 1 }
            case "z": if num <= 7 { zC[num-1] += 1 }
            default: break
            }
        }
        return (mC, pC, sC, zC)
    }
    
    
    
    // MARK: - ブロック列挙
    
    // 14枚の和了形を面子分解し、「順子・刻子 4組 + 対子 1組」の全パターンを返す
    // mentsuOnly: true でターツ・孤立牌の枝を再帰中に打ち切るため効率的
    static func winningDecompositions(_ bingpaiTiles: [String], _ fulouTiles: [String] = []) -> [BlockCounts] {
        // 14枚 or 副露後の 11/8/5/2 枚を許容
        guard bingpaiTiles.count >= 2 && (bingpaiTiles.count - 2) % 3 == 0 else { return [] }
        let requiredMentsu = (bingpaiTiles.count - 2) / 3  // 14枚→4, 11枚→3, 8枚→2 ...
        let fulouBC = parseFulouTiles(fulouTiles)
        let sc = tilesToSuitCounts(bingpaiTiles)
        let mR = extractSuitBlocks(sc.m, suit: "m", canSeq: true,  mentsuOnly: true)
        let pR = extractSuitBlocks(sc.p, suit: "p", canSeq: true,  mentsuOnly: true)
        let sR = extractSuitBlocks(sc.s, suit: "s", canSeq: true,  mentsuOnly: true)
        let zR = extractSuitBlocks(sc.z, suit: "z", canSeq: false, mentsuOnly: true)
        var seen = Set<BlockCounts>()
        var results: [BlockCounts] = []
        for bm in mR { for bp in pR { for bs in sR { for bz in zR {
            let hand = mergeBlockCounts(m: bm, p: bp, s: bs, z: bz)
            let nMentsu = hand.nShunzi + hand.nKezi + hand.nGangzi
            let nToitsu = hand.nToitsu
            guard (nMentsu == requiredMentsu && nToitsu == 1) || hand.isChitoitsu() else { continue }
            let merged = addBlockCounts(hand, fulouBC)
            if seen.insert(merged).inserted { results.append(merged) }
        }}}}
        
        // 九蓮宝燈チェック（門前14枚のみ）
        if fulouTiles.isEmpty && bingpaiTiles.count == 14 {
            let uniqueSuits = Set(bingpaiTiles.compactMap { $0.first })
            if uniqueSuits.count == 1, let suitChar = uniqueSuits.first, suitChar != "z" {
                let suit = String(suitChar)
                var suitCounts = Array(repeating: 0, count: 9)
                for t in bingpaiTiles {
                    guard let n = Int(String(t.last!)), n >= 1 && n <= 9 else { continue }
                    suitCounts[n - 1] += 1
                }
                let base = [3, 1, 1, 1, 1, 1, 1, 1, 3]
                if zip(suitCounts, base).allSatisfy({ $0.0 >= $0.1 }) {
                    var bc = BlockCounts()
                    for (i, cnt) in suitCounts.enumerated() where cnt > 0 {
                        bc.isolated[suit]?[i] = cnt
                    }
                    if seen.insert(bc).inserted { results.append(bc) }
                }
            }
        }

        // 国士無双チェック（門前14枚のみ）
        if fulouTiles.isEmpty && bingpaiTiles.count == 14 {
            let yaojiu = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
            var counts: [String: Int] = [:]
            for t in bingpaiTiles { counts[Pai.normalize(t), default: 0] += 1 }
            if yaojiu.allSatisfy({ counts[$0, default: 0] >= 1 }),
               let jantaiTile = yaojiu.first(where: { counts[$0, default: 0] >= 2 }) {
                var bc = BlockCounts()
                for tile in yaojiu {
                    guard tile.count == 2,
                          let suit = tile.first.map(String.init),
                          let num  = Int(String(tile.last!)) else { continue }
                    let idx = num - 1
                    if tile == jantaiTile {
                        bc.toitsu[suit]?[idx] = 1
                    } else {
                        bc.isolated[suit]?[idx] = 1
                    }
                }
                if seen.insert(bc).inserted { results.append(bc) }
            }
        }

        return results
    }
    
    // スート1種のカウント配列から BlockCounts を再帰的にバックトラックで列挙
    private static func extractBlockCounts(
        suit: String, _ counts: inout [Int], _ pos: Int, _ canSeq: Bool,
        mentsuOnly: Bool = false,
        _ current: inout BlockCounts, _ results: inout [BlockCounts]
    ) {
        var p = pos
        while p < counts.count && counts[p] == 0 { p += 1 }
        guard p < counts.count else { results.append(current); return }
        
        let num = p + 1  // 1-indexed 牌番号
        
        // 刻子
        if counts[p] >= 3 {
            counts[p] -= 3
            current.ankezi[suit]?[p] += 1
            extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: mentsuOnly, &current, &results)
            current.ankezi[suit]?[p] -= 1
            counts[p] += 3
        }
        
        // 順子
        if canSeq && p+2 < counts.count && counts[p+1] > 0 && counts[p+2] > 0 {
            counts[p] -= 1; counts[p+1] -= 1; counts[p+2] -= 1
            current.shunzi[suit]?[p] += 1
            extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: mentsuOnly, &current, &results)
            current.shunzi[suit]?[p] -= 1
            counts[p] += 1; counts[p+1] += 1; counts[p+2] += 1
        }
        
        // 対子
        if counts[p] >= 2 {
            counts[p] -= 2
            current.toitsu[suit]?[p] += 1
            extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: mentsuOnly, &current, &results)
            current.toitsu[suit]?[p] -= 1
            counts[p] += 2
        }
        
        // mentsuOnly の場合はターツ・孤立牌の枝をスキップ
        // 残り牌があっても results に追加せず枝を打ち切る（未使用牌のある組み合わせを除外）
        guard !mentsuOnly else { return }
        
        // リャンメン / ペンチャンターツ（num==1 → 1-2、num==8 → 8-9 はペンチャン）
        if canSeq && p+1 < counts.count && counts[p+1] > 0 {
            counts[p] -= 1; counts[p+1] -= 1
            if num == 1 || num == 8 {
                current.penchan[suit]?[p] += 1
                extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: false, &current, &results)
                current.penchan[suit]?[p] -= 1
            } else {
                current.ryanmen[suit]?[p] += 1
                extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: false, &current, &results)
                current.ryanmen[suit]?[p] -= 1
            }
            counts[p] += 1; counts[p+1] += 1
        }
        
        // カンチャンターツ
        if canSeq && p+2 < counts.count && counts[p+2] > 0 {
            counts[p] -= 1; counts[p+2] -= 1
            current.kanchan[suit]?[p] += 1
            extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: false, &current, &results)
            current.kanchan[suit]?[p] -= 1
            counts[p] += 1; counts[p+2] += 1
        }
        
        // 孤立牌（pos の残り全枚をスキップ）
        let saved = counts[p]
        counts[p] = 0
        current.isolated[suit]?[p] += saved
        extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: false, &current, &results)
        current.isolated[suit]?[p] -= saved
        counts[p] = saved
    }
    
    // 4スートの BlockCounts をスートごとに選択してマージ
    private static func mergeBlockCounts(
        m: BlockCounts, p: BlockCounts, s: BlockCounts, z: BlockCounts
    ) -> BlockCounts {
        var result = BlockCounts()
        result.shunzi["m"]   = m.shunzi["m"]!;  result.shunzi["p"]   = p.shunzi["p"]!;  result.shunzi["s"]   = s.shunzi["s"]!
        result.ankezi["m"]   = m.ankezi["m"]!;  result.ankezi["p"]   = p.ankezi["p"]!;  result.ankezi["s"]   = s.ankezi["s"]!; result.ankezi["z"]   = z.ankezi["z"]!
        result.ryanmen["m"]  = m.ryanmen["m"]!; result.ryanmen["p"]  = p.ryanmen["p"]!; result.ryanmen["s"]  = s.ryanmen["s"]!
        result.penchan["m"]  = m.penchan["m"]!; result.penchan["p"]  = p.penchan["p"]!; result.penchan["s"]  = s.penchan["s"]!
        result.kanchan["m"]  = m.kanchan["m"]!; result.kanchan["p"]  = p.kanchan["p"]!; result.kanchan["s"]  = s.kanchan["s"]!
        result.toitsu["m"]   = m.toitsu["m"]!;  result.toitsu["p"]   = p.toitsu["p"]!;  result.toitsu["s"]   = s.toitsu["s"]!;  result.toitsu["z"]   = z.toitsu["z"]!
        result.isolated["m"] = m.isolated["m"]!; result.isolated["p"] = p.isolated["p"]!; result.isolated["s"] = s.isolated["s"]!; result.isolated["z"] = z.isolated["z"]!
        return result
    }
    
    // スート1種のカウント配列から BlockCounts の全組み合わせを列挙（重複除去済み）
    static func extractSuitBlocks(_ counts: [Int], suit: String, canSeq: Bool, mentsuOnly: Bool = false) -> [BlockCounts] {
        var mutableCounts = counts
        var current = BlockCounts()
        var results: [BlockCounts] = []
        extractBlockCounts(suit: suit, &mutableCounts, 0, canSeq, mentsuOnly: mentsuOnly, &current, &results)
        var seen = Set<BlockCounts>()
        return results.filter { seen.insert($0).inserted }
    }
    
    // tilesToSuitCounts の戻り値を受け取り、全スートにわたる BlockCounts の全組み合わせを列挙
    static func enumerateBlocks(
        suitCounts: (m: [Int], p: [Int], s: [Int], z: [Int])
    ) -> [BlockCounts] {
        let mResults = extractSuitBlocks(suitCounts.m, suit: "m", canSeq: true)
        let pResults = extractSuitBlocks(suitCounts.p, suit: "p", canSeq: true)
        let sResults = extractSuitBlocks(suitCounts.s, suit: "s", canSeq: true)
        let zResults = extractSuitBlocks(suitCounts.z, suit: "z", canSeq: false)
        
        var seen = Set<BlockCounts>()
        var results: [BlockCounts] = []
        for bm in mResults { for bp in pResults { for bs in sResults { for bz in zResults {
            let merged = mergeBlockCounts(m: bm, p: bp, s: bs, z: bz)
            if seen.insert(merged).inserted { results.append(merged) }
        }}}}
        return results
    }
    
    
}

// MARK: - 役計算
extension Hule {
    static func getYaku(
        tiles: [String],
        context: HuleContext,
        baopai: [String] = [],
        libaopai: [String] = [],
        fulouTiles: [String] = []
    ) -> (yaku: [Yaku], fu: Int) {
        let normalized = tiles.map { Pai.normalize($0) }.sorted()
        //        let fulouBC = fulouBlockCounts(fulouGroups)
        let fulouBC = parseFulouTiles(fulouTiles)
        let expandFulouTiles = fulouTiles.flatMap { Hule.expandFulouTile($0) }
        let allTiles = tiles + expandFulouTiles
        let akaDoraCnt = akaDoraCount(tiles: allTiles)
        let doraCnt    = doraCount(tiles: allTiles, baopaiLabels: baopai) + akaDoraCnt
        let uraDoraCnt = context.lizhi ? doraCount(tiles: allTiles, baopaiLabels: libaopai) : 0

        //アガリ形を分解して役を取得
        let decompositions = winningDecompositions(normalized,fulouTiles)
        guard !decompositions.isEmpty else { return (yaku: [], fu: 30) }

        let candidates = decompositions.map { d -> (yaku: [Yaku], fu: Int) in
            let d = context.zimo ? d : adjustForRon(d, winTile: context.winTile) //ロンアガリで刻子になった場合は明刻に補正
            let yaku = yakuForDecomposition(d, context: context, fulouBC: fulouBC)
            let fu = computeFu(decomposition: d, context: context)
            return (yaku, fu)
        }

        let best = selectBestCandidate(candidates)
        var resultYaku = best?.yaku ?? []
        // ドラ・裏ドラは役あり確定後に追加（単独では和了不可）
        let maxFanshu = resultYaku.max(by: { $0.fanshu < $1.fanshu })?.fanshu ?? 0
          if maxFanshu > 0 && maxFanshu < 100   {
            if doraCnt    > 0 { resultYaku.append(Yaku(name: "ドラ",   fanshu: doraCnt))    }
            if uraDoraCnt > 0 { resultYaku.append(Yaku(name: "裏ドラ", fanshu: uraDoraCnt)) }
        }
        return (yaku: resultYaku, fu: best?.fu ?? 30)
    }

    // 複数の分解候補から最有利な組み合わせを選ぶ: 翻数優先、翻数が同点なら符が高い方を採用
    static func selectBestCandidate(_ candidates: [(yaku: [Yaku], fu: Int)]) -> (yaku: [Yaku], fu: Int)? {
        candidates.max { a, b in
            let aFan = a.yaku.reduce(0) { $0 + $1.fanshu }
            let bFan = b.yaku.reduce(0) { $0 + $1.fanshu }
            if aFan != bFan { return aFan < bFan }
            return a.fu < b.fu
        }
    }

    // ロン時: アガリ牌で完成した刻子を暗刻→明刻に補正する
    private static func adjustForRon(_ d: BlockCounts, winTile: String) -> BlockCounts {
        guard winTile.count >= 2,
              let numChar = winTile.dropFirst().first,
              let num = Int(String(numChar)) else { return d }
        let suit = String(winTile.prefix(1))
        let idx = num - 1
        guard (d.ankezi[suit]?[idx] ?? 0) > 0 else { return d }
        var d = d
        d.ankezi[suit]?[idx] -= 1
        d.mingkezi[suit]?[idx] += 1
        return d
    }

    // コンパクト文字列1要素を個別タイルラベルに展開する
    // 例: "m123" → ["m1","m2","m3"], "z1111+" → ["z1","z1","z1","z1"]
    static func expandFulouTile(_ s: String) -> [String] {
        let stripped = (s.hasSuffix("+") || s.hasSuffix("-")) ? String(s.dropLast()) : s
        guard stripped.count >= 4, let suit = stripped.first.map(String.init) else { return [] }
        return stripped.dropFirst().map { "\(suit)\($0)" }
    }
    
    // fulouTiles（コンパクト文字列形式）を BlockCounts に変換する
    // 形式: "m999"（刻子）, "p123"（順子）, "z1111+"（暗槓）, "z3333-"（明槓）
    static func parseFulouTiles(_ fulouTiles: [String]) -> BlockCounts {
        var bc = BlockCounts()
        for s in fulouTiles {
            guard s.count >= 4 else { continue }
            let isAnkan = s.hasSuffix("+")
            let isKan   = isAnkan || s.hasSuffix("-")
            let tileStr = isKan ? String(s.dropLast()) : s
            guard let suitChar = tileStr.first else { continue }
            let suit = String(suitChar)
            let nums = tileStr.dropFirst().compactMap { c -> Int? in
                guard let n = Int(String(c)) else { return nil }
                return n == 0 ? 5 : n
            }
            let limit = suit == "z" ? 7 : 9
            
            if isKan && nums.count == 4 && Set(nums).count == 1 {
                // 槓子（暗槓 or 明槓）
                let idx = nums[0] - 1
                guard idx >= 0 && idx < limit else { continue }
                if isAnkan {
                    bc.angangzi[suit]?[idx] += 1
                } else {
                    bc.minggangzi[suit]?[idx] += 1
                }
            } else if nums.count == 3 && Set(nums).count == 1 {
                // 刻子
                let idx = nums[0] - 1
                guard idx >= 0 && idx < limit else { continue }
                bc.mingkezi[suit]?[idx] += 1
            } else if nums.count == 3 && suit != "z" {
                // 順子
                let sorted = nums.sorted()
                guard sorted[1] == sorted[0] + 1, sorted[2] == sorted[0] + 2 else { continue }
                let idx = sorted[0] - 1
                guard idx >= 0 && idx < 7 else { continue }
                bc.shunzi[suit]?[idx] += 1
            }
        }
        return bc
    }
    
    // 2つの BlockCounts を加算して返す
    private static func addBlockCounts(_ a: BlockCounts, _ b: BlockCounts) -> BlockCounts {
        var result = a
        for suit in ["m", "p", "s"] {
            if let arr = b.shunzi[suit]     { for i in arr.indices { result.shunzi[suit]?[i]     += arr[i] } }
            if let arr = b.mingkezi[suit]   { for i in arr.indices { result.mingkezi[suit]?[i]   += arr[i] } }
            if let arr = b.ankezi[suit]     { for i in arr.indices { result.ankezi[suit]?[i]     += arr[i] } }
            if let arr = b.minggangzi[suit] { for i in arr.indices { result.minggangzi[suit]?[i] += arr[i] } }
            if let arr = b.angangzi[suit]   { for i in arr.indices { result.angangzi[suit]?[i]   += arr[i] } }
        }
        if let arr = b.mingkezi["z"]   { for i in arr.indices { result.mingkezi["z"]?[i]   += arr[i] } }
        if let arr = b.ankezi["z"]     { for i in arr.indices { result.ankezi["z"]?[i]     += arr[i] } }
        if let arr = b.minggangzi["z"] { for i in arr.indices { result.minggangzi["z"]?[i] += arr[i] } }
        if let arr = b.angangzi["z"]   { for i in arr.indices { result.angangzi["z"]?[i]   += arr[i] } }
        return result
    }
    
    private static func yakuForDecomposition(
        _ decomposition: BlockCounts,
        context: HuleContext,
        fulouBC: BlockCounts = BlockCounts()
    ) -> [Yaku] {
        
        var yaku: [Yaku] = []
        func add(_ y: Yaku?) { if let y { yaku.append(y) } }
        // 役満
        add(checkKokushi(decomposition, context))
        add(checkSuuankou(decomposition, context))
        add(checkDaisangen(decomposition, context))
        add(checkShousuushi(decomposition, context))
        add(checkDaisuushi(decomposition, context))
        add(checkTsuuiisou(decomposition, context))
        add(checkRyuuiisou(decomposition, context))
        add(checkChinroutou(decomposition, context))
        add(checkChuurenpoutou(decomposition, context))
        add(checkSuukantsu(decomposition, context))
        add(checkTianhu(decomposition, context))
        add(checkDihu(decomposition, context))
        
        if !yaku.isEmpty {return yaku}

        // 状況役
        add(checkLizhi(decomposition, context))
        add(checkDaburizhi(decomposition, context))
        add(checkYifa(decomposition, context))
        add(checkMenqianqingzimo(decomposition, context))
        add(checkQianggang(decomposition, context))
        add(checkLingshang(decomposition, context))
        add(checkHaidi(decomposition, context))
        add(checkHedi(decomposition, context))
        // 通常役（1翻）
        add(checkPinghu(decomposition, context))
        add(checkTanyao(decomposition, context))
        add(checkIipeiko(decomposition, context))
        checkYakuhai(decomposition, context).forEach { add($0) }
        add(checkSanshokuDoujun(decomposition, context))
        add(checkSanshokuDoukou(decomposition, context))
        add(checkIttsu(decomposition, context))
        add(checkChanta(decomposition, context))
        // 通常役（2翻〜）
        add(checkChiitoitsu(decomposition, context))
        add(checkToitoi(decomposition, context))
        add(checkSanankou(decomposition, context))
        add(checkSankantsu(decomposition, context))
        add(checkShousangen(decomposition, context))
        add(checkHonroutou(decomposition, context))
        add(checkRyanpeiko(decomposition, context))
        add(checkHonitsu(decomposition, context))
        add(checkJunchan(decomposition, context))
        add(checkChinitsu(decomposition, context))
        
        
        return yaku
    }
    
    
    // MARK: - 状況役
    
    private static func checkTianhu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.tianhu else { return nil }
        return Yaku(name: "天和", fanshu: Yaku.yakuman)
    }
    
    private static func checkDihu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.dihu else { return nil }
        return Yaku(name: "地和", fanshu: Yaku.yakuman)
    }
    
    private static func checkMenqianqingzimo(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.zimo && ctx.menqian else { return nil }
        return Yaku(name: "門前清自摸和", fanshu: 1)
    }
    
    private static func checkLizhi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.lizhi && !ctx.daburi else { return nil }
        return Yaku(name: "立直", fanshu: 1)
    }
    
    private static func checkDaburizhi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        // 門前のみ。立直とは複合しない（代わりにこちらが適用される）
        guard ctx.daburi else { return nil }
        return Yaku(name: "ダブル立直", fanshu: 2)
    }
    
    private static func checkYifa(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.yifa else { return nil }
        return Yaku(name: "一発", fanshu: 1)
    }
    
    private static func checkQianggang(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.qianggang else { return nil }
        return Yaku(name: "槍槓", fanshu: 1)
    }
    
    private static func checkLingshang(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.lingshang else { return nil }
        return Yaku(name: "嶺上開花", fanshu: 1)
    }
    
    private static func checkHaidi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.haidi && ctx.zimo else { return nil }
        return Yaku(name: "海底摸月", fanshu: 1)
    }
    
    private static func checkHedi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.hedi && !ctx.zimo else { return nil }
        return Yaku(name: "河底撈魚", fanshu: 1)
    }
    
    // MARK: - 通常役
    private static func checkPinghu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard checkPinghuCondition(decomposition: decomposition, context: ctx) else { return nil }
        return Yaku(name: "平和", fanshu: 1)
    }
    
    private static func checkTanyao(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nYaojiu == 0 else { return nil }
        guard ctx.kuitanAri || ctx.menqian else { return nil }
        return Yaku(name: "断么九", fanshu: 1)
    }
    
    private static func checkIipeiko(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.menqian else { return nil }
        let pairs = ["m", "p", "s"].reduce(0) { sum, suit in
            sum + (decomposition.shunzi[suit]?.reduce(0) { $0 + $1 / 2 } ?? 0)
        }
        // pairs==1なら一盃口、2以上なら二盃口（こちらは対象外）
        guard pairs == 1 else { return nil }
        return Yaku(name: "一盃口", fanshu: 1)
    }
    
    private static func checkYakuhai(_ decomposition: BlockCounts, _ ctx: HuleContext) -> [Yaku] {
        guard let zKezi   = decomposition.kezi["z"],
              let zGangzi = decomposition.gangzi["z"] else { return [] }
        let zBlocks = zip(zKezi, zGangzi).map { $0 + $1 }
        var result: [Yaku] = []
        let zhuangIdx = ctx.zhuangfeng.rawValue - 1  // 東=0,南=1,西=2,北=3
        let menIdx    = ctx.menfeng.rawValue - 1
        // 場風・自風（連風牌は2翻）
        if zBlocks[zhuangIdx] > 0 {
            if zhuangIdx == menIdx {
                result.append(Yaku(name: "連風牌（\(ctx.zhuangfeng.label)）", fanshu: 2))
            } else {
                result.append(Yaku(name: "場風（\(ctx.zhuangfeng.label)）", fanshu: 1))
            }
        }
        if menIdx != zhuangIdx && zBlocks[menIdx] > 0 {
            result.append(Yaku(name: "自風（\(ctx.menfeng.label)）", fanshu: 1))
        }
        // 三元牌: 白=index4, 發=index5, 中=index6
        for (i, name) in [(4, "白"), (5, "發"), (6, "中")] {
            if i < zBlocks.count && zBlocks[i] > 0 {
                result.append(Yaku(name: name, fanshu: 1))
            }
        }
        return result
    }
    
    private static func checkSanshokuDoujun(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        let m = decomposition.shunzi["m"] ?? []; let p = decomposition.shunzi["p"] ?? []; let s = decomposition.shunzi["s"] ?? []
        for i in 0..<min(m.count, min(p.count, s.count)) {
            if m[i] > 0 && p[i] > 0 && s[i] > 0 {
                return Yaku(name: "三色同順", fanshu: ctx.menqian ? 2 : 1)
            }
        }
        return nil
    }
    
    private static func checkSanshokuDoukou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        let m = decomposition.kezi["m"] ?? []; let p = decomposition.kezi["p"] ?? []; let s = decomposition.kezi["s"] ?? []
        for i in 0..<min(m.count, min(p.count, s.count)) {
            if m[i] > 0 && p[i] > 0 && s[i] > 0 {
                return Yaku(name: "三色同刻", fanshu: 2)
            }
        }
        return nil
    }
    
    private static func checkIttsu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        for suit in ["m", "p", "s"] {
            guard let arr = decomposition.shunzi[suit], arr.count >= 9 else { continue }
            if arr[0] > 0 && arr[3] > 0 && arr[6] > 0 {
                return Yaku(name: "一気通貫", fanshu: ctx.menqian ? 2 : 1)
            }
        }
        return nil
    }
    
    private static func checkChanta(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nYaojiu == 5  else { return nil }
        guard decomposition.nShunzi >= 1 else { return nil }  // 混老頭と区別
        // 字牌が1つ以上ある（純全帯么九と区別）
        let hasZipai = decomposition.nZipai >= 1 || decomposition.jantai.hasPrefix("z")
        guard hasZipai else { return nil }
        return Yaku(name: "混全帯么九", fanshu: ctx.menqian ? 2 : 1)
    }
    
    private static func checkChiitoitsu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.isChitoitsu() else { return nil }
        return Yaku(name: "七対子", fanshu: 2)
    }
    
    
    private static func checkToitoi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nShunzi == 0 && decomposition.nKezi == 4 else { return nil }
        return Yaku(name: "対対和", fanshu: 2)
    }
    
    private static func checkSanankou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nAnkezi + decomposition.nAngangzi >= 3 else { return nil }
        return Yaku(name: "三暗刻", fanshu: 2)
    }
    
    private static func checkSankantsu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nGangzi >= 3 else { return nil }
        return Yaku(name: "三槓子", fanshu: 2)
    }
    
    private static func checkShousangen(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard let zKezi = decomposition.kezi["z"] else { return nil }
        let dragonKezi = [4, 5, 6].filter { $0 < zKezi.count && zKezi[$0] > 0 }.count
        let dragonJantai = ["z5", "z6", "z7"].contains(decomposition.jantai)
        guard dragonKezi == 2 && dragonJantai else { return nil }
        return Yaku(name: "小三元", fanshu: 2)
    }
    
    private static func checkHonroutou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        if checkChiitoitsu(decomposition, ctx) == nil {
            guard decomposition.nYaojiu >= 5  else { return nil }
            guard decomposition.nShunzi == 0 else { return nil }  // 順子があると混老頭にならない
        } else{
            guard decomposition.nYaojiu >= 7   else { return nil }
        }
        return Yaku(name: "混老頭", fanshu: 2)
    }
    
    private static func checkRyanpeiko(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.menqian else { return nil }
        let pairs = ["m", "p", "s"].reduce(0) { sum, suit in
            sum + (decomposition.shunzi[suit]?.reduce(0) { $0 + $1 / 2 } ?? 0)
        }
        guard pairs >= 2 else { return nil }
        return Yaku(name: "二盃口", fanshu: 3)
    }
    
    private static func checkHonitsu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        let usedSuits = ["m", "p", "s"].filter { suit in
            (decomposition.shunzi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (decomposition.gangzi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (decomposition.kezi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (decomposition.toitsu[suit]?.reduce(0, +) ?? 0) > 0 ||
            decomposition.jantai.hasPrefix(suit)
        }
        let hasZipai = (decomposition.kezi["z"]?.reduce(0, +) ?? 0) > 0 ||
        (decomposition.toitsu["z"]?.reduce(0, +) ?? 0) > 0 ||
        decomposition.jantai.hasPrefix("z")
        guard usedSuits.count == 1 && hasZipai else { return nil }
        return Yaku(name: "混一色", fanshu: ctx.menqian ? 3 : 2)
    }
    
    private static func checkJunchan(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nYaojiu == 5 else { return nil }
        guard decomposition.nShunzi >= 1 else { return nil }  // 混老頭と区別
        guard decomposition.nZipai == 0 && !decomposition.jantai.hasPrefix("z") else { return nil }  // 字牌なし
        return Yaku(name: "純全帯么九", fanshu: ctx.menqian ? 3 : 2)
    }
    
    private static func checkChinitsu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        let usedSuits = ["m", "p", "s"].filter { suit in
            (decomposition.shunzi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (decomposition.gangzi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (decomposition.kezi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (decomposition.toitsu[suit]?.reduce(0, +) ?? 0) > 0 ||
            decomposition.jantai.hasPrefix(suit)
        }
        let hasZipai = (decomposition.kezi["z"]?.reduce(0, +) ?? 0) > 0 ||
        (decomposition.toitsu["z"]?.reduce(0, +) ?? 0) > 0 ||
        decomposition.jantai.hasPrefix("z")
        guard usedSuits.count == 1 && !hasZipai else { return nil }
        return Yaku(name: "清一色", fanshu: ctx.menqian ? 6 : 5)
    }
    
    // MARK: - 役満
    
    private static func checkKokushi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard  decomposition.isKokushimuso() else { return nil }
        if ctx.winTile == decomposition.jantai {
            return Yaku(name: "国士無双十三面待ち", fanshu: Yaku.doubleYakuman)
        }
        return Yaku(name: "国士無双", fanshu: Yaku.yakuman)
    }
    
    private static func checkSuuankou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nAnkezi + decomposition.nAngangzi == 4 else { return nil }
        if ctx.winTile == decomposition.jantai {
            return Yaku(name: "四暗刻単騎待ち", fanshu: Yaku.doubleYakuman)
        }
        return Yaku(name: "四暗刻", fanshu: Yaku.yakuman)
    }
    
    private static func checkDaisangen(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard let zKezi = decomposition.kezi["z"], let zGangzi = decomposition.gangzi["z"] else { return nil }
        guard [4, 5, 6].allSatisfy({ i in i < zKezi.count && (zKezi[i] + zGangzi[i]) > 0 }) else { return nil }
        return Yaku(name: "大三元", fanshu: Yaku.yakuman)
    }

    private static func checkShousuushi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard let zKezi = decomposition.kezi["z"], let zGangzi = decomposition.gangzi["z"] else { return nil }
        let windMentsu = (0..<4).filter { i in i < zKezi.count && (zKezi[i] + zGangzi[i]) > 0 }.count
        let windJantai = ["z1","z2","z3","z4"].contains(decomposition.jantai)
        guard windMentsu == 3 && windJantai else { return nil }
        return Yaku(name: "小四喜", fanshu: Yaku.yakuman)
    }

    private static func checkDaisuushi(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard let zKezi = decomposition.kezi["z"], let zGangzi = decomposition.gangzi["z"] else { return nil }
        guard (0..<4).allSatisfy({ i in i < zKezi.count && (zKezi[i] + zGangzi[i]) > 0 }) else { return nil }
        return Yaku(name: "大四喜", fanshu: Yaku.doubleYakuman)
    }

    private static func checkTsuuiisou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        for suit in ["m", "p", "s"] {
            let total = (decomposition.shunzi[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.kezi[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.gangzi[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.toitsu[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.isolated[suit]?.reduce(0, +) ?? 0)
            if total > 0 { return nil }
        }
        return Yaku(name: "字一色", fanshu: Yaku.yakuman)
    }

    private static func checkRyuuiisou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        // m/p があれば不成立
        for suit in ["m", "p"] {
            let total = (decomposition.shunzi[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.kezi[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.gangzi[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.toitsu[suit]?.reduce(0, +) ?? 0)
                      + (decomposition.isolated[suit]?.reduce(0, +) ?? 0)
            if total > 0 { return nil }
        }
        // s 順子は s234 (index 1) のみ許可
        if let arr = decomposition.shunzi["s"] {
            for (i, cnt) in arr.enumerated() where cnt > 0 { if i != 1 { return nil } }
        }
        // s 刻子・槓子・対子・孤立牌は s2,s3,s4,s6,s8 (index 1,2,3,5,7) のみ許可
        let allowedS: Set<Int> = [1, 2, 3, 5, 7]
        for arr in [decomposition.kezi["s"], decomposition.gangzi["s"], decomposition.toitsu["s"], decomposition.isolated["s"]] {
            guard let arr else { continue }
            for (i, cnt) in arr.enumerated() where cnt > 0 { if !allowedS.contains(i) { return nil } }
        }
        // z は 発 (z6, index 5) のみ許可
        for arr in [decomposition.kezi["z"], decomposition.gangzi["z"], decomposition.toitsu["z"], decomposition.isolated["z"]] {
            guard let arr else { continue }
            for (i, cnt) in arr.enumerated() where cnt > 0 { if i != 5 { return nil } }
        }
        return Yaku(name: "緑一色", fanshu: Yaku.yakuman)
    }

    private static func checkChinroutou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        // 字牌があれば不成立
        let zTotal = (decomposition.kezi["z"]?.reduce(0, +) ?? 0)
                   + (decomposition.gangzi["z"]?.reduce(0, +) ?? 0)
                   + (decomposition.toitsu["z"]?.reduce(0, +) ?? 0)
                   + (decomposition.isolated["z"]?.reduce(0, +) ?? 0)
        if zTotal > 0 { return nil }
        if decomposition.nShunzi > 0 { return nil }
        // m/p/s は 1 (index 0) または 9 (index 8) のみ許可
        let allowedIdx: Set<Int> = [0, 8]
        for suit in ["m", "p", "s"] {
            for arr in [decomposition.kezi[suit], decomposition.gangzi[suit], decomposition.toitsu[suit], decomposition.isolated[suit]] {
                guard let arr else { continue }
                for (i, cnt) in arr.enumerated() where cnt > 0 { if !allowedIdx.contains(i) { return nil } }
            }
        }
        return Yaku(name: "清老頭", fanshu: Yaku.yakuman)
    }

    private static func checkChuurenpoutou(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard ctx.menqian else { return nil }
        // winningDecompositions が生成した isolated マーカーを識別（国士無双と同方式）
        guard decomposition.nShunzi == 0 && decomposition.nKezi == 0 &&
              decomposition.nGangzi == 0 && decomposition.nToitsu == 0 else { return nil }
        guard (decomposition.isolated["z"]?.reduce(0, +) ?? 0) == 0 else { return nil }
        let usedSuits = ["m", "p", "s"].filter { (decomposition.isolated[$0]?.reduce(0, +) ?? 0) > 0 }
        guard usedSuits.count == 1, let suit = usedSuits.first else { return nil }
        guard let counts = decomposition.isolated[suit] else { return nil }
        let base = [3, 1, 1, 1, 1, 1, 1, 1, 3]
        guard zip(counts, base).allSatisfy({ $0.0 >= $0.1 }) else { return nil }
        // 純正: 和了牌を除いた13枚が基本形ちょうど
        var remaining = counts
        if let winSuit = ctx.winTile.first, String(winSuit) == suit,
           let winN = Int(String(ctx.winTile.last!)), winN >= 1 && winN <= 9 {
            remaining[winN - 1] -= 1
        }
        return remaining == base
            ? Yaku(name: "純正九蓮宝燈", fanshu: Yaku.doubleYakuman)
            : Yaku(name: "九蓮宝燈", fanshu: Yaku.yakuman)
    }
    
    private static func checkSuukantsu(_ decomposition: BlockCounts, _ ctx: HuleContext) -> Yaku? {
        guard decomposition.nGangzi == 4 else { return nil }
        return Yaku(name: "四槓子", fanshu: Yaku.yakuman)
    }
    
    // MARK: - buildHudi ヘルパー
    
    // 平和条件: 門前 + 全4面子が順子 + 役牌でない雀頭 + リャンメン待ち
    private static func checkPinghuCondition(
        decomposition: BlockCounts, context: HuleContext
    ) -> Bool {
        guard context.menqian else { return false }
        guard decomposition.nShunzi == 4 && decomposition.nKezi == 0 else { return false }
        guard !isYakuhai(decomposition.jantai, zhuangfeng: context.zhuangfeng, menfeng: context.menfeng) else { return false }
        return isRyanmenWait(decomposition: decomposition, winTile: context.winTile)
    }
    
    
    // 和了牌が順子のリャンメン端かどうか
    // winningDecompositions は mentsuOnly なので ryanmen 配列は空。
    // 代わりに完成順子から待ち形を逆算する。
    //
    // 順子 [lo, lo+1, lo+2] に対して:
    //   和了牌 == lo     → lo <= 6 ならリャンメン (lo+3 が存在する)
    //   和了牌 == lo+2   → lo >= 2 ならリャンメン (lo-1 が存在する)
    //   和了牌 == lo+1   → カンチャン待ち（平和不成立）
    private static func isRyanmenWait(decomposition: BlockCounts, winTile: String) -> Bool {
        guard winTile.count == 2,
              let suitChar = winTile.first,
              let n = Int(String(winTile.last!)),
              suitChar != "z" else { return false }
        let suit = String(suitChar)
        guard let arr = decomposition.shunzi[suit] else { return false }
        
        // 低端 (lo == n): arr[n-1] が存在し、n <= 6 でリャンメン
        if n >= 1 && n <= 6 && n - 1 < arr.count && arr[n - 1] > 0 { return true }
        
        // 高端 (lo == n-2): arr[n-3] が存在し、lo = n-2 >= 2 でリャンメン
        if n >= 4 && n - 3 < arr.count && arr[n - 3] > 0 { return true }
        
        return false
    }
    
    // 単騎待ち判定: アガリ牌が雀頭の牌と一致するか
    private static func checkDanqiCondition(decomposition: BlockCounts, winTile: String) -> Bool {
        guard winTile.count == 2,
              let num = Int(String(winTile.last!)), num >= 1 else { return false }
        let suit = String(winTile.first!)
        let idx  = num - 1
        let limit = suit == "z" ? 7 : 9
        guard idx < limit else { return false }
        return (decomposition.toitsu[suit]?[idx] ?? 0) > 0
    }
    
    // 么九牌（1,9,字牌）かどうか
    private static func isYaojiu(_ tile: String) -> Bool {
        guard tile.count == 2 else { return false }
        if tile.first == "z" { return true }
        guard let num = Int(String(tile.last!)) else { return false }
        return num == 1 || num == 9
    }
    
    // 役牌（場風・自風・三元牌）かどうか
    private static func isYakuhai(_ tile: String, zhuangfeng: Feng, menfeng: Feng) -> Bool {
        guard tile.count == 2, tile.first == "z",
              let num = Int(String(tile.last!)) else { return false }
        return num >= 5 || num == zhuangfeng.rawValue || num == menfeng.rawValue
    }
    
    // MARK: - リーチ後暗槓フィルタ

    // リーチ中に暗槓できる牌ラベルを riichiAnkanLevel に基づいて返す
    // bingpaiLabels: リーチ中の13枚手牌（visibleLabels）
    // gangziCandidates: shoupai.gangzi（手牌14枚中4枚揃い候補）
    static func validAngangLabels(
        bingpaiLabels: [String],
        fulouTiles: [String],
        gangziCandidates: [String],
        level: GameSettings.RiichiAnkanLevel
    ) -> [String] {
        if level == .allForbidden { return [] }

        let allLabels = (1...9).flatMap { n in ["m","p","s"].map { "\($0)\(n)" } }
                      + (1...7).map { "z\($0)" }
        let currentWaits = Set(allLabels.filter { xiangting(bingpaiLabels + [$0]) == -1 })

        return gangziCandidates.filter { g in
            let norm = Pai.normalize(g)
            // bingpaiから3枚除いた10枚が新たな待ちの基準
            var removed = 0
            let remaining = bingpaiLabels.filter { t in
                if removed < 3 && Pai.normalize(t) == norm { removed += 1; return false }
                return true
            }
            let newWaits = Set(allLabels.filter { xiangting(remaining + [$0]) == -1 })
            guard newWaits == currentWaits else { return false }

            if level == .noChangeHand {
                // 牌姿が変わらない: すべての和了形分解でgが必ず刻子になること
                let suit = String(norm.prefix(1))
                guard let n = Int(String(norm.last!)) else { return false }
                let idx = n - 1
                for w in currentWaits {
                    let sorted = (bingpaiLabels + [w]).map { Pai.normalize($0) }.sorted()
                    let decomps = winningDecompositions(sorted, fulouTiles)
                    for decomp in decomps {
                        // 順子に使われているか
                        if suit != "z" {
                            let shunzi = decomp.shunzi[suit] ?? []
                            let inShunzi = (max(0, idx-2)...min(6, idx)).contains {
                                $0 < shunzi.count && shunzi[$0] > 0
                            }
                            if inShunzi { return false }
                        }
                        // 雀頭に使われているか
                        let toitsu = decomp.toitsu[suit] ?? []
                        if idx < toitsu.count && toitsu[idx] > 0 { return false }
                    }
                }
            }
            return true
        }
    }

    // MARK: - 点数計算

    // 符・役 → 点数変動を計算する
    // winnerIdx: 和了プレイヤー index, loserIdx: ロン放銃者(ツモ時nil), dealerIdx: 東家index
    static func computeDefen(
        fu: Int,
        yaku: [Yaku],
        zimo: Bool,
        winnerIdx: Int,
        loserIdx: Int?,
        dealerIdx: Int,
        honba: Int,
        lizhibang: Int,
        yakumanFukugouAri: Bool = true,
        doubleYakumanAri: Bool = true,
        kazoeYakumanAri: Bool = true,
        kiriageMangan: Bool = false,
        paoPlayerIdx: Int? = nil
    ) -> DefenResult {
        guard !yaku.isEmpty else {
            return DefenResult(defen: 0, fenpei: Array(repeating: 0, count: 4), effectiveFan: 0)
        }

        // ダブル役満なし: fanshu を役満上限に丸める
        let adjustedYaku: [Yaku] = doubleYakumanAri ? yaku : yaku.map {
            $0.fanshu >= Yaku.doubleYakuman ? Yaku(name: $0.name, fanshu: Yaku.yakuman) : $0
        }
        let rawFan        = adjustedYaku.reduce(0) { $0 + $1.fanshu }
        let maxYakuFanshu = adjustedYaku.map(\.fanshu).max() ?? 0

        // 役満の複合なし: 合計を最大単一役の翻数に制限
        var effectiveFan = rawFan
        if !yakumanFukugouAri && effectiveFan >= Yaku.yakuman {
            effectiveFan = min(effectiveFan, maxYakuFanshu)
        }
        // 数え役満なし: 13翻以上の通常手は三倍満扱い
        if !kazoeYakumanAri && effectiveFan >= 13 && effectiveFan < Yaku.yakuman {
            effectiveFan = 12
        }

        let isDealer = (winnerIdx == dealerIdx)
        let table    = paymentTable(fu: fu, fan: effectiveFan, kiriageMangan: kiriageMangan)

        // MARK: パオ（包）計算
        if let paoIdx = paoPlayerIdx, effectiveFan >= Yaku.yakuman {
            let paoTable  = paymentTable(fu: fu, fan: Yaku.yakuman) // 役満1つ分の基準額
            var fenpei    = Array(repeating: 0, count: 4)
            let defen: Int

            if zimo {
                // 責任払い: パオ者がロン相当額+積み場を全額負担し、残余翻数は通常ツモ精算
                let paoRonAmt = isDealer ? paoTable[3] : paoTable[0]
                let paoPayment = paoRonAmt + honba * 300

                if effectiveFan <= Yaku.yakuman {
                    // 役満ちょうど: パオ者のみ全額
                    defen = paoPayment + lizhibang * 1000
                    fenpei[winnerIdx] += defen
                    fenpei[paoIdx]    -= paoPayment
                } else {
                    // ダブル役満以上: パオ者が役満1つ分+積み場を払い、残りは通常ツモ（積み場なし）
                    let remainFan   = effectiveFan - Yaku.yakuman
                    let remainTable = paymentTable(fu: fu, fan: remainFan)
                    var remainDefen = 0
                    if isDealer {
                        let perChild = remainTable[4]
                        remainDefen = perChild * 3
                        for i in 0..<4 where i != winnerIdx { fenpei[i] -= perChild }
                    } else {
                        let forDealer = remainTable[1]
                        let forChild  = remainTable[2]
                        remainDefen = forDealer + forChild * 2
                        for i in 0..<4 where i != winnerIdx {
                            fenpei[i] -= (i == dealerIdx ? forDealer : forChild)
                        }
                    }
                    fenpei[paoIdx] -= paoPayment
                    defen = paoPayment + remainDefen + lizhibang * 1000
                    fenpei[winnerIdx] += defen
                }
            } else {
                // 折半払い: 放銃者とパオ者で均等割り。パオ者が積み場を負担
                let ronAmt  = isDealer ? table[3] : table[0]
                let half    = ronAmt / 2
                let loser   = loserIdx!
                defen = ronAmt + honba * 300 + lizhibang * 1000
                fenpei[winnerIdx] += defen
                if paoIdx == loser {
                    // 放銃者＝パオ者: 全額+積み場
                    fenpei[loser] -= ronAmt + honba * 300
                } else {
                    fenpei[loser]  -= half
                    fenpei[paoIdx] -= (ronAmt - half) + honba * 300
                }
            }

            return DefenResult(defen: defen, fenpei: fenpei, effectiveFan: effectiveFan)
        }

        // MARK: 通常計算
        // [子ロン, 子ツモ親払い, 子ツモ子払い, 親ロン, 親ツモ子払い]
        let koRon       = table[0]
        let koTsumoOya  = table[1]
        let koTsumoKo   = table[2]
        let oyaRon      = table[3]
        let oyaTsumoKo  = table[4]

        var fenpei = Array(repeating: 0, count: 4)
        let defen: Int

        if isDealer && !zimo {
            // ① 親のロンアガリ: 放銃者が oyaRon を払う
            let loser   = loserIdx!
            let payment = oyaRon
            defen = payment + honba * 300 + lizhibang * 1000
            fenpei[winnerIdx] += defen
            fenpei[loser]     -= payment + honba * 300
            
        } else if isDealer && zimo {
            // ② 親のツモアガリ: 子3人が oyaTsumoKo ずつ払う
            defen = oyaTsumoKo * 3 + honba * 300 + lizhibang * 1000
            fenpei[winnerIdx] += defen
            for i in 0..<4 where i != winnerIdx {
                fenpei[i] -= oyaTsumoKo + honba * 100
            }
            
        } else if !isDealer && !zimo {
            // ③ 子のロンアガリ: 放銃者が koRon を払う
            let loser   = loserIdx!
            let payment = koRon
            defen = payment + honba * 300 + lizhibang * 1000
            fenpei[winnerIdx] += defen
            fenpei[loser]     -= payment + honba * 300
            
        } else {
            // ④ 子のツモアガリ: 親が koTsumoOya、他の子が koTsumoKo を払う
            defen = koTsumoOya + koTsumoKo * 2 + honba * 300 + lizhibang * 1000
            fenpei[winnerIdx] += defen
            for i in 0..<4 where i != winnerIdx {
                fenpei[i] -= (i == dealerIdx ? koTsumoOya : koTsumoKo) + honba * 100
            }
        }
        
        return DefenResult(defen: defen, fenpei: fenpei, effectiveFan: effectiveFan)
    }
    
    private static func ceil100(_ value: Int) -> Int {
        return ((value + 99) / 100) * 100
    }
    
    // [子ロン, 子ツモ親払い, 子ツモ子払い, 親ロン, 親ツモ子払い]
    // fan には computeDefen で設定反映済みの有効翻数を渡す
    static func paymentTable(fu: Int, fan: Int, kiriageMangan: Bool = false) -> [Int] {
        let fixedBase: Int? = {
            // 切り上げ満貫: 基本点が7500以上8000未満なら満貫扱い
            if kiriageMangan && fan >= 1 && fan < 5 {
                let base = 32 * fu * (1 << (fan - 1))
                if base >= 7500 && base < 8000 { return 8000 }
            }
            switch fan {
            case 5:       return 8000
            case 6, 7:    return 12000
            case 8, 9, 10: return 16000
            case 11, 12:  return 24000
            case 13..<99: return 32000
            case 100...:  return fan / 100 * 32000
            default: return nil
            }
        }()

        func pay(coefficient: Double, divisor: Double) -> Int {
            if let base = fixedBase {
                return Int((Double(base) * coefficient / divisor).rounded())
            }
            let raw = Int(Double(32 * fu * (1 << (fan - 1))) * coefficient / divisor)
            let cap = Int((8000.0 * coefficient / divisor).rounded())
            return min(ceil100(raw), cap)
        }

        return [
            pay(coefficient: 1.0, divisor: 1.0),  // 子ロン
            pay(coefficient: 1.0, divisor: 2.0),  // 子ツモ 親払い
            pay(coefficient: 1.0, divisor: 4.0),  // 子ツモ 子払い
            pay(coefficient: 1.5, divisor: 1.0),  // 親ロン
            pay(coefficient: 1.5, divisor: 3.0),  // 親ツモ 子払い
        ]
    }
    
    // MARK: - 符計算
    // 符合計を計算して10符単位に切り上げる
    private static func computeFu(
        decomposition: BlockCounts,
        context: HuleContext
    ) -> Int {
        // 七対子は25符固定
        if decomposition.nToitsu == 7 {return 25}
        
        var fu = 20
        
        let danqi = checkDanqiCondition(decomposition: decomposition, winTile: context.winTile)
        let pinghu = checkPinghuCondition(decomposition: decomposition, context: context)
        
        // 雀頭符・単騎符
        fu += jantaiFu(jantai: decomposition.jantai, danqi: danqi,
                       zhuangfeng: context.zhuangfeng, menfeng: context.menfeng,
                       renpuFu: context.renpuFu)
        
        // 刻子符
        fu += keziTotalFu(decomposition: decomposition)
        
        // 待ち符（カンチャン・ペンチャン）
        fu += waitFu(decomposition: decomposition, winTile: context.winTile, danqi: danqi)
        
        // ツモ・ロン補正
        if context.zimo {
            if !pinghu { fu += 2 }           // ツモ符（平和はなし）
        } else {
            if context.menqian { fu += 10 }  // 門前ロン
            else if fu == 20   { fu  = 30 }  // 副露で符なし → 最低30符
        }
        
        return ((fu + 9) / 10) * 10
    }
    
    
    // 雀頭符: 役牌対子 +2、連風対子 +renpuFu、単騎 +2
    private static func jantaiFu(jantai: String, danqi: Bool,
                                 zhuangfeng: Feng, menfeng: Feng, renpuFu: Int) -> Int {
        var fu = danqi ? 2 : 0
        guard jantai.count == 2, jantai.first == "z",
              let n = Int(String(jantai.last!)) else { return fu }
        let isZhuang = n == zhuangfeng.rawValue
        let isMen    = n == menfeng.rawValue
        if isZhuang && isMen {
            fu += renpuFu  // 連風牌: 設定値 (2 or 4)
        } else {
            if isZhuang { fu += 2 }
            if isMen    { fu += 2 }
        }
        if n >= 5 { fu += 2 }  // 三元牌 (白z5/發z6/中z7)
        return fu
    }
    
    // 刻子符: 明刻中張=2, 明刻么九=4, 暗刻中張=4, 暗刻么九=8
    // 槓子符: 明槓中張=8, 明槓么九=16, 暗槓中張=16, 暗槓么九=32
    private static func keziTotalFu(decomposition: BlockCounts) -> Int {
        var fu = 0
        for suit in ["m", "p", "s", "z"] {
            // 明刻: 中張=2, 么九=4
            if let arr = decomposition.mingkezi[suit] {
                for (i, cnt) in arr.enumerated() where cnt > 0 {
                    let isYaojiu = (suit == "z") || (i == 0) || (i == 8)
                    fu += (isYaojiu ? 4 : 2) * cnt
                }
            }
            // 暗刻: 中張=4, 么九=8
            if let arr = decomposition.ankezi[suit] {
                for (i, cnt) in arr.enumerated() where cnt > 0 {
                    let isYaojiu = (suit == "z") || (i == 0) || (i == 8)
                    fu += (isYaojiu ? 8 : 4) * cnt
                }
            }
            // 明槓: 中張=8, 么九=16
            if let arr = decomposition.minggangzi[suit] {
                for (i, cnt) in arr.enumerated() where cnt > 0 {
                    let isYaojiu = (suit == "z") || (i == 0) || (i == 8)
                    fu += (isYaojiu ? 16 : 8) * cnt
                }
            }
            // 暗槓: 中張=16, 么九=32
            if let arr = decomposition.angangzi[suit] {
                for (i, cnt) in arr.enumerated() where cnt > 0 {
                    let isYaojiu = (suit == "z") || (i == 0) || (i == 8)
                    fu += (isYaojiu ? 32 : 16) * cnt
                }
            }
        }
        return fu
    }
    
    // 待ち符: カンチャン +2、ペンチャン +2、リャンメン/シャンポン/単騎 0
    // 単騎は jantaiFu で計上するためここでは 0
    private static func waitFu(decomposition: BlockCounts, winTile: String, danqi: Bool) -> Int {
        if danqi { return 0 }
        guard winTile.count == 2,
              let suitChar = winTile.first,
              let n = Int(String(winTile.last!)),
              suitChar != "z" else { return 0 }
        let suit = String(suitChar)
        guard let arr = decomposition.shunzi[suit] else { return 0 }
        
        // カンチャン: winTile が順子 {n-1, n, n+1} の真ん中 (index = n-2)
        if n >= 2 && n <= 8 {
            let idx = n - 2
            if idx < arr.count && arr[idx] > 0 { return 2 }
        }
        
        // ペンチャン: 1-2-3 で 3 待ち (index 0) / 7-8-9 で 7 待ち (index 6)
        if n == 3 && arr.count > 0 && arr[0] > 0 { return 2 }
        if n == 7 && arr.count > 6 && arr[6] > 0 { return 2 }
        
        return 0
    }
}


// MARK: - Result
@Observable
class Result {


    var huleResult: HuleResult? = nil
    var summaryResult: SummaryResult? = nil
    var roundHistory: [RoundRecord] = []

}


// MARK: - SummaryResult
struct SummaryResult {
    var roundHistory: [RoundRecord]
    var finalScores: [(feng: Feng, points: Int)]  // プレイヤー index 順
    var finalPoints: [Double]                            // ウマ・オカ込み最終ポイント
}

// MARK: - HuleResult
struct HuleResult {
    enum Kind { case zimo, rong, pingju, kyuushu, suufon, suuchaRiichi, suukanSanyou, sanchahou, nagashiMangan }

    var kind: Kind
    var hulePlayer: Int?       // 和了プレイヤー index（流局時は nil）
    var bingpai: [Pai]         // 手牌（表示用・hidden除去済み）
    var fulou: [[Pai]] = []    // 副露グループ（表示順）
    var winTile: Pai?          // 和了牌（ツモ牌 or ロン牌）
    var baopai: [Pai]          // ドラ表示牌
    var libaopai: [Pai] = []   // 裏ドラ表示牌（リーチ和了時のみ）
    var hupai: [(name: String, fan: Int)] = []  // 役一覧（未実装時は空）
    var fu: Int = 0
    var totalFan: Int = 0
    var points: Int = 0
    var tenpaiPlayers: [Int] = []         // テンパイプレイヤー index（流局時のみ使用）
    var nagashiManganPlayers: [Int] = []  // 流し満貫成立プレイヤー index
    var scoreChanges: [Int]    // 各プレイヤーの得点変動 [0...3]（未実装時は 0）
    var afterScores: [(feng: Feng, points: Int)]  // 変動後の得点
    var honba: Int
    var lizhibang: Int
}

extension HuleResult.Kind {
    /// 流局かどうか
    var isPingju: Bool {
        switch self {
        case .zimo, .rong, .nagashiMangan: return false
        default:                           return true
        }
    }

    /// 流局種別のラベル（GameResultViewの局履歴などで使用）。和了の場合は nil
    var pingjuLabel: String? {
        switch self {
        case .pingju:           return "流局"
        case .kyuushu:          return "九種九牌"
        case .suufon:           return "四風連打"
        case .suuchaRiichi:     return "四家立直"
        case .suukanSanyou:     return "四槓散了"
        case .sanchahou:        return "三家和"
        case .nagashiMangan:    return "流し満貫"
        case .zimo, .rong:      return nil
        }
    }

    /// 途中流局のサブタイトル（RoundResultViewで「流局」の下に表示）。通常流局・和了は nil
    var pingjuSubtitle: String? {
        switch self {
        case .kyuushu:      return "九種九牌"
        case .suufon:       return "四風連打"
        case .suuchaRiichi: return "四家立直"
        case .suukanSanyou: return "四槓散了"
        case .sanchahou:    return "三家和"
        default:            return nil
        }
    }
}


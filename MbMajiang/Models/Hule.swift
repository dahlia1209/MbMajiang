//
//  Hule.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/11.
//

import Foundation



// MARK: - Hudi（面子分解 + 符情報）
struct Hudi {
    var fu: Int                     // 符合計
    var menqian: Bool               // 門前か
    var zimo: Bool                  // ツモ和了か
    var shunzi: [String: [Int]]     // 順子 (m/p/s): 開始番号-1 が index (有効 0〜6)
    var kezi:   [String: [Int]]     // 刻子 (m/p/s/z): 牌番号-1 が index
    var toitsu: [String: [Int]]     // 対子 (m/p/s/z): 牌番号-1 が index（七対子のスート判定に使用）
    var nShunzi: Int                // 順子の総数
    var nKezi:   Int                // 刻子（槓子含む）の総数
    var nAnkezi: Int                // 暗刻（暗槓含む）の総数
    var nGangzi: Int                // 槓子の総数
    var nYaojiu: Int                // 么九牌を含む面子の数
    var nZipai:  Int                // 字牌を含む面子の数
    var danqi:   Bool               // 単騎待ちか
    var pinghu:  Bool               // 平和か
    var zhuangfeng: Feng            // 場風
    var menfeng:    Feng            // 自風
    var jantai: String              // 雀頭牌ラベル（役判定用）
}

// MARK: - BlockCounts（ブロック種別×スートのカウント配列）
struct BlockCounts: Hashable {
    var shunzi:   [String: [Int]]  // 順子 (m/p/s): 開始番号-1 が index (有効 0〜6)
    var kezi:     [String: [Int]]  // 刻子 (m/p/s/z): 牌番号-1 が index
    var ryanmen:  [String: [Int]]  // リャンメン (m/p/s): 低い方の番号-1 が index (有効 1〜6)
    var penchan:  [String: [Int]]  // ペンチャン (m/p/s): 低い方の番号-1 が index (有効 0, 7)
    var kanchan:  [String: [Int]]  // カンチャン (m/p/s): 低い方の番号-1 が index (有効 0〜6)
    var toitsu:   [String: [Int]]  // 対子 (m/p/s/z): 牌番号-1 が index
    var isolated: [String: [Int]]  // 孤立牌 (m/p/s/z): 牌番号-1 が index
    
    init() {
        let s9 = [Int](repeating: 0, count: 9)
        let s7 = [Int](repeating: 0, count: 7)
        shunzi   = ["m": s9, "p": s9, "s": s9]
        kezi     = ["m": s9, "p": s9, "s": s9, "z": s7]
        ryanmen  = ["m": s9, "p": s9, "s": s9]
        penchan  = ["m": s9, "p": s9, "s": s9]
        kanchan  = ["m": s9, "p": s9, "s": s9]
        toitsu   = ["m": s9, "p": s9, "s": s9, "z": s7]
        isolated = ["m": s9, "p": s9, "s": s9, "z": s7]
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
}

// MARK: - Yaku（役）
struct Yaku {
    let name: String
    let fanshu: Int  // 翻数（役満=13, ダブル役満=26）

    static let yakuman = 13
    static let doubleYakuman = 26
}

// MARK: - DefenResult（点数計算結果）
struct DefenResult {
    let defen: Int      // 勝者の獲得点数（本場・供託込み）
    let fenpei: [Int]   // 各プレイヤーの点数変動 [0...3]
}

// MARK: - Hule
struct Hule {
    
    // 赤牌を通常牌に正規化 (m0→m5, p0→p5, s0→s5)
    static func normalize(_ label: String) -> String {
        guard label.count == 2, label.last == "0" else { return label }
        return "\(label.first!)5"
    }
    
    // 和了判定（正規化済みまたは未正規化の14枚）
    static func isHule(_ tiles: [String]) -> Bool {
        let t = tiles.map { normalize($0) }.sorted()
        // 14枚 or 副露後の 11/8/5/2 枚を許容
        guard t.count >= 2 && (t.count - 2) % 3 == 0 else { return false }

        // 七対子・国士は門前（14枚）のみ
        if t.count == 14 {
            var counts: [String: Int] = [:]
            for tile in t { counts[tile, default: 0] += 1 }

            // 七対子: 7種類の対子（同一牌4枚は不可）
            if counts.count == 7 && counts.values.allSatisfy({ $0 == 2 }) { return true }

            // 国士無双: 么九牌13種 + そのうち1種を対子
            let yaojiu = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
            if yaojiu.allSatisfy({ counts[$0, default: 0] >= 1 }) &&
               yaojiu.contains(where: { counts[$0, default: 0] >= 2 }) { return true }
        }

        // メンツ形: winningDecompositions が1件以上あれば和了
        return !winningDecompositions(t).isEmpty
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
        return 6 - pairCount
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
            current.kezi[suit]?[p] += 1
            extractBlockCounts(suit: suit, &counts, p, canSeq, mentsuOnly: mentsuOnly, &current, &results)
            current.kezi[suit]?[p] -= 1
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
        result.kezi["m"]     = m.kezi["m"]!;    result.kezi["p"]     = p.kezi["p"]!;    result.kezi["s"]     = s.kezi["s"]!;   result.kezi["z"]     = z.kezi["z"]!
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
    
    // 14枚の和了形を面子分解し、「順子・刻子 4組 + 対子 1組」の全パターンを返す
    // mentsuOnly: true でターツ・孤立牌の枝を再帰中に打ち切るため効率的
    static func winningDecompositions(_ tiles: [String]) -> [BlockCounts] {
        // 14枚 or 副露後の 11/8/5/2 枚を許容
        guard tiles.count >= 2 && (tiles.count - 2) % 3 == 0 else { return [] }
        let requiredMentsu = (tiles.count - 2) / 3  // 14枚→4, 11枚→3, 8枚→2 ...
        let sc = tilesToSuitCounts(tiles)
        let mR = extractSuitBlocks(sc.m, suit: "m", canSeq: true,  mentsuOnly: true)
        let pR = extractSuitBlocks(sc.p, suit: "p", canSeq: true,  mentsuOnly: true)
        let sR = extractSuitBlocks(sc.s, suit: "s", canSeq: true,  mentsuOnly: true)
        let zR = extractSuitBlocks(sc.z, suit: "z", canSeq: false, mentsuOnly: true)
        let sum = { (d: [String: [Int]]) in d.values.flatMap { $0 }.reduce(0, +) }
        var seen = Set<BlockCounts>()
        var results: [BlockCounts] = []
        for bm in mR { for bp in pR { for bs in sR { for bz in zR {
            let merged = mergeBlockCounts(m: bm, p: bp, s: bs, z: bz)
            guard sum(merged.shunzi) + sum(merged.kezi) == requiredMentsu,
                  sum(merged.toitsu) == 1 else { continue }
            if seen.insert(merged).inserted { results.append(merged) }
        }}}}
        return results
    }

    // enumerateBlocks を使ったメンツ形シャンテン数
    static func mianziXiangting(_ tiles: [String]) -> Int {
        
        guard tiles.count >= 1 && (13 - tiles.count) % 3 == 0
        else { return 99 }
        
        let suitCounts = tilesToSuitCounts(tiles)
        let combinations = enumerateBlocks(suitCounts: suitCounts)
        
        let base = 8 - (13-tiles.count)*2
        var minShanten = base
        
        let sum = { (d: [String: [Int]]) in d.values.flatMap { $0 }.reduce(0, +) }
        for bc in combinations {
            let mentsu = sum(bc.shunzi) + sum(bc.kezi)
            let toitsu = sum(bc.toitsu)
            let tatsu  = sum(bc.ryanmen) + sum(bc.penchan) + sum(bc.kanchan)
            
            let cap = 4  - mentsu
            
            // 雀頭なし: 対子はすべて搭子として計上
            let s1 = base - 2 * mentsu - min(tatsu + toitsu, cap)
            // 雀頭あり: 対子を1つ雀頭に充て、残りを搭子として計上
            let s2 = toitsu > 0 ? base - 2 * mentsu - min(tatsu + toitsu - 1, cap) - 1 : s1
            
            minShanten = min(minShanten, min(s1, s2))
        }
        
        return minShanten
    }

}

// MARK: - 役計算
extension Hule {

    // tiles（手牌）+ 局面情報 + 副露グループ から役・符を返す
    // 七対子は25符固定。通常形は全面子分解を試し最高翻数の組み合わせを採用。
    // fulouGroups: 副露面子のラベル配列（例: [["z7","z7","z7"]]）
    static func getYaku(
        tiles: [String],
        context: HuleContext,
        fulouGroups: [[String]] = []
    ) -> (yaku: [Yaku], fu: Int) {
        let normalized = tiles.map { normalize($0) }.sorted()
        let fulouBC = fulouBlockCounts(fulouGroups)

        // 七対子チェック（門前のみ、副露なし）
        if fulouGroups.isEmpty {
            var tileCounts: [String: Int] = [:]
            for t in normalized { tileCounts[t, default: 0] += 1 }
            if tileCounts.count == 7 && tileCounts.values.allSatisfy({ $0 == 2 }) {
                let decompositions = chiitoitsuDecompositions(tileCounts)
                let best = decompositions
                    .map { yakuForDecomposition($0, context: context, fulouBC: fulouBC) }
                    .max(by: { $0.0.reduce(0) { $0 + $1.fanshu } < $1.0.reduce(0) { $0 + $1.fanshu } })
                return (yaku: best?.0 ?? [], fu: 25)
            }
        }

        // 通常面子形
        let decompositions = winningDecompositions(normalized)
        guard !decompositions.isEmpty else { return (yaku: [], fu: 30) }

        let candidates = decompositions.map { d -> ([Yaku], Int) in
            let (yaku, hudi) = yakuForDecomposition(d, context: context, fulouBC: fulouBC)
            return (yaku, hudi.fu)
        }
        let best = candidates.max(by: {
            $0.0.reduce(0) { $0 + $1.fanshu } < $1.0.reduce(0) { $0 + $1.fanshu }
        })
        return (yaku: best?.0 ?? [], fu: best?.1 ?? 30)
    }

    // 副露グループ（ラベル配列）を BlockCounts に変換する
    // 刻子（同牌3枚）と順子（連番3枚）を認識する
    private static func fulouBlockCounts(_ fulouGroups: [[String]]) -> BlockCounts {
        var bc = BlockCounts()
        for group in fulouGroups {
            let norms = group.map { normalize($0) }.filter { $0 != "_" && $0.count == 2 }
            guard norms.count >= 3 else { continue }
            let tiles3 = Array(norms.prefix(3))
            let unique = Set(tiles3)
            if unique.count == 1 {
                // 刻子
                let tile = tiles3[0]
                guard let suitChar = tile.first,
                      let num = Int(String(tile.last!)), num >= 1 else { continue }
                let suit = String(suitChar)
                let idx = num - 1
                let limit = suit == "z" ? 7 : 9
                guard idx < limit else { continue }
                bc.kezi[suit]?[idx] += 1
            } else {
                // 順子
                let suits = tiles3.compactMap { $0.first.map(String.init) }
                let nums  = tiles3.compactMap { Int(String($0.last!)) }.sorted()
                guard Set(suits).count == 1, suits[0] != "z",
                      nums.count == 3, nums[1] == nums[0] + 1, nums[2] == nums[0] + 2 else { continue }
                let suit = suits[0]
                let idx  = nums[0] - 1
                guard idx >= 0 && idx < 7 else { continue }
                bc.shunzi[suit]?[idx] += 1
            }
        }
        return bc
    }

    // 2つの BlockCounts を加算して返す（shunzi / kezi のみ）
    private static func addBlockCounts(_ a: BlockCounts, _ b: BlockCounts) -> BlockCounts {
        var result = a
        for suit in ["m", "p", "s"] {
            if let arr = b.shunzi[suit] { for i in arr.indices { result.shunzi[suit]?[i] += arr[i] } }
            if let arr = b.kezi[suit]   { for i in arr.indices { result.kezi[suit]?[i]   += arr[i] } }
        }
        if let arr = b.kezi["z"] { for i in arr.indices { result.kezi["z"]?[i] += arr[i] } }
        return result
    }

    private static func yakuForDecomposition(
        _ decomposition: BlockCounts,
        context: HuleContext,
        fulouBC: BlockCounts = BlockCounts()
    ) -> ([Yaku], Hudi) {
        let hudi = buildHudi(decomposition: decomposition, fulouBC: fulouBC, context: context)
        var yaku: [Yaku] = []
        func add(_ y: Yaku?) { if let y { yaku.append(y) } }

        // 状況役
        add(checkTianhu(hudi, context))
        add(checkDihu(hudi, context))
        add(checkMenqianqingzimo(hudi, context))
        add(checkLizhi(hudi, context))
        add(checkDaburizhi(hudi, context))
        add(checkYifa(hudi, context))
        add(checkQianggang(hudi, context))
        add(checkLingshang(hudi, context))
        add(checkHaidi(hudi, context))
        add(checkHedi(hudi, context))
        // 通常役（1翻）
        add(checkPinghu(hudi, context))
        add(checkTanyao(hudi, context))
        add(checkIipeiko(hudi, context))
        checkYakuhai(hudi, context).forEach { add($0) }
        add(checkSanshokuDoujun(hudi, context))
        add(checkSanshokuDoukou(hudi, context))
        add(checkIttsu(hudi, context))
        add(checkChanta(hudi, context))
        add(checkChiitoitsu(hudi, context))
        // 通常役（2翻〜）
        add(checkToitoi(hudi, context))
        add(checkSanankou(hudi, context))
        add(checkSankantsu(hudi, context))
        add(checkShousangen(hudi, context))
        add(checkHonroutou(hudi, context))
        add(checkRyanpeiko(hudi, context))
        add(checkHonitsu(hudi, context))
        add(checkJunchan(hudi, context))
        add(checkChinitsu(hudi, context))
        // 役満
        add(checkKokushi(hudi, context))
        add(checkSuuankou(hudi, context))
        add(checkDaisangen(hudi, context))
        add(checkShousuushi(hudi, context))
        add(checkDaisuushi(hudi, context))
        add(checkTsuuiisou(hudi, context))
        add(checkRyuuiisou(hudi, context))
        add(checkChinroutou(hudi, context))
        add(checkChuurenpoutou(hudi, context))
        add(checkSuukantsu(hudi, context))

        return (yaku, hudi)
    }

    // MARK: - Hudi 構築

    private static func buildHudi(
        decomposition: BlockCounts,   // 手牌の面子分解
        fulouBC: BlockCounts = BlockCounts(),  // 副露面子のブロック
        context: HuleContext
    ) -> Hudi {
        let sum = { (d: [String: [Int]]) in d.values.flatMap { $0 }.reduce(0, +) }

        // 手牌 + 副露をマージした合計でカウント
        let merged  = addBlockCounts(decomposition, fulouBC)
        let nShunzi = sum(merged.shunzi)
        let nKezi   = sum(merged.kezi)

        // 手牌内の刻子はすべて暗刻、副露刻子は明刻
        let nAnkezi = sum(decomposition.kezi)

        let jantai  = findJantai(decomposition: decomposition)   // 雀頭は手牌から
        let nYaojiu = countYaojiuMentsu(decomposition: merged)
        let nZipai  = countZipaiMentsu(decomposition: merged)

        let pinghu = checkPinghuCondition(
            nShunzi: nShunzi, nKezi: nKezi, jantai: jantai,
            decomposition: merged, context: context
        )
        let danqi = checkDanqiCondition(decomposition: decomposition, winTile: context.winTile)

        let fu = computeFu(
            decomposition: merged,
            jantai: jantai, danqi: danqi, pinghu: pinghu,
            isAllAnkezi: context.menqian,
            context: context
        )

        return Hudi(
            fu: fu,
            menqian: context.menqian,
            zimo: context.zimo,
            shunzi: merged.shunzi,
            kezi: merged.kezi,
            toitsu: merged.toitsu,
            nShunzi: nShunzi,
            nKezi: nKezi,
            nAnkezi: nAnkezi,
            nGangzi: 0,      // TODO: 槓子は別途入力が必要
            nYaojiu: nYaojiu,
            nZipai: nZipai,
            danqi: danqi,
            pinghu: pinghu,
            zhuangfeng: context.zhuangfeng,
            menfeng: context.menfeng,
            jantai: jantai
        )
    }

    // MARK: - 状況役

    private static func checkTianhu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.tianhu else { return nil }
        return Yaku(name: "天和", fanshu: Yaku.yakuman)
    }

    private static func checkDihu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.dihu else { return nil }
        return Yaku(name: "地和", fanshu: Yaku.yakuman)
    }

    private static func checkMenqianqingzimo(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.zimo && ctx.menqian else { return nil }
        return Yaku(name: "門前清自摸和", fanshu: 1)
    }

    private static func checkLizhi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.lizhi && !ctx.daburi else { return nil }
        return Yaku(name: "立直", fanshu: 1)
    }

    private static func checkDaburizhi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // 門前のみ。立直とは複合しない（代わりにこちらが適用される）
        // TODO: daburi フラグを GameState 側でセットする
        guard ctx.daburi else { return nil }
        return Yaku(name: "ダブル立直", fanshu: 2)
    }

    private static func checkYifa(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.yifa else { return nil }
        return Yaku(name: "一発", fanshu: 1)
    }

    private static func checkQianggang(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.qianggang else { return nil }
        return Yaku(name: "槍槓", fanshu: 1)
    }

    private static func checkLingshang(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.lingshang else { return nil }
        return Yaku(name: "嶺上開花", fanshu: 1)
    }

    private static func checkHaidi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.haidi && ctx.zimo else { return nil }
        return Yaku(name: "海底摸月", fanshu: 1)
    }

    private static func checkHedi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.hedi && !ctx.zimo else { return nil }
        return Yaku(name: "河底撈魚", fanshu: 1)
    }

    // MARK: - 通常役

    private static func checkPinghu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.pinghu else { return nil }
        return Yaku(name: "平和", fanshu: 1)
    }

    private static func checkTanyao(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // 全面子が中張牌（么九牌・字牌を含まない）かつ雀頭も中張牌
        guard hudi.nYaojiu == 0 && !isYaojiu(hudi.jantai) else { return nil }
        return Yaku(name: "断么九", fanshu: 1)
    }

    private static func checkIipeiko(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.menqian else { return nil }
        let pairs = ["m", "p", "s"].reduce(0) { sum, suit in
            sum + (hudi.shunzi[suit]?.reduce(0) { $0 + $1 / 2 } ?? 0)
        }
        // pairs==1なら一盃口、2以上なら二盃口（こちらは対象外）
        guard pairs == 1 else { return nil }
        return Yaku(name: "一盃口", fanshu: 1)
    }

    private static func checkYakuhai(_ hudi: Hudi, _ ctx: HuleContext) -> [Yaku] {
        guard let zKezi = hudi.kezi["z"] else { return [] }
        var result: [Yaku] = []
        let zhuangIdx = hudi.zhuangfeng.rawValue - 1  // 東=0,南=1,西=2,北=3
        let menIdx    = hudi.menfeng.rawValue - 1
        // 場風・自風（連風牌は2翻）
        if zKezi[zhuangIdx] > 0 {
            if zhuangIdx == menIdx {
                result.append(Yaku(name: "連風牌（\(hudi.zhuangfeng.label)）", fanshu: 2))
            } else {
                result.append(Yaku(name: "場風（\(hudi.zhuangfeng.label)）", fanshu: 1))
            }
        }
        if menIdx != zhuangIdx && zKezi[menIdx] > 0 {
            result.append(Yaku(name: "自風（\(hudi.menfeng.label)）", fanshu: 1))
        }
        // 三元牌: 白=index4, 發=index5, 中=index6
        for (i, name) in [(4, "白"), (5, "發"), (6, "中")] {
            if i < zKezi.count && zKezi[i] > 0 {
                result.append(Yaku(name: name, fanshu: 1))
            }
        }
        return result
    }

    private static func checkSanshokuDoujun(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        let m = hudi.shunzi["m"] ?? []; let p = hudi.shunzi["p"] ?? []; let s = hudi.shunzi["s"] ?? []
        for i in 0..<min(m.count, min(p.count, s.count)) {
            if m[i] > 0 && p[i] > 0 && s[i] > 0 {
                return Yaku(name: "三色同順", fanshu: ctx.menqian ? 2 : 1)
            }
        }
        return nil
    }

    private static func checkSanshokuDoukou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        let m = hudi.kezi["m"] ?? []; let p = hudi.kezi["p"] ?? []; let s = hudi.kezi["s"] ?? []
        for i in 0..<min(m.count, min(p.count, s.count)) {
            if m[i] > 0 && p[i] > 0 && s[i] > 0 {
                return Yaku(name: "三色同刻", fanshu: 2)
            }
        }
        return nil
    }

    private static func checkIttsu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        for suit in ["m", "p", "s"] {
            guard let arr = hudi.shunzi[suit], arr.count >= 9 else { continue }
            if arr[0] > 0 && arr[3] > 0 && arr[6] > 0 {
                return Yaku(name: "一気通貫", fanshu: ctx.menqian ? 2 : 1)
            }
        }
        return nil
    }

    private static func checkChanta(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nYaojiu == 4 && isYaojiu(hudi.jantai) else { return nil }
        guard hudi.nShunzi >= 1 else { return nil }  // 混老頭と区別
        // 字牌が1つ以上ある（純全帯么九と区別）
        let hasZipai = hudi.nZipai >= 1 || hudi.jantai.hasPrefix("z")
        guard hasZipai else { return nil }
        return Yaku(name: "混全帯么九", fanshu: ctx.menqian ? 2 : 1)
    }

    private static func checkChiitoitsu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // nShunzi==0 && nKezi==0 は chiitoitsuDecomposition から来た七対子形
        guard ctx.menqian, hudi.nShunzi == 0, hudi.nKezi == 0 else { return nil }
        return Yaku(name: "七対子", fanshu: 2)
    }

    /// 七対子用の [BlockCounts] を生成（toitsu に7対子を格納）
    private static func chiitoitsuDecompositions(_ tileCounts: [String: Int]) -> [BlockCounts] {
        var bc = BlockCounts()
        for (tile, _) in tileCounts {
            guard tile.count == 2,
                  let suitChar = tile.first,
                  let num = Int(String(tile.last!)) else { continue }
            let suit = String(suitChar)
            bc.toitsu[suit]?[num - 1] += 1
        }
        return [bc]
    }

    private static func checkToitoi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nShunzi == 0 && hudi.nKezi == 4 else { return nil }
        return Yaku(name: "対対和", fanshu: 2)
    }

    private static func checkSanankou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nAnkezi >= 3 else { return nil }
        return Yaku(name: "三暗刻", fanshu: 2)
    }

    private static func checkSankantsu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nGangzi >= 3 else { return nil }
        return Yaku(name: "三槓子", fanshu: 2)
    }

    private static func checkShousangen(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard let zKezi = hudi.kezi["z"] else { return nil }
        let dragonKezi = [4, 5, 6].filter { $0 < zKezi.count && zKezi[$0] > 0 }.count
        let dragonJantai = ["z5", "z6", "z7"].contains(hudi.jantai)
        guard dragonKezi == 2 && dragonJantai else { return nil }
        return Yaku(name: "小三元", fanshu: 2)
    }

    private static func checkHonroutou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nYaojiu == 4 && isYaojiu(hudi.jantai) else { return nil }
        guard hudi.nShunzi == 0 else { return nil }  // 順子があると混老頭にならない
        return Yaku(name: "混老頭", fanshu: 2)
    }

    private static func checkRyanpeiko(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard ctx.menqian else { return nil }
        let pairs = ["m", "p", "s"].reduce(0) { sum, suit in
            sum + (hudi.shunzi[suit]?.reduce(0) { $0 + $1 / 2 } ?? 0)
        }
        guard pairs >= 2 else { return nil }
        return Yaku(name: "二盃口", fanshu: 3)
    }

    private static func checkHonitsu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        let usedSuits = ["m", "p", "s"].filter { suit in
            (hudi.shunzi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (hudi.kezi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (hudi.toitsu[suit]?.reduce(0, +) ?? 0) > 0 ||
            hudi.jantai.hasPrefix(suit)
        }
        let hasZipai = (hudi.kezi["z"]?.reduce(0, +) ?? 0) > 0 ||
                       (hudi.toitsu["z"]?.reduce(0, +) ?? 0) > 0 ||
                       hudi.jantai.hasPrefix("z")
        guard usedSuits.count == 1 && hasZipai else { return nil }
        return Yaku(name: "混一色", fanshu: ctx.menqian ? 3 : 2)
    }

    private static func checkJunchan(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nYaojiu == 4 && isYaojiu(hudi.jantai) else { return nil }
        guard hudi.nShunzi >= 1 else { return nil }  // 混老頭と区別
        guard hudi.nZipai == 0 && !hudi.jantai.hasPrefix("z") else { return nil }  // 字牌なし
        return Yaku(name: "純全帯么九", fanshu: ctx.menqian ? 3 : 2)
    }

    private static func checkChinitsu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        let usedSuits = ["m", "p", "s"].filter { suit in
            (hudi.shunzi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (hudi.kezi[suit]?.reduce(0, +) ?? 0) > 0 ||
            (hudi.toitsu[suit]?.reduce(0, +) ?? 0) > 0 ||
            hudi.jantai.hasPrefix(suit)
        }
        let hasZipai = (hudi.kezi["z"]?.reduce(0, +) ?? 0) > 0 ||
                       (hudi.toitsu["z"]?.reduce(0, +) ?? 0) > 0 ||
                       hudi.jantai.hasPrefix("z")
        guard usedSuits.count == 1 && !hasZipai else { return nil }
        return Yaku(name: "清一色", fanshu: ctx.menqian ? 6 : 5)
    }

    // MARK: - 役満

    private static func checkKokushi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // 国士無双は winningDecompositions() の外で判定が必要（専用の面子形）
        // TODO: tiles から么九牌13種 + 対子1枚 の形か確認
        return nil
    }

    private static func checkSuuankou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nAnkezi == 4 else { return nil }
        // 単騎待ちでのアガリはダブル役満
        let fanshu = hudi.danqi ? Yaku.doubleYakuman : Yaku.yakuman
        return Yaku(name: "四暗刻", fanshu: fanshu)
    }

    private static func checkDaisangen(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // TODO: z5(白)/z6(發)/z7(中) がすべて刻子
        return nil
    }

    private static func checkShousuushi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // TODO: z1(東)/z2(南)/z3(西)/z4(北) のうち3種が刻子 + 1種が雀頭
        return nil
    }

    private static func checkDaisuushi(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // ダブル役満
        // TODO: z1(東)/z2(南)/z3(西)/z4(北) がすべて刻子
        return nil
    }

    private static func checkTsuuiisou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // TODO: 全面子・雀頭が字牌（数牌が0枚）
        return nil
    }

    private static func checkRyuuiisou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // TODO: 全牌が緑牌（s2,s3,s4,s6,s8,z6）のみで構成
        return nil
    }

    private static func checkChinroutou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // TODO: 全面子・雀頭が数牌の么九牌（m1,m9,p1,p9,s1,s9）のみ
        return nil
    }

    private static func checkChuurenpoutou(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        // TODO: 1種の数牌で 1112345678999 + 同スートの1牌
        return nil
    }

    private static func checkSuukantsu(_ hudi: Hudi, _ ctx: HuleContext) -> Yaku? {
        guard hudi.nGangzi == 4 else { return nil }
        return Yaku(name: "四槓子", fanshu: Yaku.yakuman)
    }

    // MARK: - buildHudi ヘルパー

    // 雀頭（対子）の牌ラベルを返す
    private static func findJantai(decomposition: BlockCounts) -> String {
        for suit in ["m", "p", "s", "z"] {
            guard let arr = decomposition.toitsu[suit] else { continue }
            for (i, cnt) in arr.enumerated() where cnt > 0 {
                return "\(suit)\(i + 1)"
            }
        }
        return ""
    }

    // 么九牌(1,9)または字牌を含む面子（順子・刻子）の総数
    private static func countYaojiuMentsu(decomposition: BlockCounts) -> Int {
        var count = 0
        for suit in ["m", "p", "s"] {
            if let arr = decomposition.shunzi[suit] {
                count += arr[0]  // 1-2-3（1を含む）
                count += arr[6]  // 7-8-9（9を含む）
            }
            if let arr = decomposition.kezi[suit] {
                count += arr[0]  // 1刻子
                count += arr[8]  // 9刻子
            }
        }
        // 字牌刻子はすべて么九牌扱い
        if let arr = decomposition.kezi["z"] {
            count += arr.reduce(0, +)
        }
        return count
    }

    // 字牌を含む面子（刻子のみ）の総数
    private static func countZipaiMentsu(decomposition: BlockCounts) -> Int {
        return decomposition.kezi["z"]?.reduce(0, +) ?? 0
    }

    // 平和条件: 全4面子が順子 + 役牌でない雀頭 + リャンメン待ち
    private static func checkPinghuCondition(
        nShunzi: Int, nKezi: Int, jantai: String,
        decomposition: BlockCounts, context: HuleContext
    ) -> Bool {
        guard nShunzi == 4 && nKezi == 0 else { return false }
        guard !isYakuhai(jantai, zhuangfeng: context.zhuangfeng, menfeng: context.menfeng) else { return false }
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
        lizhibang: Int
    ) -> DefenResult {
        guard !yaku.isEmpty else {
            return DefenResult(defen: 0, fenpei: Array(repeating: 0, count: 4))
        }

        let isDealer = (winnerIdx == dealerIdx)
        let totalFan = yaku.reduce(0) { $0 + $1.fanshu }
        let table    = paymentTable(fu: fu, fan: totalFan)

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

        return DefenResult(defen: defen, fenpei: fenpei)
    }

    private static func ceil100(_ value: Int) -> Int {
        return ((value + 99) / 100) * 100
    }
    
    // [子ロン, 子ツモ親払い, 子ツモ子払い, 親ロン, 親ツモ子払い]
      static func paymentTable(fu: Int, fan: Int) -> [Int] {
          let fixedBase: Int? = {
              switch fan {
              case 5:         return 8000
              case 6, 7:      return 12000
              case 8, 9, 10:  return 16000
              case 11, 12:    return 24000
              default:        return fan >= 13 ? 32000 : nil
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
        jantai: String, danqi: Bool, pinghu: Bool,
        isAllAnkezi: Bool,
        context: HuleContext
    ) -> Int {
        var fu = 20

        // 雀頭符・単騎符
        fu += jantaiFu(jantai: jantai, danqi: danqi,
                       zhuangfeng: context.zhuangfeng, menfeng: context.menfeng)

        // 刻子符
        fu += keziTotalFu(decomposition: decomposition, isAllAnkezi: isAllAnkezi)

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

    // 雀頭符: 役牌対子 +2、連風対子 +4、単騎 +2
    private static func jantaiFu(jantai: String, danqi: Bool,
                                  zhuangfeng: Feng, menfeng: Feng) -> Int {
        var fu = danqi ? 2 : 0
        guard jantai.count == 2, jantai.first == "z",
              let n = Int(String(jantai.last!)) else { return fu }
        if n == zhuangfeng.rawValue { fu += 2 }
        if n == menfeng.rawValue    { fu += 2 }
        if n >= 5                   { fu += 2 }  // 三元牌 (白z5/發z6/中z7)
        return fu
    }

    // 刻子符: 明刻中張=2, 明刻么九=4, 暗刻中張=4, 暗刻么九=8
    // （槓子は nGangzi 未実装のため現状スキップ）
    private static func keziTotalFu(decomposition: BlockCounts, isAllAnkezi: Bool) -> Int {
        var fu = 0
        for suit in ["m", "p", "s", "z"] {
            guard let arr = decomposition.kezi[suit] else { continue }
            for (i, cnt) in arr.enumerated() where cnt > 0 {
                let isYaojiu = (suit == "z") || (i == 0) || (i == 8)
                var kfu = 2
                if isYaojiu    { kfu *= 2 }
                if isAllAnkezi { kfu *= 2 }
                fu += kfu * cnt
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

//
//  YakuReferenceData.swift
//  MbMajiang
//
//  手役一覧パネル用の静的な役早見表データ（役名・翻数・成立条件・例となる14枚の手牌）。
//

import Foundation

struct YakuReferenceEntry {
    let name: String
    let fanshu: String
    let condition: String
    let tiles: [String]
    /// カン（槓子）の組。副露と同様に表示する牌のグループ（明槓・暗槓）
    var melds: [[Pai]] = []

    /// `fanshu`から導出する、手役一覧パネルの開閉セクションの区分
    var category: YakuCategory {
        if fanshu == "役満" { return .yakuman }
        if fanshu == "ダブル役満" { return .doubleYakuman }
        if fanshu.hasPrefix("6翻") { return .six }
        if fanshu.hasPrefix("3翻") { return .three }
        if fanshu.hasPrefix("2翻") { return .two }
        return .one
    }
}

/// 手役一覧パネルの開閉セクションの区分。`label`はセクション見出しに使う
enum YakuCategory: String, CaseIterable {
    case one, two, three, six, yakuman, doubleYakuman

    var label: String {
        switch self {
        case .one: return "1翻"
        case .two: return "2翻"
        case .three: return "3翻"
        case .six: return "6翻"
        case .yakuman: return "役満"
        case .doubleYakuman: return "ダブル役満"
        }
    }
}

enum YakuReferenceData {
    /// 明槓（ミンカン）の表示用グループ。呼んだ1枚を横向きにする
    private static func minkan(_ code: String) -> [Pai] {
        var called = Pai(code)
        called.rotated = true
        return [called, Pai(code), Pai(code), Pai(code)]
    }

    /// 暗槓（アンカン）の表示用グループ。両端2枚を裏向きにする
    private static func ankan(_ code: String) -> [Pai] {
        var left = Pai(code)
        left.revealed = false
        var right = Pai(code)
        right.revealed = false
        return [left, Pai(code), Pai(code), right]
    }

    static let entries: [YakuReferenceEntry] = [
        // MARK: - 1翻
        YakuReferenceEntry(name: "門前清自摸和（メンゼンツモ）", fanshu: "1翻",
            condition: "門前（メンゼン）でツモあがりする",
            tiles: ["m2","m3","m4","p5","p6","p7","s3","s4","s5","s7","s8","s9","m9","m9"]),
        YakuReferenceEntry(name: "立直（リーチ）", fanshu: "1翻",
            condition: "門前（メンゼン）かつテンパイした状態で1000点棒を供託してリーチ宣言してあがる",
            tiles: ["m1","m2","m3","p2","p3","p4","s5","s6","s7","z5","z5","z5","m8","m8"]),
        YakuReferenceEntry(name: "一発（イッパツ）", fanshu: "1翻",
            condition: "リーチ宣言後の１巡以内にあがる。他家（ターチャ）が鳴くと不成立になる。",
            tiles: ["p1","p2","p3","p7","p8","p9","s2","s3","s4","m5","m6","m7","s9","s9"]),
        YakuReferenceEntry(name: "平和（ピンフ）", fanshu: "1翻",
            condition: "手牌の面子（メンツ）が全て順子（シュンツ）かつ雀頭（ジャントウ）が役牌以外かつ両面待ちの形でテンパイしてあがる。門前（メンゼン）のみ成立。",
            tiles: ["m2","m3","m4","p5","p6","p7","s1","s2","s3","s6","s7","s8","m9","m9"]),
        YakuReferenceEntry(name: "断么九（タンヤオ）", fanshu: "1翻",
            condition: "手牌が2〜8の数牌（スーパイ）のみであがる。1・9・字牌（ジハイ）を含まれていると不成立。正式名称はタンヤオチュー。",
            tiles: ["m2","m3","m4","p3","p4","p5","s5","s6","s7","m6","m7","m8","p2","p2"]),
        YakuReferenceEntry(name: "一盃口（イーペーコー）", fanshu: "1翻",
            condition: "同じ順子（シュンツ）を2組揃えてあがる。門前（メンゼン）のみ成立。",
            tiles: ["m2","m3","m4","m2","m3","m4","p5","p6","p7","s1","s2","s3","z5","z5"]),
        YakuReferenceEntry(name: "役牌：自風牌（ヤクハイ：ジカゼハイ）", fanshu: "1翻",
            condition: "自風の風牌（フォンパイ：東南西北の牌）で刻子（コーツ）を作ってあがる。親の自風牌は必ず東になり、親から見て下家（シモチャ：右のプレイヤー）は南、対面（トイメン：正面のプレイヤー）は西、上家（カミチャ：左のプレイヤー）は北が自風牌となる。",
            tiles: ["z2","z2","z2","m3","m4","m5","p6","p7","p8","s1","s2","s3","m9","m9"]),
        YakuReferenceEntry(name: "役牌：場風牌（ヤクハイ：バカゼハイ）", fanshu: "1翻",
            condition: "場風の風牌（フォンパイ：東南西北の牌）で刻子（コーツ）を作ってあがる。東場の局であれば東、南場であれば南が場風牌となる。",
            tiles: ["z1","z1","z1","m5","m6","m7","p2","p3","p4","s6","s7","s8","p9","p9"]),
        YakuReferenceEntry(name: "役牌：白・發・中（ヤクハイ：ハク・ハツ・チュン）", fanshu: "1翻",
            condition: "白・發・中いずれかの牌で刻子（コーツ）を1組作ってあがる。白・發・中は三元牌と呼ばれる。",
            tiles: ["z7","z7","z7","m1","m2","m3","p4","p5","p6","s2","s3","s4","m8","m8"]),
        YakuReferenceEntry(name: "槍槓（チャンカン）", fanshu: "1翻",
            condition: "他家（ターチャ）が加槓（カカン）した牌でロンあがりする",
            tiles: ["m4","m5","m6","p1","p2","p3","s6","s7","s8","z1","z1","z1","p9","p9"]),
        YakuReferenceEntry(name: "嶺上開花（リンシャンカイホウ）", fanshu: "1翻",
            condition: "カンの後に引いた嶺上牌（リンシャンパイ）でツモあがる",
            tiles: ["m1","m1","m1","p4","p5","p6","s2","s3","s4","s7","s8","s9","m6","m6"]),
        YakuReferenceEntry(name: "海底摸月（ハイテイ）", fanshu: "1翻",
            condition: "最後1枚の牌山を引いてツモあがりする。正式名称はハイテイモーユエ。",
            tiles: ["p2","p3","p4","p5","p6","p7","m1","m2","m3","s4","s5","s6","z6","z6"]),
        YakuReferenceEntry(name: "河底撈魚（ホウテイ）", fanshu: "1翻",
            condition: "牌山が0枚の状態で他家（ターチャ）が捨てた牌でロンあがりする。正式名称はホウテイラオユイ。",
            tiles: ["s1","s2","s3","s4","s5","s6","m3","m4","m5","p7","p8","p9","m9","m9"]),


        // MARK: - 2翻
        YakuReferenceEntry(name: "ダブル立直（ダブリー）", fanshu: "2翻",
            condition: "１巡目でリーチ宣言してあがる。正式名称はダブルリーチ。",
            tiles: ["p1","p2","p3","p4","p5","p6","m7","m8","m9","s3","s4","s5","z6","z6"]),
        YakuReferenceEntry(name: "三色同順（サンショク）", fanshu: "2翻（鳴き1翻）",
            condition: "同じ数字の順子（シュンツ）を萬子（マンズ）・筒子（ピンズ）・索子（ソーズ）で1組ずつ揃えてあがる。正式名称はサンショクドウジュン。",
            tiles: ["m4","m5","m6","p4","p5","p6","s4","s5","s6","m1","m2","m3","p8","p8"]),
        YakuReferenceEntry(name: "一気通貫（イッツー）", fanshu: "2翻（鳴き1翻）",
            condition: "同じ種類の数牌（スーパイ）で123・456・789の順子（シュンツ）を揃えてあがる。正式名称はイッキツウカン。",
            tiles: ["m1","m2","m3","m4","m5","m6","m7","m8","m9","p2","p3","p4","s5","s5"]),
        YakuReferenceEntry(name: "混全帯么九（チャンタ）", fanshu: "2翻（鳴き1翻）",
            condition: "手牌全ての面子（メンツ）と雀頭（ジャントウ）に1・9・字牌（ジハイ）のいずれかを含めてあがる。正式名称はホンチャンタイヤオチュー。",
            tiles: ["m1","m2","m3","p7","p8","p9","s1","s2","s3","z1","z1","z1","m9","m9"]),
        YakuReferenceEntry(name: "七対子（チートイツ）", fanshu: "2翻",
            condition: "異なる7組の対子（トイツ）を揃えてあがる。4面子1雀頭でない特殊なあがりの形。門前（メンゼン）のみ成立。",
            tiles: ["m1","m1","m5","m5","p3","p3","p8","p8","s2","s2","s7","s7","z5","z5"]),
        YakuReferenceEntry(name: "対々和（トイトイ）", fanshu: "2翻",
            condition: "4組すべてを刻子（コーツ）で揃えてあがる。正式名称はトイトイホー。",
            tiles: ["m3","m3","m3","p6","p6","p6","s2","s2","s2","z4","z4","z4","m8","m8"]),
        YakuReferenceEntry(name: "三暗刻（サンアンコー）", fanshu: "2翻",
            condition: "暗刻（アンコ：手牌で同じ牌3枚の組み合わせ）を3組作ってあがる。",
            tiles: ["m2","m2","m2","p5","p5","p5","s7","s7","s7","m4","m5","m6","p9","p9"]),
        YakuReferenceEntry(name: "三槓子（サンカンツ）", fanshu: "2翻",
            condition: "カンを3回行ってあがる。",
            tiles: ["m5","m6","m7","z6","z6"],
            melds: [ankan("m1"), minkan("p4"), ankan("s8")]),
        YakuReferenceEntry(name: "小三元（ショウサンゲン）", fanshu: "2翻",
            condition: "白・發・中で刻子（コーツ）２組と雀頭（ジャントウ）を作ってあがる。",
            tiles: ["z5","z5","z5","z6","z6","z6","z7","z7","m2","m3","m4","p6","p7","p8"]),
        YakuReferenceEntry(name: "混老頭（ホンロウトウ）", fanshu: "2翻",
            condition: "1・9・字牌（ジハイ）のみで構成してあがる。対々和か七対子と必ず複合する。",
            tiles: ["m1","m1","m1","p9","p9","p9","z1","z1","z1","z5","z5","z5","s9","s9"]),
        YakuReferenceEntry(name: "三色同刻（サンショクドウコウ）", fanshu: "2翻",
            condition: "同じ数字の刻子（コーツ）を萬子（マンズ）・筒子（ピンズ）・索子（ソーズ）それぞれで1組ずつ揃えてあがる。",
            tiles: ["m5","m5","m5","p5","p5","p5","s5","s5","s5","m1","m2","m3","p8","p8"]),

        // MARK: - 3翻
        YakuReferenceEntry(name: "混一色（ホンイツ）", fanshu: "3翻（鳴き2翻）",
            condition: "1種類の数牌（スーパイ）＋字牌（ジハイ）のみで構成してあがる。正式名称はホンイーソー。",
            tiles: ["m1","m2","m3","m4","m5","m6","m7","m8","m9","z1","z1","z1","z5","z5"]),
        YakuReferenceEntry(name: "純全帯么九（ジュンチャン）", fanshu: "3翻（鳴き2翻）",
            condition: "全ての面子（メンツ）・雀頭（ジャントウ）に1・9のいずれかを含めてあがる。字牌（ジハイ）は使わない。正式名称はジュンチャンタイヤオチュー。",
            tiles: ["m1","m2","m3","p7","p8","p9","s1","s2","s3","m7","m8","m9","p1","p1"]),
        YakuReferenceEntry(name: "二盃口（リャンペーコー）", fanshu: "3翻",
            condition: "同じ順子（シュンツ）を2組ずつ、2種類揃える。門前（メンゼン）のみ成立。",
            tiles: ["m2","m3","m4","m2","m3","m4","p5","p6","p7","p5","p6","p7","s8","s8"]),

        // MARK: - 5〜6翻
        YakuReferenceEntry(name: "清一色（チンイツ）", fanshu: "6翻（鳴き5翻）",
            condition: "1種類の数牌（スーパイ）のみで構成してあがる。字牌（ジハイ）は使わない。正式名称はチンイーソー。",
            tiles: ["m1","m2","m3","m4","m5","m6","m7","m8","m9","m2","m3","m4","m9","m9"]),

        // MARK: - 役満
        YakuReferenceEntry(name: "国士無双（コクシムソウ）", fanshu: "役満",
            condition: "1・9・字牌（ジハイ）の計13種類を1枚ずつ＋1枚で構成してあがる。4面子1雀頭でない特殊なあがりの形。",
            tiles: ["m1","m9","p1","p9","s1","s9","z1","z1","z2","z3","z4","z5","z6","z7"]),
        YakuReferenceEntry(name: "国士無双十三面待ち（コクシムソウジュウサンメンマチ）", fanshu: "ダブル役満",
            condition: "国士無双のうち、1・9・字牌（ジハイ）の計13種類を1枚ずつ揃えてテンパイしてあがる。",
            tiles: ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z5","z6","z7"]),
        YakuReferenceEntry(name: "四暗刻（スーアンコー）", fanshu: "役満",
            condition: "暗刻（アンコ：手牌で同じ牌3枚の組み合わせ）を4組作ってあがる。",
            tiles: ["m2","m2","m2","p5","p5","p5","s7","s7","s7","z3","z3","z3","m9","m9"]),
        YakuReferenceEntry(name: "四暗刻単騎待ち（スーアンコータンキマチ）", fanshu: "ダブル役満",
            condition: "四暗刻のうち、暗刻（アンコ）4組を作り、雀頭単騎待ちの形でテンパイしてあがる。",
            tiles: ["m3","m3","m3","p6","p6","p6","s8","s8","s8","z6","z6","z6","p1","p1"]),
        YakuReferenceEntry(name: "大三元（ダイサンゲン）", fanshu: "役満",
            condition: "白・發・中の刻子（コーツ）を3組すべて揃えてあがる。",
            tiles: ["z5","z5","z5","z6","z6","z6","z7","z7","z7","m2","m3","m4","p7","p7"]),
        YakuReferenceEntry(name: "小四喜（ショウスーシー）", fanshu: "役満",
            condition: "東南西北で刻子（コーツ）3組と雀頭（ジャントウ）を作ってあがる。",
            tiles: ["z1","z1","z1","z2","z2","z2","z3","z3","z3","z4","z4","m5","m6","m7"]),
        YakuReferenceEntry(name: "大四喜（ダイスーシー）", fanshu: "ダブル役満",
            condition: "東南西北の刻子（コーツ）を4組すべて揃えてあがる。",
            tiles: ["z1","z1","z1","z2","z2","z2","z3","z3","z3","z4","z4","z4","m5","m5"]),
        YakuReferenceEntry(name: "字一色（ツーイーソー）", fanshu: "役満",
            condition: "字牌（ジハイ）のみで構成してあがる。",
            tiles: ["z1","z1","z1","z2","z2","z2","z5","z5","z5","z7","z7","z7","z6","z6"]),
        YakuReferenceEntry(name: "緑一色（リューイーソー）", fanshu: "役満",
            condition: "索子（ソーズ）の2・3・4・6・8と發のみで構成してあがる。",
            tiles: ["s2","s3","s4","s2","s3","s4","s6","s6","s6","s8","s8","s8","z6","z6"]),
        YakuReferenceEntry(name: "清老頭（チンロウトウ）", fanshu: "役満",
            condition: "1・9の数牌（スーパイ）のみで構成してあがる。",
            tiles: ["m1","m1","m1","m9","m9","m9","p1","p1","p1","p9","p9","p9","s9","s9"]),
        YakuReferenceEntry(name: "九蓮宝燈（チューレンポウトウ）", fanshu: "役満",
            condition: "1種の数牌（スーパイ）で1112345678999＋1枚を作ってあがる。面前のみ成立。",
            tiles: ["m1","m1","m1","m2","m3","m4","m5","m5","m6","m7","m8","m9","m9","m9"]),
        YakuReferenceEntry(name: "純正九蓮宝燈（ジュンセイチューレンポウトウ）", fanshu: "ダブル役満",
            condition: "九蓮宝燈のうち、1112345678999の形でテンパイしてあがる。",
            tiles: ["m1","m1","m1","m2","m3","m4","m5","m5","m6","m7","m8","m9","m9","m9"]),
        YakuReferenceEntry(name: "四槓子（スーカンツ）", fanshu: "役満",
            condition: "カンを4回行ってあがる。",
            tiles: ["m8","m8"],
            melds: [ankan("m1"), minkan("p4"), ankan("s7"), minkan("z2")]),
        YakuReferenceEntry(name: "天和（テンホー）", fanshu: "役満",
            condition: "親の1巡目のツモあがる。",
            tiles: ["m1","m2","m3","p4","p5","p6","s2","s3","s4","z1","z1","z1","m9","m9"]),
        YakuReferenceEntry(name: "地和（チーホー）", fanshu: "役満",
            condition: "子の1巡目のツモあがる。他家（ターチャ）の鳴きが入ると不成立。",
            tiles: ["p1","p2","p3","m4","m5","m6","s7","s8","s9","z6","z6","z6","p9","p9"]),
    ]

    /// 手役一覧パネル用に、区分（1役〜ダブル役満）ごとにまとめたエントリー一覧
    static let groupedEntries: [(category: YakuCategory, entries: [YakuReferenceEntry])] =
        YakuCategory.allCases.map { category in
            (category, entries.filter { $0.category == category })
        }
}

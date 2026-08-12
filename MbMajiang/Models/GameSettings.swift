import Foundation
import Observation
import SwiftUI
import UIKit
import PencilKit

@Observable
final class GameSettings {

    // MARK: - CPU
    // 下家・対面・上家の順（インデックス0=下家, 1=対面, 2=上家）
    var cpuStyles: [CpuStyle] = [.damaDefense, .damaDefense, .damaDefense]

    // MARK: - 点数
    var haikyuGenten: Int = 25000
    var junikitenRanks: [Int] = [10, -10, -30]  // 2着, 3着, 4着 (1着は自動計算)
    var junkitenRounding: Bool = false
    var renpuFu: RenpuFu = .two

    // MARK: - 牌
    var akadoraMan: Int = 1
    var akadoraPin: Int = 1
    var akadoraSou: Int = 1
    var kuitanAri: Bool = true
    var kuichikaeLevel: KuichikaeLevel = .none

    // MARK: - 進行
    var kyokuCount: KyokuCount = .tonpuSen
    var tochukuryokuAri: Bool = true
    var nagashiManganAri: Bool = false
    var notenSengenAri: Bool = true
    var notenBatsuAri: Bool = true
    var dojiHuleMax: DojiHuleMax = .atamahane
    var renzhuFang: RenzhuFang = .tenpai
    var tobiEndAri: Bool = false
    var orasudomeAri: Bool = false
    var enchossenFang: EnchossenFang = .suddenDeath

    // MARK: - 立直・ドラ
    var ippatsuAri: Bool = true
    var uradoraAri: Bool = true
    var kandoraAri: Bool = true
    var kandoraNochigakeAri: Bool = false
    var kanUraAri: Bool = true
    var noTsumoBanRiichiAri: Bool = false
    var riichiAnkanLevel: RiichiAnkanLevel = .noChangeWaiting

    // MARK: - 表示
    var showHandDisplayOption: Bool = false
    var showTeyakuList: Bool = true
    var showHowToPlayAssist: Bool = true
    var agariHaiDisplay: Bool = true
    var dapaiAssist: Bool = true
    var fulouAssist: Bool = true
    var thinkingTimeMode: ThinkingTimeMode = .unlimited

    // 一打あたりの制限時間（秒）。0 = 無制限。持ち時間がある間はこの猶予を使い切ってから持ち時間を消費する
    var turnTimeLimit: Int {
        switch thinkingTimeMode {
        case .unlimited: return 0
        case .perMove10: return 10
        case .bank300:   return 0
        }
    }
    // 一局あたりの持ち時間（秒）。0 = 無制限（持ち時間なし）
    var totalTimeBank: Int {
        switch thinkingTimeMode {
        case .bank300: return 300
        default:       return 0
        }
    }
    // 持ち時間を使い切った後の一打あたりの制限時間（秒）
    var postBankTimeLimit: Int {
        switch thinkingTimeMode {
        case .bank300: return 5
        default:       return 0
        }
    }

    // MARK: - テーマ
    var tileTheme: TileTheme = .original
    /// 「汎用」テーマの設定方法。.simpleなら配色プリセットから選択、.detailedならスロットごとにRGBで自由に選択
    var genericTileColorMode: TileBackColorMode = .simple
    /// 簡易設定で選ぶ配色プリセット（全スロットをまとめて切り替える）
    var genericColorScheme: GenericColorScheme = .original
    /// 詳細設定（RGB自由選択）で使うカスタムカラー
    var genericManzuDigitColorRed: Double = 0
    var genericManzuDigitColorGreen: Double = 0
    var genericManzuDigitColorBlue: Double = 0
    var genericManzuWanColorRed: Double = 153/255
    var genericManzuWanColorGreen: Double = 0
    var genericManzuWanColorBlue: Double = 0
    var genericPinzuRedColorRed: Double = 153/255
    var genericPinzuRedColorGreen: Double = 0
    var genericPinzuRedColorBlue: Double = 0
    var genericPinzuGreenColorRed: Double = 4/255
    var genericPinzuGreenColorGreen: Double = 60/255
    var genericPinzuGreenColorBlue: Double = 40/255
    var genericSouzuRedColorRed: Double = 153/255
    var genericSouzuRedColorGreen: Double = 0
    var genericSouzuRedColorBlue: Double = 0
    var genericSouzuGreenColorRed: Double = 4/255
    var genericSouzuGreenColorGreen: Double = 60/255
    var genericSouzuGreenColorBlue: Double = 40/255
    var genericHonorWindColorRed: Double = 0
    var genericHonorWindColorGreen: Double = 0
    var genericHonorWindColorBlue: Double = 0
    var genericHonorHatsuColorRed: Double = 4/255
    var genericHonorHatsuColorGreen: Double = 60/255
    var genericHonorHatsuColorBlue: Double = 40/255
    var genericHonorChunColorRed: Double = 153/255
    var genericHonorChunColorGreen: Double = 0
    var genericHonorChunColorBlue: Double = 0
    var genericAkaDoraColorRed: Double = 153/255
    var genericAkaDoraColorGreen: Double = 0
    var genericAkaDoraColorBlue: Double = 0
    /// 一索（鳥の絵柄）専用の差し色
    var genericSouzuBirdAccentColorRed: Double = 153/255
    var genericSouzuBirdAccentColorGreen: Double = 0
    var genericSouzuBirdAccentColorBlue: Double = 0
    var boardTheme: BoardTheme = .original
    /// 「アニマル」テーマで選択中の動物
    var animalBoardBackground: AnimalBoardBackground = .lesserPanda
    /// 「オリジナル」テーマ（単色背景）の設定方法。.simpleならプリセットから選択、.detailedならRGBで自由に選択
    var boardBackgroundColorMode: TileBackColorMode = .simple
    var boardBackgroundColorPreset: BoardBackgroundColor = .green
    /// 詳細設定（RGB自由選択）で使うカスタムカラー
    var boardBackgroundColorRed: Double = 55/255
    var boardBackgroundColorGreen: Double = 125/255
    var boardBackgroundColorBlue: Double = 45/255
    /// 「キャンバス」テーマで選択中のキャンバス枠（キャンバス1〜5を切り替えて複数保存できる）
    var selectedCanvasSlot: CanvasSlot = .slot1
    /// キャンバス枠ごとの名前。未設定（空文字）の場合は「キャンバス1」のような既定名を表示する
    var canvasSlotNames: [String] = Array(repeating: "", count: CanvasSlot.allCases.count)
    /// 「キャンバス」テーマの背景色（自由選択、キャンバス枠ごと）
    var boardCanvasBackgroundColorsRed: [Double] = Array(repeating: 1, count: CanvasSlot.allCases.count)
    var boardCanvasBackgroundColorsGreen: [Double] = Array(repeating: 1, count: CanvasSlot.allCases.count)
    var boardCanvasBackgroundColorsBlue: [Double] = Array(repeating: 1, count: CanvasSlot.allCases.count)
    /// 「キャンバス」テーマの手書き内容。編集画面への再読込用（PKDrawingの生データ、キャンバス枠ごと）
    var boardCanvasDrawingDatas: [Data?] = Array(repeating: nil, count: CanvasSlot.allCases.count)
    /// 「キャンバス」テーマの手書き内容を描画に使うために書き出した画像（透過PNG、キャンバス枠ごと）
    var boardCanvasImageDatas: [Data?] = Array(repeating: nil, count: CanvasSlot.allCases.count)
    var soundTheme: SoundTheme = .original
    /// 簡易設定で選ぶ牌デザイン（裏）のテーマ。テーマによっては色を持たないものも将来追加され得る
    var tileBackDesignTheme: TileBackDesignTheme = .original
    var tileBackColor: TileBackColor = .gold
    /// 牌デザイン（裏）の設定方法。.simpleならプリセットから選択、.detailedならRGBで自由に選択
    var tileBackColorMode: TileBackColorMode = .simple
    /// 詳細設定（RGB自由選択）で使うカスタムカラーの構成要素
    var tileBackColorCustomRed: Double = 229/255
    var tileBackColorCustomGreen: Double = 179/255
    var tileBackColorCustomBlue: Double = 67/255
    /// 「ボーダー」テーマの帯の本数（2〜5）
    var tileBackBorderCount: Int = 2
    /// 簡易設定で選ぶボーダーの配色プリセット（本数・2色をまとめて切り替える）
    var tileBackColorScheme: TileBackColorScheme = .original
    /// 詳細設定（RGB自由選択）で使うボーダーのカスタムカラー
    var tileBackBorderColor1CustomRed: Double = 190/255
    var tileBackBorderColor1CustomGreen: Double = 60/255
    var tileBackBorderColor1CustomBlue: Double = 60/255
    var tileBackBorderColor2CustomRed: Double = 229/255
    var tileBackBorderColor2CustomGreen: Double = 179/255
    var tileBackBorderColor2CustomBlue: Double = 67/255
    /// BGMの設定方法。.bulkなら対局中ずっと1曲、.perRoundなら局ごとに個別の曲を再生する
    var bgmMode: BGMMode = .bulk
    /// 一括設定モードで使う固定の1曲
    var bgmBulkTrack: BGMTrack = .jadeTiles
    /// 局ごとに設定モードで使う、東一局〜南四局それぞれに割り当てるBGM（インデックス0=東一局...7=南四局）
    var bgmByRound: [BGMTrack] = [.jadeTiles, .oikaze, .shippu, .attakaOnsen, .senkoHanabi, .uchiageHanabi, .yunagi, .kaminokoe]

    // MARK: - 役満
    var yakumanFukugouAri: Bool = true
    var doubleYakumanAri: Bool = false
    var kazoeYakumanAri: Bool = false
    var yakumanPaoAri: Bool = true
    var kiriageMangan: Bool = true

    // MARK: - Computed
    var junkiten1: Int { -(junikitenRanks.reduce(0, +)) }

    // MARK: - Theme Enums

    enum TileTheme: String, CaseIterable, Hashable {
        case original = "オリジナル"

        func imageName(for label: String) -> String {
            switch self {
            case .original: return "original/\(GameSettings.genericBaseName(for: label))_fixed"
            }
        }
    }

    /// 「汎用」テーマの色スロットの値をまとめたもの。環境値として画面に渡す
    struct GenericTileColors: Hashable {
        var manzuDigit: Color
        var manzuWan: Color
        var pinzuRed: Color
        var pinzuGreen: Color
        var souzuRed: Color
        var souzuGreen: Color
        var honorWind: Color
        var honorHatsu: Color
        var honorChun: Color
        var akaDora: Color
        /// 一索（鳥の絵柄）専用の差し色。索子の他牌の差し色（souzuRed）とは独立
        var souzuBirdAccent: Color
    }

    /// 簡易設定で選べる配色プリセット（全10色スロットを一括で切り替える）
    enum GenericColorScheme: String, CaseIterable, Hashable {
        case original = "デフォルト"
        case sumi     = "墨"
        case sakura   = "桜"
        case hisui    = "翡翠"
        /// 詳細設定（スロットごとのRGB自由選択）を使う。実際の色は`genericTileColorMode`が`.detailed`の間は
        /// カスタムRGBを使うため、この`colors`の値そのものは描画には使われない
        case custom   = "（カスタム）"

        var colors: GenericTileColors {
            func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r / 255, green: g / 255, blue: b / 255) }
            switch self {
            case .original, .custom:
                return GenericTileColors(
                    manzuDigit: rgb(0, 0, 0), manzuWan: rgb(153, 0, 0),
                    pinzuRed: rgb(153, 0, 0), pinzuGreen: rgb(4, 60, 40),
                    souzuRed: rgb(153, 0, 0), souzuGreen: rgb(4, 60, 40),
                    honorWind: rgb(0, 0, 0), honorHatsu: rgb(4, 60, 40), honorChun: rgb(153, 0, 0),
                    akaDora: rgb(153, 0, 0), souzuBirdAccent: rgb(153, 0, 0)
                )
            case .sumi:
                return GenericTileColors(
                    manzuDigit: rgb(14, 23, 43), manzuWan: rgb(31, 54, 97),
                    pinzuRed: rgb(74, 74, 74), pinzuGreen: rgb(46, 46, 46),
                    souzuRed: rgb(74, 74, 74), souzuGreen: rgb(46, 46, 46),
                    honorWind: rgb(26, 26, 26), honorHatsu: rgb(46, 46, 46), honorChun: rgb(74, 74, 74),
                    akaDora: rgb(138, 31, 31), souzuBirdAccent: rgb(74, 74, 74)
                )
            case .sakura:
                return GenericTileColors(
                    manzuDigit: rgb(255, 120, 130), manzuWan: rgb(90, 73, 49),
                    pinzuRed: rgb(255, 120, 130), pinzuGreen: rgb(90, 73, 49),
                    souzuRed: rgb(244, 164, 192), souzuGreen: rgb(0, 0, 0),
                    honorWind: rgb(255, 140, 130), honorHatsu: rgb(4, 60, 40), honorChun: rgb(255, 165, 125),
                    akaDora: rgb(184, 48, 90), souzuBirdAccent: rgb(38, 62, 15)
                )
            case .hisui:
                return GenericTileColors(
                    manzuDigit: rgb(14, 41, 29), manzuWan: rgb(32, 88, 63),
                    pinzuRed: rgb(137, 106, 41), pinzuGreen: rgb(32, 88, 63),
                    souzuRed: rgb(137, 106, 41), souzuGreen: rgb(32, 88, 63),
                    honorWind: rgb(14, 41, 29), honorHatsu: rgb(32, 88, 63), honorChun: rgb(137, 106, 41),
                    akaDora: rgb(163, 39, 58), souzuBirdAccent: rgb(137, 106, 41)
                )
            }
        }
    }

    var genericTileColors: GenericTileColors {
        guard genericTileColorMode == .detailed else { return genericColorScheme.colors }
        func resolve(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r, green: g, blue: b) }
        return GenericTileColors(
            manzuDigit: resolve(genericManzuDigitColorRed, genericManzuDigitColorGreen, genericManzuDigitColorBlue),
            manzuWan:   resolve(genericManzuWanColorRed, genericManzuWanColorGreen, genericManzuWanColorBlue),
            pinzuRed:   resolve(genericPinzuRedColorRed, genericPinzuRedColorGreen, genericPinzuRedColorBlue),
            pinzuGreen: resolve(genericPinzuGreenColorRed, genericPinzuGreenColorGreen, genericPinzuGreenColorBlue),
            souzuRed:   resolve(genericSouzuRedColorRed, genericSouzuRedColorGreen, genericSouzuRedColorBlue),
            souzuGreen: resolve(genericSouzuGreenColorRed, genericSouzuGreenColorGreen, genericSouzuGreenColorBlue),
            honorWind:  resolve(genericHonorWindColorRed, genericHonorWindColorGreen, genericHonorWindColorBlue),
            honorHatsu: resolve(genericHonorHatsuColorRed, genericHonorHatsuColorGreen, genericHonorHatsuColorBlue),
            honorChun:  resolve(genericHonorChunColorRed, genericHonorChunColorGreen, genericHonorChunColorBlue),
            akaDora:    resolve(genericAkaDoraColorRed, genericAkaDoraColorGreen, genericAkaDoraColorBlue),
            souzuBirdAccent: resolve(genericSouzuBirdAccentColorRed, genericSouzuBirdAccentColorGreen, genericSouzuBirdAccentColorBlue)
        )
    }

    /// 牌のラベル（"m5","p0","z6"等）から、汎用テーマの画像アセットのベース名を求める（赤ドラはaka_接頭辞の別画像）
    static func genericBaseName(for label: String) -> String {
        switch label {
        case "m0": return "aka_m5"
        case "p0": return "aka_p5"
        case "s0": return "aka_s5"
        default:   return label
        }
    }

    /// 汎用テーマで牌を描画するために必要なレイヤー一覧（固定レイヤー＋色付けするマスクのリスト）
    static func genericTileLayers(for label: String, colors: GenericTileColors) -> (fixed: String, masks: [(name: String, color: Color)])? {
        let base = genericBaseName(for: label)
        let fixedName = "original/\(base)_fixed"
        guard UIImage(named: fixedName) != nil else { return nil }

        // 赤ドラ（赤5萬・赤5筒・赤5索）は種類によらず共通の色を使う
        if label == "m0" || label == "p0" || label == "s0" {
            let masks: [(name: String, color: Color)] = ["black", "red", "green"].compactMap { slot in
                let maskName = "original/\(base)_mask_\(slot)"
                guard UIImage(named: maskName) != nil else { return nil }
                return (maskName, colors.akaDora)
            }
            return (fixedName, masks)
        }

        let slotOrder: [(slot: String, color: Color)]
        switch label.first {
        case "m": slotOrder = [("black", colors.manzuDigit), ("red", colors.manzuWan)]
        case "p": slotOrder = [("red", colors.pinzuRed), ("green", colors.pinzuGreen)]
        case "s": slotOrder = label == "s1"
            ? [("red", colors.souzuBirdAccent), ("green", colors.souzuGreen)]
            : [("red", colors.souzuRed), ("green", colors.souzuGreen)]
        case "z":
            switch label {
            case "z1", "z2", "z3", "z4": slotOrder = [("black", colors.honorWind)]
            case "z6": slotOrder = [("green", colors.honorHatsu)]
            case "z7": slotOrder = [("red", colors.honorChun)]
            default:   slotOrder = []
            }
        default: slotOrder = []
        }

        let masks: [(name: String, color: Color)] = slotOrder.compactMap { slot, color in
            let maskName = "original/\(base)_mask_\(slot)"
            guard UIImage(named: maskName) != nil else { return nil }
            return (maskName, color)
        }
        return (fixedName, masks)
    }

    enum BoardTheme: String, CaseIterable, Hashable {
        case original = "オリジナル"
        case animal   = "アニマル"
        case canvas   = "キャンバス"
    }

    /// 「アニマル」テーマで選べる動物の背景画像
    enum AnimalBoardBackground: String, CaseIterable, Hashable {
        case lesserPanda = "レッサーパンダ"
        case cat         = "ねこ"
        case rabbit      = "うさぎ"
        case shiba       = "しばいぬ"
        case fox         = "きつね"

        var imageName: String {
            switch self {
            case .lesserPanda: return "original/boardBackgroundRedPanda"
            case .cat:         return "original/boardBackgroundCat"
            case .rabbit:      return "original/boardBackgroundRabbit"
            case .shiba:       return "original/boardBackgroundShiba"
            case .fox:         return "original/boardBackgroundFox"
            }
        }
    }

    /// 「キャンバス」テーマで選べるキャンバス枠。それぞれ独立に背景色・手書き内容を保存できる
    enum CanvasSlot: Int, CaseIterable, Hashable {
        case slot1, slot2, slot3, slot4, slot5

        var label: String { "キャンバス\(rawValue + 1)" }
    }

    /// 背景「オリジナル」テーマの簡易設定で選べるプリセットカラー
    enum BoardBackgroundColor: String, CaseIterable, Hashable {
        case green  = "グリーン"
        case brown  = "ブラウン"
        case blue   = "ブルー"
        case red    = "レッド"
        case black  = "ブラック"
        /// ピッカーで自由に色を選ぶ。実際の色は`boardBackgroundColorMode`が`.detailed`の間はカスタムRGBを使うため、
        /// この`color`の値そのものは描画には使われない
        case custom = "（カスタム）"

        var color: Color {
            switch self {
            case .green:  return Color(red: 55/255,  green: 125/255, blue: 45/255)
            case .brown:  return Color(red: 110/255, green: 75/255,  blue: 45/255)
            case .blue:   return Color(red: 40/255,  green: 70/255,  blue: 110/255)
            case .red:    return Color(red: 130/255, green: 40/255,  blue: 40/255)
            case .black:  return Color(red: 35/255,  green: 35/255,  blue: 38/255)
            case .custom: return Color(red: 100/255, green: 100/255, blue: 100/255)
            }
        }
    }

    enum SoundTheme: String, CaseIterable, Hashable {
        case original = "オリジナル"

        func soundName(for action: String) -> String {
            switch self {
            case .original: return action
            }
        }
    }

    enum BGMMode: String, CaseIterable, Hashable {
        case bulk     = "一括設定"
        case perRound = "局ごとに設定"
    }

    /// 対局中に流せるBGMの一覧。各局（東一局〜南四局）に個別に割り当てる
    enum BGMTrack: String, CaseIterable, Hashable {
        case jadeTiles     = "Jade Tiles"
        case oikaze        = "追い風"
        case shippu        = "疾風"
        case attakaOnsen   = "あったか温泉"
        case senkoHanabi   = "線香花火"
        case uchiageHanabi = "打ち上げ花火"
        case yunagi        = "夕凪"
        case kaminokoe     = "神ノ声"

        var bgmName: String {
            switch self {
            case .jadeTiles:     return "BGM/GameBGM/jadetiles"
            case .oikaze:        return "BGM/GameBGM/oikaze"
            case .shippu:        return "BGM/GameBGM/shippu"
            case .attakaOnsen:   return "BGM/GameBGM/attakaonsen"
            case .senkoHanabi:   return "BGM/GameBGM/senkohanabi"
            case .uchiageHanabi: return "BGM/GameBGM/uchiagehanabi"
            case .yunagi:        return "BGM/GameBGM/yunagi"
            case .kaminokoe:     return "BGM/GameBGM/kaminokoe"
            }
        }
    }

    enum TileBackColor: String, CaseIterable, Hashable {
        case gold   = "ゴールド"
        case red    = "レッド"
        case green  = "グリーン"
        case blue   = "ブルー"
        case black  = "ブラック"
        /// ピッカーで自由に色を選ぶ。実際の色は`tileBackColorMode`が`.detailed`の間はカスタムRGBを使うため、
        /// この`color`の値そのものは描画には使われない
        case custom = "（カスタム）"

        var color: Color {
            switch self {
            case .gold:   return Color(red: 229/255, green: 179/255, blue: 67/255)
            case .red:    return Color(red: 190/255, green: 60/255,  blue: 60/255)
            case .green:  return Color(red: 60/255,  green: 140/255, blue: 90/255)
            case .blue:   return Color(red: 60/255,  green: 100/255, blue: 180/255)
            case .black:  return Color(red: 45/255,  green: 45/255,  blue: 48/255)
            case .custom: return Color(red: 100/255, green: 100/255, blue: 100/255)
            }
        }
    }

    enum TileBackColorMode: String, CaseIterable, Hashable {
        case simple   = "簡易設定"
        case detailed = "詳細設定"
    }

    /// 牌デザイン（裏）の簡易設定で選べるテーマ
    enum TileBackDesignTheme: String, CaseIterable, Hashable {
        case original = "オリジナル"
        case striped  = "ボーダー"
    }

    /// 「ボーダー」テーマの簡易設定で選べる配色プリセット（本数・2色をまとめて切り替える）
    enum TileBackColorScheme: String, CaseIterable, Hashable {
        case original    = "デフォルト"
        case lesserPanda = "レッサーパンダ"
        case manul       = "マヌルネコ"
        case zebra       = "しまうま"
        /// 本数・カラー1・カラー2を自由に設定する。実際の値は`tileBackColorMode`が`.detailed`の間は
        /// カスタム値を使うため、この`count`/`color1`/`color2`の値そのものは描画には使われない
        case custom      = "（カスタム）"

        var count: Int {
            switch self {
            case .original:    return 2
            case .lesserPanda: return 5
            case .manul:       return 5
            case .zebra:       return 5
            case .custom:      return 2
            }
        }

        var color1: Color {
            func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r / 255, green: g / 255, blue: b / 255) }
            switch self {
            case .original:    return rgb(190, 60, 60)
            case .lesserPanda: return rgb(196, 138, 82)
            case .manul:       return rgb(122, 124, 128)
            case .zebra:       return rgb(30, 30, 30)
            case .custom:      return rgb(190, 60, 60)
            }
        }

        var color2: Color {
            func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r / 255, green: g / 255, blue: b / 255) }
            switch self {
            case .original:    return rgb(229, 179, 67)
            case .lesserPanda: return rgb(92, 55, 32)
            case .manul:       return rgb(238, 238, 233)
            case .zebra:       return rgb(245, 245, 240)
            case .custom:      return rgb(229, 179, 67)
            }
        }
    }

    /// 牌裏の実際の描画方法。単色か、指定本数・2色の横帯（ボーダー）か
    enum TileBackAppearance: Hashable {
        case solid(Color)
        case striped(count: Int, color1: Color, color2: Color)
    }

    /// ボーダーの本数として選べる範囲（1本なら単色と同じなので、テーマとしては2本から）
    static let tileBackBorderCountRange = 2...5

    /// 詳細設定（RGB自由選択）で使う背景のカスタムカラー
    var boardBackgroundColorCustom: Color {
        Color(red: boardBackgroundColorRed, green: boardBackgroundColorGreen, blue: boardBackgroundColorBlue)
    }

    /// 実際に描画に使う背景画像。テーマが「アニマル」の場合は選択中の動物の画像、それ以外は単色背景のためnil
    var effectiveBoardImageName: String? {
        switch boardTheme {
        case .original, .canvas: return nil
        case .animal:             return animalBoardBackground.imageName
        }
    }

    /// 実際に描画に使う背景「オリジナル」テーマの色。簡易/詳細設定でプリセットかRGB自由選択かが切り替わる
    var boardBackgroundColor: Color {
        if boardTheme == .canvas { return boardCanvasBackgroundColor }
        return boardBackgroundColorMode == .detailed ? boardBackgroundColorCustom : boardBackgroundColorPreset.color
    }

    /// キャンバス枠の表示名。名前が未設定なら「キャンバス1」のような既定名を返す
    func canvasSlotDisplayName(_ slot: CanvasSlot) -> String {
        let name = canvasSlotNames[slot.rawValue]
        return name.isEmpty ? slot.label : name
    }

    /// 「キャンバス」テーマの背景色（選択中のキャンバス枠のもの）
    var boardCanvasBackgroundColor: Color {
        let i = selectedCanvasSlot.rawValue
        return Color(red: boardCanvasBackgroundColorsRed[i], green: boardCanvasBackgroundColorsGreen[i], blue: boardCanvasBackgroundColorsBlue[i])
    }

    /// 「キャンバス」テーマの手書き画像（選択中のキャンバス枠のもの。背景色の上に重ねて描画する）
    var boardCanvasImage: UIImage? {
        guard let data = boardCanvasImageDatas[selectedCanvasSlot.rawValue] else { return nil }
        return UIImage(data: data)
    }

    /// 詳細設定（RGB自由選択）のカスタムカラー
    var tileBackColorCustom: Color {
        Color(red: tileBackColorCustomRed, green: tileBackColorCustomGreen, blue: tileBackColorCustomBlue)
    }

    /// 詳細設定（RGB自由選択）のボーダーのカスタムカラー
    var tileBackBorderColor1Custom: Color {
        Color(red: tileBackBorderColor1CustomRed, green: tileBackBorderColor1CustomGreen, blue: tileBackBorderColor1CustomBlue)
    }
    var tileBackBorderColor2Custom: Color {
        Color(red: tileBackBorderColor2CustomRed, green: tileBackBorderColor2CustomGreen, blue: tileBackBorderColor2CustomBlue)
    }

    /// 実際に描画に使う牌裏の見た目。簡易/詳細設定でプリセットかRGB自由選択かが切り替わる
    var effectiveTileBackAppearance: TileBackAppearance {
        switch tileBackDesignTheme {
        case .original:
            return .solid(tileBackColorMode == .detailed ? tileBackColorCustom : tileBackColor.color)
        case .striped:
            if tileBackColorMode == .detailed {
                return .striped(count: tileBackBorderCount, color1: tileBackBorderColor1Custom, color2: tileBackBorderColor2Custom)
            } else {
                let scheme = tileBackColorScheme
                return .striped(count: scheme.count, color1: scheme.color1, color2: scheme.color2)
            }
        }
    }

    // MARK: - Persistence
    func save() {
        let ud = UserDefaults.standard
        ud.set(haikyuGenten, forKey: "haikyuGenten")
        ud.set(junikitenRanks, forKey: "junikitenRanks")
        ud.set(junkitenRounding, forKey: "junkitenRounding")
        ud.set(renpuFu.rawValue, forKey: "renpuFu")
        ud.set(akadoraMan, forKey: "akadoraMan")
        ud.set(akadoraPin, forKey: "akadoraPin")
        ud.set(akadoraSou, forKey: "akadoraSou")
        ud.set(kuitanAri, forKey: "kuitanAri")
        ud.set(kuichikaeLevel.rawValue, forKey: "kuichikaeLevel")
        ud.set(kyokuCount.rawValue, forKey: "kyokuCount")
        ud.set(tochukuryokuAri, forKey: "tochukuryokuAri")
        ud.set(nagashiManganAri, forKey: "nagashiManganAri")
        ud.set(notenSengenAri, forKey: "notenSengenAri")
        ud.set(notenBatsuAri, forKey: "notenBatsuAri")
        ud.set(dojiHuleMax.rawValue, forKey: "dojiHuleMax")
        ud.set(renzhuFang.rawValue, forKey: "renzhuFang")
        ud.set(tobiEndAri, forKey: "tobiEndAri")
        ud.set(orasudomeAri, forKey: "orasudomeAri")
        ud.set(enchossenFang.rawValue, forKey: "enchossenFang")
        ud.set(ippatsuAri, forKey: "ippatsuAri")
        ud.set(uradoraAri, forKey: "uradoraAri")
        ud.set(kandoraAri, forKey: "kandoraAri")
        ud.set(kandoraNochigakeAri, forKey: "kandoraNochigakeAri")
        ud.set(kanUraAri, forKey: "kanUraAri")
        ud.set(noTsumoBanRiichiAri, forKey: "noTsumoBanRiichiAri")
        ud.set(riichiAnkanLevel.rawValue, forKey: "riichiAnkanLevel")
        ud.set(showHandDisplayOption, forKey: "showHandDisplayOption")
        ud.set(showTeyakuList, forKey: "showTeyakuList")
        ud.set(showHowToPlayAssist, forKey: "showHowToPlayAssist")
        ud.set(agariHaiDisplay, forKey: "agariHaiDisplay")
        ud.set(dapaiAssist, forKey: "dapaiAssist")
        ud.set(fulouAssist, forKey: "fulouAssist")
        ud.set(thinkingTimeMode.rawValue, forKey: "thinkingTimeMode")
        ud.set(yakumanFukugouAri, forKey: "yakumanFukugouAri")
        ud.set(doubleYakumanAri, forKey: "doubleYakumanAri")
        ud.set(kazoeYakumanAri, forKey: "kazoeYakumanAri")
        ud.set(yakumanPaoAri, forKey: "yakumanPaoAri")
        ud.set(kiriageMangan, forKey: "kiriageMangan")
        ud.set(cpuStyles.map { $0.rawValue }, forKey: "cpuStyles")
        ud.set(selectedPreset.rawValue, forKey: "selectedPreset")
        ud.set(tileTheme.rawValue, forKey: "tileTheme")
        ud.set(genericTileColorMode.rawValue, forKey: "genericTileColorMode")
        ud.set(genericColorScheme.rawValue, forKey: "genericColorScheme")
        ud.set(genericManzuDigitColorRed, forKey: "genericManzuDigitColorRed")
        ud.set(genericManzuDigitColorGreen, forKey: "genericManzuDigitColorGreen")
        ud.set(genericManzuDigitColorBlue, forKey: "genericManzuDigitColorBlue")
        ud.set(genericManzuWanColorRed, forKey: "genericManzuWanColorRed")
        ud.set(genericManzuWanColorGreen, forKey: "genericManzuWanColorGreen")
        ud.set(genericManzuWanColorBlue, forKey: "genericManzuWanColorBlue")
        ud.set(genericPinzuRedColorRed, forKey: "genericPinzuRedColorRed")
        ud.set(genericPinzuRedColorGreen, forKey: "genericPinzuRedColorGreen")
        ud.set(genericPinzuRedColorBlue, forKey: "genericPinzuRedColorBlue")
        ud.set(genericPinzuGreenColorRed, forKey: "genericPinzuGreenColorRed")
        ud.set(genericPinzuGreenColorGreen, forKey: "genericPinzuGreenColorGreen")
        ud.set(genericPinzuGreenColorBlue, forKey: "genericPinzuGreenColorBlue")
        ud.set(genericSouzuRedColorRed, forKey: "genericSouzuRedColorRed")
        ud.set(genericSouzuRedColorGreen, forKey: "genericSouzuRedColorGreen")
        ud.set(genericSouzuRedColorBlue, forKey: "genericSouzuRedColorBlue")
        ud.set(genericSouzuGreenColorRed, forKey: "genericSouzuGreenColorRed")
        ud.set(genericSouzuGreenColorGreen, forKey: "genericSouzuGreenColorGreen")
        ud.set(genericSouzuGreenColorBlue, forKey: "genericSouzuGreenColorBlue")
        ud.set(genericHonorWindColorRed, forKey: "genericHonorWindColorRed")
        ud.set(genericHonorWindColorGreen, forKey: "genericHonorWindColorGreen")
        ud.set(genericHonorWindColorBlue, forKey: "genericHonorWindColorBlue")
        ud.set(genericHonorHatsuColorRed, forKey: "genericHonorHatsuColorRed")
        ud.set(genericHonorHatsuColorGreen, forKey: "genericHonorHatsuColorGreen")
        ud.set(genericHonorHatsuColorBlue, forKey: "genericHonorHatsuColorBlue")
        ud.set(genericHonorChunColorRed, forKey: "genericHonorChunColorRed")
        ud.set(genericHonorChunColorGreen, forKey: "genericHonorChunColorGreen")
        ud.set(genericHonorChunColorBlue, forKey: "genericHonorChunColorBlue")
        ud.set(genericAkaDoraColorRed, forKey: "genericAkaDoraColorRed")
        ud.set(genericAkaDoraColorGreen, forKey: "genericAkaDoraColorGreen")
        ud.set(genericAkaDoraColorBlue, forKey: "genericAkaDoraColorBlue")
        ud.set(genericSouzuBirdAccentColorRed, forKey: "genericSouzuBirdAccentColorRed")
        ud.set(genericSouzuBirdAccentColorGreen, forKey: "genericSouzuBirdAccentColorGreen")
        ud.set(genericSouzuBirdAccentColorBlue, forKey: "genericSouzuBirdAccentColorBlue")
        ud.set(boardTheme.rawValue, forKey: "boardTheme")
        ud.set(animalBoardBackground.rawValue, forKey: "animalBoardBackground")
        ud.set(boardBackgroundColorMode.rawValue, forKey: "boardBackgroundColorMode")
        ud.set(boardBackgroundColorPreset.rawValue, forKey: "boardBackgroundColorPreset")
        ud.set(boardBackgroundColorRed, forKey: "boardBackgroundColorRed")
        ud.set(boardBackgroundColorGreen, forKey: "boardBackgroundColorGreen")
        ud.set(boardBackgroundColorBlue, forKey: "boardBackgroundColorBlue")
        ud.set(selectedCanvasSlot.rawValue, forKey: "selectedCanvasSlot")
        ud.set(canvasSlotNames, forKey: "canvasSlotNames")
        for slot in CanvasSlot.allCases {
            let i = slot.rawValue
            ud.set(boardCanvasBackgroundColorsRed[i], forKey: "boardCanvasBackgroundColorRed_\(i)")
            ud.set(boardCanvasBackgroundColorsGreen[i], forKey: "boardCanvasBackgroundColorGreen_\(i)")
            ud.set(boardCanvasBackgroundColorsBlue[i], forKey: "boardCanvasBackgroundColorBlue_\(i)")
            if let data = boardCanvasDrawingDatas[i] {
                ud.set(data, forKey: "boardCanvasDrawingData_\(i)")
            } else {
                ud.removeObject(forKey: "boardCanvasDrawingData_\(i)")
            }
            if let data = boardCanvasImageDatas[i] {
                ud.set(data, forKey: "boardCanvasImageData_\(i)")
            } else {
                ud.removeObject(forKey: "boardCanvasImageData_\(i)")
            }
        }
        ud.set(soundTheme.rawValue, forKey: "soundTheme")
        ud.set(tileBackDesignTheme.rawValue, forKey: "tileBackDesignTheme")
        ud.set(tileBackColor.rawValue, forKey: "tileBackColor")
        ud.set(tileBackColorMode.rawValue, forKey: "tileBackColorMode")
        ud.set(tileBackColorCustomRed, forKey: "tileBackColorCustomRed")
        ud.set(tileBackColorCustomGreen, forKey: "tileBackColorCustomGreen")
        ud.set(tileBackColorCustomBlue, forKey: "tileBackColorCustomBlue")
        ud.set(tileBackBorderCount, forKey: "tileBackBorderCount")
        ud.set(tileBackColorScheme.rawValue, forKey: "tileBackColorScheme")
        ud.set(tileBackBorderColor1CustomRed, forKey: "tileBackBorderColor1CustomRed")
        ud.set(tileBackBorderColor1CustomGreen, forKey: "tileBackBorderColor1CustomGreen")
        ud.set(tileBackBorderColor1CustomBlue, forKey: "tileBackBorderColor1CustomBlue")
        ud.set(tileBackBorderColor2CustomRed, forKey: "tileBackBorderColor2CustomRed")
        ud.set(tileBackBorderColor2CustomGreen, forKey: "tileBackBorderColor2CustomGreen")
        ud.set(tileBackBorderColor2CustomBlue, forKey: "tileBackBorderColor2CustomBlue")
        ud.set(bgmByRound.map { $0.rawValue }, forKey: "bgmByRound")
        ud.set(bgmMode.rawValue, forKey: "bgmMode")
        ud.set(bgmBulkTrack.rawValue, forKey: "bgmBulkTrack")
    }

    static func load() -> GameSettings {
        let s = GameSettings()
        let ud = UserDefaults.standard
        guard ud.object(forKey: "haikyuGenten") != nil else {
            print("[GameSettings] load() — no saved data, using defaults")
            return s
        }
        s.haikyuGenten       = ud.integer(forKey: "haikyuGenten")
        s.junikitenRanks     = ud.array(forKey: "junikitenRanks") as? [Int] ?? s.junikitenRanks
        s.junkitenRounding   = ud.bool(forKey: "junkitenRounding")
        s.renpuFu            = RenpuFu(rawValue: ud.string(forKey: "renpuFu") ?? "") ?? s.renpuFu
        s.akadoraMan         = ud.integer(forKey: "akadoraMan")
        s.akadoraPin         = ud.integer(forKey: "akadoraPin")
        s.akadoraSou         = ud.integer(forKey: "akadoraSou")
        s.kuitanAri          = ud.bool(forKey: "kuitanAri")
        s.kuichikaeLevel     = KuichikaeLevel(rawValue: ud.string(forKey: "kuichikaeLevel") ?? "") ?? s.kuichikaeLevel
        s.kyokuCount         = KyokuCount(rawValue: ud.string(forKey: "kyokuCount") ?? "") ?? s.kyokuCount
        s.tochukuryokuAri    = ud.bool(forKey: "tochukuryokuAri")
        s.nagashiManganAri   = ud.bool(forKey: "nagashiManganAri")
        s.notenSengenAri     = ud.bool(forKey: "notenSengenAri")
        s.notenBatsuAri      = ud.bool(forKey: "notenBatsuAri")
        s.dojiHuleMax        = DojiHuleMax(rawValue: ud.string(forKey: "dojiHuleMax") ?? "") ?? s.dojiHuleMax
        s.renzhuFang         = RenzhuFang(rawValue: ud.string(forKey: "renzhuFang") ?? "") ?? s.renzhuFang
        s.tobiEndAri         = ud.bool(forKey: "tobiEndAri")
        s.orasudomeAri       = ud.bool(forKey: "orasudomeAri")
        s.enchossenFang      = EnchossenFang(rawValue: ud.string(forKey: "enchossenFang") ?? "") ?? s.enchossenFang
        s.ippatsuAri         = ud.bool(forKey: "ippatsuAri")
        s.uradoraAri         = ud.bool(forKey: "uradoraAri")
        s.kandoraAri         = ud.bool(forKey: "kandoraAri")
        s.kandoraNochigakeAri = ud.bool(forKey: "kandoraNochigakeAri")
        s.kanUraAri          = ud.bool(forKey: "kanUraAri")
        s.noTsumoBanRiichiAri = ud.bool(forKey: "noTsumoBanRiichiAri")
        s.riichiAnkanLevel   = RiichiAnkanLevel(rawValue: ud.string(forKey: "riichiAnkanLevel") ?? "") ?? s.riichiAnkanLevel
        s.showHandDisplayOption = ud.bool(forKey: "showHandDisplayOption")
        s.showTeyakuList     = (ud.object(forKey: "showTeyakuList") as? Bool) ?? s.showTeyakuList
        s.showHowToPlayAssist = (ud.object(forKey: "showHowToPlayAssist") as? Bool) ?? s.showHowToPlayAssist
        s.agariHaiDisplay    = ud.bool(forKey: "agariHaiDisplay")
        s.dapaiAssist        = ud.bool(forKey: "dapaiAssist")
        s.fulouAssist        = ud.bool(forKey: "fulouAssist")
        s.thinkingTimeMode   = ThinkingTimeMode(rawValue: ud.string(forKey: "thinkingTimeMode") ?? "") ?? s.thinkingTimeMode
        s.yakumanFukugouAri  = ud.bool(forKey: "yakumanFukugouAri")
        s.doubleYakumanAri   = ud.bool(forKey: "doubleYakumanAri")
        s.kazoeYakumanAri    = ud.bool(forKey: "kazoeYakumanAri")
        s.yakumanPaoAri      = ud.bool(forKey: "yakumanPaoAri")
        s.kiriageMangan      = ud.bool(forKey: "kiriageMangan")
        if let rawStyles = ud.array(forKey: "cpuStyles") as? [String], rawStyles.count == s.cpuStyles.count {
            s.cpuStyles = rawStyles.enumerated().map { CpuStyle(rawValue: $1) ?? s.cpuStyles[$0] }
        }
        s.selectedPreset     = Preset(rawValue: ud.string(forKey: "selectedPreset") ?? "") ?? .custom
        s.tileTheme          = TileTheme(rawValue: ud.string(forKey: "tileTheme") ?? "") ?? .original
        s.genericTileColorMode = TileBackColorMode(rawValue: ud.string(forKey: "genericTileColorMode") ?? "") ?? .simple
        s.genericColorScheme = GenericColorScheme(rawValue: ud.string(forKey: "genericColorScheme") ?? "") ?? .original
        if ud.object(forKey: "genericManzuDigitColorRed") != nil {
            s.genericManzuDigitColorRed   = ud.double(forKey: "genericManzuDigitColorRed")
            s.genericManzuDigitColorGreen = ud.double(forKey: "genericManzuDigitColorGreen")
            s.genericManzuDigitColorBlue  = ud.double(forKey: "genericManzuDigitColorBlue")
            s.genericManzuWanColorRed     = ud.double(forKey: "genericManzuWanColorRed")
            s.genericManzuWanColorGreen   = ud.double(forKey: "genericManzuWanColorGreen")
            s.genericManzuWanColorBlue    = ud.double(forKey: "genericManzuWanColorBlue")
            s.genericPinzuRedColorRed     = ud.double(forKey: "genericPinzuRedColorRed")
            s.genericPinzuRedColorGreen   = ud.double(forKey: "genericPinzuRedColorGreen")
            s.genericPinzuRedColorBlue    = ud.double(forKey: "genericPinzuRedColorBlue")
            s.genericPinzuGreenColorRed   = ud.double(forKey: "genericPinzuGreenColorRed")
            s.genericPinzuGreenColorGreen = ud.double(forKey: "genericPinzuGreenColorGreen")
            s.genericPinzuGreenColorBlue  = ud.double(forKey: "genericPinzuGreenColorBlue")
            s.genericSouzuRedColorRed     = ud.double(forKey: "genericSouzuRedColorRed")
            s.genericSouzuRedColorGreen   = ud.double(forKey: "genericSouzuRedColorGreen")
            s.genericSouzuRedColorBlue    = ud.double(forKey: "genericSouzuRedColorBlue")
            s.genericSouzuGreenColorRed   = ud.double(forKey: "genericSouzuGreenColorRed")
            s.genericSouzuGreenColorGreen = ud.double(forKey: "genericSouzuGreenColorGreen")
            s.genericSouzuGreenColorBlue  = ud.double(forKey: "genericSouzuGreenColorBlue")
            s.genericHonorWindColorRed    = ud.double(forKey: "genericHonorWindColorRed")
            s.genericHonorWindColorGreen  = ud.double(forKey: "genericHonorWindColorGreen")
            s.genericHonorWindColorBlue   = ud.double(forKey: "genericHonorWindColorBlue")
            s.genericHonorHatsuColorRed   = ud.double(forKey: "genericHonorHatsuColorRed")
            s.genericHonorHatsuColorGreen = ud.double(forKey: "genericHonorHatsuColorGreen")
            s.genericHonorHatsuColorBlue  = ud.double(forKey: "genericHonorHatsuColorBlue")
            s.genericHonorChunColorRed    = ud.double(forKey: "genericHonorChunColorRed")
            s.genericHonorChunColorGreen  = ud.double(forKey: "genericHonorChunColorGreen")
            s.genericHonorChunColorBlue   = ud.double(forKey: "genericHonorChunColorBlue")
            s.genericAkaDoraColorRed      = ud.double(forKey: "genericAkaDoraColorRed")
            s.genericAkaDoraColorGreen    = ud.double(forKey: "genericAkaDoraColorGreen")
            s.genericAkaDoraColorBlue     = ud.double(forKey: "genericAkaDoraColorBlue")
            s.genericSouzuBirdAccentColorRed   = ud.double(forKey: "genericSouzuBirdAccentColorRed")
            s.genericSouzuBirdAccentColorGreen = ud.double(forKey: "genericSouzuBirdAccentColorGreen")
            s.genericSouzuBirdAccentColorBlue  = ud.double(forKey: "genericSouzuBirdAccentColorBlue")
        }
        s.boardTheme         = BoardTheme(rawValue: ud.string(forKey: "boardTheme") ?? "") ?? .original
        s.animalBoardBackground = AnimalBoardBackground(rawValue: ud.string(forKey: "animalBoardBackground") ?? "") ?? .lesserPanda
        s.boardBackgroundColorMode = TileBackColorMode(rawValue: ud.string(forKey: "boardBackgroundColorMode") ?? "") ?? .simple
        s.boardBackgroundColorPreset = BoardBackgroundColor(rawValue: ud.string(forKey: "boardBackgroundColorPreset") ?? "") ?? .green
        if ud.object(forKey: "boardBackgroundColorRed") != nil {
            s.boardBackgroundColorRed   = ud.double(forKey: "boardBackgroundColorRed")
            s.boardBackgroundColorGreen = ud.double(forKey: "boardBackgroundColorGreen")
            s.boardBackgroundColorBlue  = ud.double(forKey: "boardBackgroundColorBlue")
        }
        s.selectedCanvasSlot = CanvasSlot(rawValue: ud.integer(forKey: "selectedCanvasSlot")) ?? .slot1
        if let names = ud.stringArray(forKey: "canvasSlotNames"), names.count == CanvasSlot.allCases.count {
            s.canvasSlotNames = names
        }
        if ud.object(forKey: "boardCanvasBackgroundColorRed_0") != nil {
            for slot in CanvasSlot.allCases {
                let i = slot.rawValue
                s.boardCanvasBackgroundColorsRed[i]   = ud.double(forKey: "boardCanvasBackgroundColorRed_\(i)")
                s.boardCanvasBackgroundColorsGreen[i] = ud.double(forKey: "boardCanvasBackgroundColorGreen_\(i)")
                s.boardCanvasBackgroundColorsBlue[i]  = ud.double(forKey: "boardCanvasBackgroundColorBlue_\(i)")
                s.boardCanvasDrawingDatas[i] = ud.data(forKey: "boardCanvasDrawingData_\(i)")
                s.boardCanvasImageDatas[i]   = ud.data(forKey: "boardCanvasImageData_\(i)")
            }
        } else {
            // 旧バージョン（キャンバス1枠のみ）からの移行。既存の内容をキャンバス1にそのまま引き継ぐ
            if ud.object(forKey: "boardCanvasBackgroundColorRed") != nil {
                s.boardCanvasBackgroundColorsRed[0]   = ud.double(forKey: "boardCanvasBackgroundColorRed")
                s.boardCanvasBackgroundColorsGreen[0] = ud.double(forKey: "boardCanvasBackgroundColorGreen")
                s.boardCanvasBackgroundColorsBlue[0]  = ud.double(forKey: "boardCanvasBackgroundColorBlue")
            }
            s.boardCanvasDrawingDatas[0] = ud.data(forKey: "boardCanvasDrawingData")
            s.boardCanvasImageDatas[0]   = ud.data(forKey: "boardCanvasImageData")
        }
        s.soundTheme         = SoundTheme(rawValue: ud.string(forKey: "soundTheme") ?? "") ?? .original
        s.tileBackDesignTheme = TileBackDesignTheme(rawValue: ud.string(forKey: "tileBackDesignTheme") ?? "") ?? .original
        s.tileBackColor      = TileBackColor(rawValue: ud.string(forKey: "tileBackColor") ?? "") ?? .gold
        s.tileBackColorMode  = TileBackColorMode(rawValue: ud.string(forKey: "tileBackColorMode") ?? "") ?? .simple
        if ud.object(forKey: "tileBackColorCustomRed") != nil {
            s.tileBackColorCustomRed   = ud.double(forKey: "tileBackColorCustomRed")
            s.tileBackColorCustomGreen = ud.double(forKey: "tileBackColorCustomGreen")
            s.tileBackColorCustomBlue  = ud.double(forKey: "tileBackColorCustomBlue")
        }
        if ud.object(forKey: "tileBackBorderCount") != nil {
            s.tileBackBorderCount = ud.integer(forKey: "tileBackBorderCount")
        }
        s.tileBackColorScheme = TileBackColorScheme(rawValue: ud.string(forKey: "tileBackColorScheme") ?? "") ?? .original
        if ud.object(forKey: "tileBackBorderColor1CustomRed") != nil {
            s.tileBackBorderColor1CustomRed   = ud.double(forKey: "tileBackBorderColor1CustomRed")
            s.tileBackBorderColor1CustomGreen = ud.double(forKey: "tileBackBorderColor1CustomGreen")
            s.tileBackBorderColor1CustomBlue  = ud.double(forKey: "tileBackBorderColor1CustomBlue")
        }
        if ud.object(forKey: "tileBackBorderColor2CustomRed") != nil {
            s.tileBackBorderColor2CustomRed   = ud.double(forKey: "tileBackBorderColor2CustomRed")
            s.tileBackBorderColor2CustomGreen = ud.double(forKey: "tileBackBorderColor2CustomGreen")
            s.tileBackBorderColor2CustomBlue  = ud.double(forKey: "tileBackBorderColor2CustomBlue")
        }
        if let rawTracks = ud.array(forKey: "bgmByRound") as? [String], rawTracks.count == s.bgmByRound.count {
            s.bgmByRound = rawTracks.enumerated().map { BGMTrack(rawValue: $1) ?? s.bgmByRound[$0] }
        }
        s.bgmMode            = BGMMode(rawValue: ud.string(forKey: "bgmMode") ?? "") ?? .bulk
        s.bgmBulkTrack       = BGMTrack(rawValue: ud.string(forKey: "bgmBulkTrack") ?? "") ?? .jadeTiles
        return s
    }

    // MARK: - Enums

    /// CPUの打ち回しタイプ。副露軸（鳴くか門前を貫くか）と攻守軸（押し引き判断をするか）の組み合わせに加え、
    /// 門前守備型からリーチ宣言だけを止めた特殊タイプ（ダマ型）を加えた5種類。
    enum CpuStyle: String, CaseIterable, Hashable {
        case fulouOffense  = "副露攻撃型"
        case fulouDefense  = "副露守備型"
        case menzenOffense = "門前攻撃型"
        case menzenDefense = "門前守備型"
        case damaDefense   = "ダマ型"

        /// 鳴き（チー・ポン）判断を行うか。falseなら門前を貫く。
        var doesFulou: Bool {
            switch self {
            case .fulouOffense, .fulouDefense: return true
            case .menzenOffense, .menzenDefense, .damaDefense: return false
            }
        }

        /// 押し引き（危険牌を避ける）判断を行うか。falseなら常に押す。
        var playsDefense: Bool {
            switch self {
            case .fulouDefense, .menzenDefense, .damaDefense: return true
            case .fulouOffense, .menzenOffense: return false
            }
        }

        /// テンパイ時にリーチを宣言するか。falseなら常にダマテンのまま進める。
        var declaresRiichi: Bool {
            switch self {
            case .damaDefense: return false
            default: return true
            }
        }

        /// 対局前パネルの「詳細設定」タブでの表示名（ダマ型のみ表記を変更）
        var detailPanelLabel: String {
            self == .damaDefense ? "ダマ守備型" : rawValue
        }

        /// 対局前パネルの「簡易」タブで選択できる3種類（CPUの強さ）
        static let simplePanelCases: [CpuStyle] = [.damaDefense, .menzenDefense, .fulouOffense]

        /// 簡易タブでの表示名（絵文字付き）。simplePanelCases以外は通常名を返す
        var simplePanelLabel: String {
            switch self {
            case .damaDefense:   return "ひよこ🐤"
            case .menzenDefense: return "わし🦅"
            case .fulouOffense:  return "らいおん🦁"
            default: return rawValue
            }
        }
    }

    enum RenpuFu: String, CaseIterable, Hashable {
        case two = "2符"
        case four = "4符"
    }

    enum KyokuCount: String, CaseIterable, Hashable {
        case ikkokuSen = "一局戦"
        case tonpuSen  = "東風戦"
        case hanjouSen = "半荘戦"
    }

    enum ThinkingTimeMode: String, CaseIterable, Hashable {
        case unlimited = "無制限"
        case perMove10 = "一打10秒"
        case bank300   = "持ち時間300秒"
    }

    enum KuichikaeLevel: String, CaseIterable, Hashable {
        case none    = "喰い替えなし"
        case suji    = "スジ喰い替えあり"
        case genmotsu = "現物喰い替えもあり"
    }

    enum DojiHuleMax: String, CaseIterable, Hashable {
        case atamahane = "頭ハネ"
        case doubleRon = "ダブロンあり"
        case tripleRon = "トリロンあり"
    }

    enum RenzhuFang: String, CaseIterable, Hashable {
        case none   = "連荘なし"
        case hule   = "和了連荘"
        case tenpai = "テンパイ連荘"
        case noten  = "ノーテン連荘"
    }

    enum EnchossenFang: String, CaseIterable, Hashable {
        case none              = "延長戦なし"
        case suddenDeath       = "サドンデス"
        case renzhuSuddenDeath = "連荘優先サドンデス"
        case fixed4            = "4局固定"
    }

    enum RiichiAnkanLevel: String, CaseIterable, Hashable {
        case allForbidden    = "すべての暗槓不可"
        case noChangeHand    = "牌姿の変わる暗槓不可"
        case noChangeWaiting = "待ちの変わる暗槓不可"
    }

    // MARK: - Preset

    enum Preset: String, CaseIterable, Hashable {
        case tenhou  = "天鳳"
        case mleague = "Mリーグ"
        case custom  = "カスタム"
    }

    var selectedPreset: Preset = .custom

    func applyPreset(_ preset: Preset) {
        switch preset {
        case .tenhou:  applyTenhou()
        case .mleague: applyMleague()
        case .custom:  break
        }
        selectedPreset = preset
    }

    private func applyMleague() {
        haikyuGenten         = 25000
        junikitenRanks       = [10, -10, -30]
        junkitenRounding     = false
        renpuFu              = .two
        akadoraMan           = 1
        akadoraPin           = 1
        akadoraSou           = 1
        kuitanAri            = true
        kuichikaeLevel       = .none
        kyokuCount           = .hanjouSen
        tochukuryokuAri      = false
        nagashiManganAri     = false
        notenSengenAri       = true
        notenBatsuAri        = true
        dojiHuleMax          = .atamahane
        renzhuFang           = .tenpai
        tobiEndAri           = false
        ippatsuAri           = true
        uradoraAri           = true
        kandoraAri           = true
        kandoraNochigakeAri  = false
        kanUraAri            = true
        riichiAnkanLevel     = .noChangeWaiting
        yakumanFukugouAri    = true
        doubleYakumanAri     = false
        kazoeYakumanAri      = false
        yakumanPaoAri        = true
        kiriageMangan        = true
    }

    private func applyTenhou() {
        haikyuGenten         = 25000
        junikitenRanks       = [10, -10, -30]
        junkitenRounding     = false
        renpuFu              = .two
        akadoraMan           = 1
        akadoraPin           = 1
        akadoraSou           = 1
        kuitanAri            = true
        kuichikaeLevel       = .none
        kyokuCount           = .hanjouSen
        tochukuryokuAri      = true
        nagashiManganAri     = false
        notenSengenAri       = false
        notenBatsuAri        = true
        dojiHuleMax          = .atamahane
        renzhuFang           = .tenpai
        tobiEndAri           = true
        ippatsuAri           = true
        uradoraAri           = true
        kandoraAri           = true
        kandoraNochigakeAri  = false
        kanUraAri            = true
        riichiAnkanLevel     = .noChangeWaiting
        yakumanFukugouAri    = true
        doubleYakumanAri     = true
        kazoeYakumanAri      = true
        yakumanPaoAri        = true
        kiriageMangan        = false
    }

}

import Foundation
import Observation

@Observable
final class GameSettings {

    // MARK: - CPU
    var cpuLevel: CpuLevel = .level1

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
    var kyokuCount: KyokuCount = .hanjouSen
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
    var agariHaiDisplay: Bool = false
    var dapaiAssist: Bool = false
    var fulouAssist: Bool = false
    var turnTimeLimit: Int = 0  // 0 = 無制限

    // MARK: - テーマ
    var tileTheme: TileTheme = .standard
    var boardTheme: BoardTheme = .standard
    var soundTheme: SoundTheme = .standard

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
        case standard = "standard"

        func imageName(for label: String) -> String {
            switch self {
            case .standard: return label
            }
        }
    }

    enum BoardTheme: String, CaseIterable, Hashable {
        case standard = "standard"

        var imageName: String {
            switch self {
            case .standard: return "boardBackground"
            }
        }
    }

    enum SoundTheme: String, CaseIterable, Hashable {
        case standard = "standard"

        func soundName(for action: String) -> String {
            switch self {
            case .standard: return action
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
        ud.set(agariHaiDisplay, forKey: "agariHaiDisplay")
        ud.set(dapaiAssist, forKey: "dapaiAssist")
        ud.set(fulouAssist, forKey: "fulouAssist")
        ud.set(turnTimeLimit, forKey: "turnTimeLimit")
        ud.set(yakumanFukugouAri, forKey: "yakumanFukugouAri")
        ud.set(doubleYakumanAri, forKey: "doubleYakumanAri")
        ud.set(kazoeYakumanAri, forKey: "kazoeYakumanAri")
        ud.set(yakumanPaoAri, forKey: "yakumanPaoAri")
        ud.set(kiriageMangan, forKey: "kiriageMangan")
        ud.set(cpuLevel.rawValue, forKey: "cpuLevel")
        ud.set(selectedPreset.rawValue, forKey: "selectedPreset")
        ud.set(tileTheme.rawValue, forKey: "tileTheme")
        ud.set(boardTheme.rawValue, forKey: "boardTheme")
        ud.set(soundTheme.rawValue, forKey: "soundTheme")
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
        s.agariHaiDisplay    = ud.bool(forKey: "agariHaiDisplay")
        s.dapaiAssist        = ud.bool(forKey: "dapaiAssist")
        s.fulouAssist        = ud.bool(forKey: "fulouAssist")
        s.turnTimeLimit      = ud.object(forKey: "turnTimeLimit") != nil ? ud.integer(forKey: "turnTimeLimit") : 0
        s.yakumanFukugouAri  = ud.bool(forKey: "yakumanFukugouAri")
        s.doubleYakumanAri   = ud.bool(forKey: "doubleYakumanAri")
        s.kazoeYakumanAri    = ud.bool(forKey: "kazoeYakumanAri")
        s.yakumanPaoAri      = ud.bool(forKey: "yakumanPaoAri")
        s.kiriageMangan      = ud.bool(forKey: "kiriageMangan")
        s.cpuLevel           = CpuLevel(rawValue: ud.string(forKey: "cpuLevel") ?? "") ?? s.cpuLevel
        s.selectedPreset     = Preset(rawValue: ud.string(forKey: "selectedPreset") ?? "") ?? .custom
        s.tileTheme          = TileTheme(rawValue: ud.string(forKey: "tileTheme") ?? "") ?? .standard
        s.boardTheme         = BoardTheme(rawValue: ud.string(forKey: "boardTheme") ?? "") ?? .standard
        s.soundTheme         = SoundTheme(rawValue: ud.string(forKey: "soundTheme") ?? "") ?? .standard
        return s
    }

    // MARK: - Enums

    enum CpuLevel: String, CaseIterable, Hashable {
        case level1 = "弱い"
        case level2 = "普通"
    }

    enum RenpuFu: String, CaseIterable, Hashable {
        case two = "2符"
        case four = "4符"
    }

    enum KyokuCount: String, CaseIterable, Hashable {
        case ikkokuSen = "一局戦"
        case tonpuSen  = "東風戦"
        case hanjouSen = "東南戦"
        case ichangSen = "一荘戦"
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

//
//  GameSettingsTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("GameSettings Preset")
struct GameSettingsPresetTests {

    // MARK: - currentPreset

    @Test("デフォルト設定はカスタム")
    func defaultIsCustom() {
        let s = GameSettings()
        #expect(s.currentPreset == .custom)
    }

    @Test("天鳳プリセット適用後は currentPreset == .tenhou")
    func applyTenhouMatchesTenhou() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.currentPreset == .tenhou)
    }

    @Test("Mリーグプリセット適用後は currentPreset == .mleague")
    func applyMleagueMatchesMleague() {
        let s = GameSettings()
        s.applyPreset(.mleague)
        #expect(s.currentPreset == .mleague)
    }

    @Test("天鳳適用後に設定変更するとカスタムになる")
    func tenhouThenChangeBecomesCustom() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        s.tobiEndAri = false  // 天鳳はtrue → falseに変更
        #expect(s.currentPreset == .custom)
    }

    @Test("Mリーグ適用後に設定変更するとカスタムになる")
    func mleagueThenChangeBecomesCustom() {
        let s = GameSettings()
        s.applyPreset(.mleague)
        s.notenSengenAri = false  // Mリーグはtrue → falseに変更
        #expect(s.currentPreset == .custom)
    }

    // MARK: - 表示設定はプリセット判定に影響しない

    @Test("天鳳適用後に打牌アシストをオンにしてもカスタムにならない")
    func tenhouDisplaySettingDoesNotBreakPreset() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        s.dapaiAssist = true
        #expect(s.currentPreset == .tenhou)
    }

    @Test("Mリーグ適用後にアガリ牌表示をオンにしてもカスタムにならない")
    func mleagueDisplaySettingDoesNotBreakPreset() {
        let s = GameSettings()
        s.applyPreset(.mleague)
        s.agariHaiDisplay = true
        #expect(s.currentPreset == .mleague)
    }

    @Test("天鳳適用後に手牌表示オプションを変更してもカスタムにならない")
    func tenhouHandDisplayDoesNotBreakPreset() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        s.showHandDisplayOption = true
        #expect(s.currentPreset == .tenhou)
    }

    // MARK: - applyPreset の値確認

    @Test("天鳳プリセット: トビ終了あり")
    func tenhouTobiEnd() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.tobiEndAri == true)
    }

    @Test("天鳳プリセット: ダブル役満あり")
    func tenhouDoubleYakuman() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.doubleYakumanAri == true)
        #expect(s.kazoeYakumanAri == true)
        #expect(s.kiriageMangan == false)
    }

    @Test("Mリーグプリセット: トビ終了なし")
    func mleagueTobiEnd() {
        let s = GameSettings()
        s.applyPreset(.mleague)
        #expect(s.tobiEndAri == false)
    }

    @Test("Mリーグプリセット: ダブル役満なし・切り上げ満貫あり")
    func mleagueYakumanOptions() {
        let s = GameSettings()
        s.applyPreset(.mleague)
        #expect(s.doubleYakumanAri == false)
        #expect(s.kiriageMangan == true)
    }

    @Test("天鳳とMリーグのプリセットは相互に区別される")
    func tenhouAndMleagueAreDifferent() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.currentPreset != .mleague)
        s.applyPreset(.mleague)
        #expect(s.currentPreset != .tenhou)
    }
}

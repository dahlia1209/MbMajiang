//
//  GameSettingsTests.swift
//  MbMajiangTests
//

import Testing
@testable import MbMajiang

@Suite("GameSettings Preset")
struct GameSettingsPresetTests {

    // MARK: - selectedPreset の初期値

    @Test("デフォルトの selectedPreset はカスタム")
    func defaultIsCustom() {
        let s = GameSettings()
        #expect(s.selectedPreset == .custom)
    }

    // MARK: - applyPreset で selectedPreset が切り替わる

    @Test("天鳳プリセット適用後は selectedPreset == .tenhou")
    func applyTenhouSetsSelected() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.selectedPreset == .tenhou)
    }

    @Test("Mリーグプリセット適用後は selectedPreset == .mleague")
    func applyMleagueSetsSelected() {
        let s = GameSettings()
        s.applyPreset(.mleague)
        #expect(s.selectedPreset == .mleague)
    }

    @Test("カスタム適用後は selectedPreset == .custom")
    func applyCustomSetsSelected() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        s.applyPreset(.custom)
        #expect(s.selectedPreset == .custom)
    }

    @Test("天鳳 → Mリーグと切り替えると selectedPreset が変わる")
    func switchPreset() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.selectedPreset == .tenhou)
        s.applyPreset(.mleague)
        #expect(s.selectedPreset == .mleague)
    }

    // MARK: - applyPreset で設定値が反映される

    @Test("天鳳プリセット: トビ終了あり")
    func tenhouTobiEnd() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        #expect(s.tobiEndAri == true)
    }

    @Test("天鳳プリセット: ダブル役満あり・切り上げ満貫なし")
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

    @Test("天鳳とMリーグで設定値が異なる")
    func tenhouAndMleagueDiffer() {
        let t = GameSettings(); t.applyPreset(.tenhou)
        let m = GameSettings(); m.applyPreset(.mleague)
        #expect(t.tobiEndAri != m.tobiEndAri)
        #expect(t.tochukuryokuAri != m.tochukuryokuAri)
        #expect(t.kiriageMangan != m.kiriageMangan)
    }

    // MARK: - 表示設定は selectedPreset に影響しない

    @Test("天鳳適用後に打牌アシストを変えても selectedPreset は変わらない")
    func displaySettingDoesNotChangePreset() {
        let s = GameSettings()
        s.applyPreset(.tenhou)
        s.dapaiAssist = true
        #expect(s.selectedPreset == .tenhou)
    }
}

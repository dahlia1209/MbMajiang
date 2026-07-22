//
//  CpuStyleTests.swift
//  MbMajiangTests
//
//  CPUの5タイプ（副露攻撃型・副露守備型・門前攻撃型・門前守備型・ダマ型）の
//  軸（副露するか・押し引きするか・リーチ宣言するか）とそのゲーティング挙動のテスト。

import Testing
@testable import MbMajiang

@Suite("GameSettings.CpuStyle: 副露/攻守の軸")
struct CpuStyleAxesTests {

    @Test("副露攻撃型: 鳴く・押し引きしない")
    func fulouOffense() {
        #expect(GameSettings.CpuStyle.fulouOffense.doesFulou == true)
        #expect(GameSettings.CpuStyle.fulouOffense.playsDefense == false)
    }

    @Test("副露守備型: 鳴く・押し引きする")
    func fulouDefense() {
        #expect(GameSettings.CpuStyle.fulouDefense.doesFulou == true)
        #expect(GameSettings.CpuStyle.fulouDefense.playsDefense == true)
    }

    @Test("門前攻撃型: 鳴かない・押し引きしない")
    func menzenOffense() {
        #expect(GameSettings.CpuStyle.menzenOffense.doesFulou == false)
        #expect(GameSettings.CpuStyle.menzenOffense.playsDefense == false)
    }

    @Test("門前守備型: 鳴かない・押し引きする・リーチする")
    func menzenDefense() {
        #expect(GameSettings.CpuStyle.menzenDefense.doesFulou == false)
        #expect(GameSettings.CpuStyle.menzenDefense.playsDefense == true)
        #expect(GameSettings.CpuStyle.menzenDefense.declaresRiichi == true)
    }

    @Test("ダマ型: 鳴かない・押し引きする・リーチしない")
    func damaDefense() {
        #expect(GameSettings.CpuStyle.damaDefense.doesFulou == false)
        #expect(GameSettings.CpuStyle.damaDefense.playsDefense == true)
        #expect(GameSettings.CpuStyle.damaDefense.declaresRiichi == false)
    }

    @Test("ダマ型以外はすべてリーチする")
    func onlyDamaSkipsRiichi() {
        let nonDama: [GameSettings.CpuStyle] = [.fulouOffense, .fulouDefense, .menzenOffense, .menzenDefense]
        for style in nonDama {
            #expect(style.declaresRiichi == true)
        }
    }
}

@Suite("AIPlayer.onDapai: cpuStyleによる副露判断のON/OFF")
struct OnDapaiFulouStyleGatingTests {

    // 3面子(m123,p456,s789) + 塔子2(s12,s45) + 雀頭なし → 1シャンテン。s3のチーでシャンテンが縮む。
    private let baseHand = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","s1","s2","s4","s5"]

    private func makeStatus() -> GameStatus {
        var status = GameStatus()
        status.player = 3   // id=0から見て上家(3+1)%4=0 → チー可能
        status.dapai = "s3"
        status.paishu = 10
        return status
    }

    @Test("門前型は鳴く条件が揃っていてもチーしない")
    func menzenStyleNeverCalls() {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(baseHand))
        ai.cpuStyle = .menzenOffense
        ai.kuitanAri = true
        ai.onDapai(makeStatus())
        #expect(ai.status.decision != .chi)
    }

    @Test("副露型はシャンテンが縮むならチーする")
    func fulouStyleCallsWhenBeneficial() {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(baseHand))
        ai.cpuStyle = .fulouOffense
        ai.kuitanAri = true
        ai.onDapai(makeStatus())
        #expect(ai.status.decision == .chi)
    }
}

@Suite("AIPlayer.onZimo: cpuStyleによるリーチ宣言のON/OFF")
struct OnZimoRiichiStyleGatingTests {

    // 4面子+単騎（テンパイ） + ツモ牌z1（無関係な浮き牌、切ればテンパイ維持）
    private let tenpaiHand = ["m1","m2","m3","p4","p5","p6","s7","s8","s9","m4","m5","m6","m7"]

    private func makeStatus() -> GameStatus {
        var status = GameStatus()
        status.player = 0
        status.paishu = 10
        return status
    }

    @Test("ダマ型はテンパイでもリーチ宣言しない")
    func damaStyleNeverDeclares() {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(tenpaiHand, "z1"))
        ai.cpuStyle = .damaDefense
        ai.onZimo(makeStatus())
        #expect(ai.status.isSelectingRiichi == false)
    }

    @Test("門前守備型はテンパイならリーチ宣言する")
    func menzenDefenseDeclares() {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(tenpaiHand, "z1"))
        ai.cpuStyle = .menzenDefense
        ai.onZimo(makeStatus())
        #expect(ai.status.isSelectingRiichi == true)
    }
}

@Suite("AIPlayer.selectDapai: cpuStyleによる押し引き判断のON/OFF")
struct SelectDapaiStyleGatingTests {

    // 対子・搭子なしの14枚（何を切ってもシャンテン差が出にくい形）
    private let scatteredHand = ["m1","m4","m7","p1","p5","p8","s1","s4","s7","z1","z2","z3","z4","z5"]

    @Test("攻撃型(playsDefense=false)は押し引き判断(現物チェック)を行わない")
    func offenseStyleSkipsDefenseCheck() {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(scatteredHand))
        ai.cpuStyle = .fulouOffense
        var wasQueried = false
        ai.getRiichiGenbutsu = { wasQueried = true; return [["z1"]] }
        ai.selectDapai()
        #expect(wasQueried == false)
    }

    @Test("守備型(playsDefense=true)は押し引き判断(現物チェック)を行う")
    func defenseStyleRunsDefenseCheck() {
        let ai = AIPlayer(id: 0, shoupai: Shoupai(scatteredHand))
        ai.cpuStyle = .fulouDefense
        var wasQueried = false
        ai.getRiichiGenbutsu = { wasQueried = true; return [["z1"]] }
        ai.selectDapai()
        #expect(wasQueried == true)
    }
}

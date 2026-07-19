//
//  SelectBestCandidateTests.swift
//  MbMajiangTests
//
//  getYaku が複数の和了形分解から採用する組み合わせを選ぶロジックのテスト。
//  翻数が同点の場合、符が高い方を採用するのが正式なルール。

import Testing
@testable import MbMajiang

@Suite("Hule.selectBestCandidate: 分解候補の選択")
struct SelectBestCandidateTests {

    private func yaku(_ fanshu: Int) -> [Yaku] {
        [Yaku(name: "test", fanshu: fanshu)]
    }

    @Test("翻数が高い方を優先する")
    func prefersHigherFan() {
        let candidates: [(yaku: [Yaku], fu: Int)] = [
            (yaku: yaku(1), fu: 40),
            (yaku: yaku(2), fu: 30),
        ]
        let best = Hule.selectBestCandidate(candidates)
        #expect(best?.yaku.first?.fanshu == 2)
        #expect(best?.fu == 30)
    }

    @Test("翻数が同点なら符が高い方を採用する（本来のルール通りの同点処理）")
    func tieBreaksOnHigherFu() {
        let candidates: [(yaku: [Yaku], fu: Int)] = [
            (yaku: yaku(2), fu: 30),
            (yaku: yaku(2), fu: 40),
        ]
        let best = Hule.selectBestCandidate(candidates)
        #expect(best?.fu == 40)
    }

    @Test("翻数が同点・符も同点なら結果は変わらない")
    func tieOnBothFanAndFu() {
        let candidates: [(yaku: [Yaku], fu: Int)] = [
            (yaku: yaku(2), fu: 30),
            (yaku: yaku(2), fu: 30),
        ]
        let best = Hule.selectBestCandidate(candidates)
        #expect(best?.fu == 30)
        #expect(best?.yaku.first?.fanshu == 2)
    }

    @Test("候補の順序に関わらず、符の高い方が選ばれる（列挙順に依存しない）")
    func orderIndependent() {
        let ordered: [(yaku: [Yaku], fu: Int)] = [
            (yaku: yaku(3), fu: 40),
            (yaku: yaku(3), fu: 30),
        ]
        let reversed: [(yaku: [Yaku], fu: Int)] = [
            (yaku: yaku(3), fu: 30),
            (yaku: yaku(3), fu: 40),
        ]
        #expect(Hule.selectBestCandidate(ordered)?.fu == 40)
        #expect(Hule.selectBestCandidate(reversed)?.fu == 40)
    }

    @Test("候補が空なら nil")
    func emptyCandidates() {
        #expect(Hule.selectBestCandidate([]) == nil)
    }
}

//
//  BoardView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/03/30.
//

import SwiftUI

struct BoardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var game: Game
    /// Previewや開発時にボタンを強制表示するための上書きセット（本番では空のまま）
    private let debugActions: Set<PlayerButtonAction>
    private let autoStart: Bool
    /// デバッグ: 全プレイヤーの手牌を公開するトグル
    @State private var revealAll: Bool = false

    init(game: Game, debugActions: Set<PlayerButtonAction>, autoStart: Bool = true) {
        self._game = State(initialValue: game)
        self.debugActions = debugActions
        self.autoStart = autoStart
    }

    /// 実際に表示するボタン（gameのactionsが空の場合はdebugActionsを使用）
    private var displayedActions: Set<PlayerButtonAction> {
        game.playerActions.isEmpty ? debugActions : game.playerActions
    }

    private var isPingju: Bool {
        game.huleResult?.kind == .pingju
    }

    private func isTenpai(_ playerIdx: Int) -> Bool {
        let tiles = game.board.shan.shoupai[playerIdx].visibleLabels.map { Hule.normalize($0) }
        return Hule.xiangting(tiles) == 0
    }

    private var highlightedIndices: Set<Int>? {
        guard let human = game.humanPlayer else { return nil }
        if human.status.isSelectingChi {
            let candidates = human.status.chiCandidates
            let selected = human.status.selectedChi
            if selected.isEmpty {
                return Set(candidates.flatMap { $0 })
            } else {
                return Set(candidates.filter { $0.contains(selected[0]) }.flatMap { $0 })
                    .subtracting([selected[0]])
            }
        } else if human.status.isSelectingAngang {
            let gangziLabels = Set(human.shoupai.gangzi)
            return Set(human.shoupai.allLabels.indices.filter { gangziLabels.contains(human.shoupai.allLabels[$0]) })
        } else if human.status.isSelectingKagang {
            let gangziLabels = Set(human.shoupai.kagangzi)
            return Set(human.shoupai.allLabels.indices.filter { gangziLabels.contains(human.shoupai.allLabels[$0]) })
        } else if human.status.isSelectingRiichi {
            return Set(human.status.lizhiCandidateIndices)
        }
        
        return nil
    }

    private func lastDapaiIndex(for playerIdx: Int) -> Int? {
        guard let last = game.status.lastDapai, last.player == playerIdx else { return nil }
        return last.index
    }

    private var onTapPaiHandler: ((Int) -> Void)? {
        if game.isSelectingChi {
            return { self.game.humanPlayer?.selectChi($0) }
        }else if game.isSelectingAngang {
            return { self.game.humanPlayer?.selectAngang($0) }
        }else if game.isSelectingKagang {
            return { self.game.humanPlayer?.selectKagang($0) }
        }else if game.isSelectingDapai {
            return { self.game.humanPlayer?.selectDapai($0) }
        }

        return nil
    }
    
    

    var body: some View {
        ZStack {
            BackgroundLayer()

            VStack {
                Spacer()
                ScoreBoardView(game.board.score, game.board.shan.wangpai, game.board.shan.paishu,
                               lizhiPlayers: game.players.map { $0.status.isLizhi })
                Spacer()
            }
            .padding(.horizontal, 40)

            HeView(he: game.board.shan.he[0], highlightedIndex: lastDapaiIndex(for: 0))
                .scaleEffect(0.8)
                .offset(y: 100)
            HeView(he: game.board.shan.he[1], highlightedIndex: lastDapaiIndex(for: 1))
                .scaleEffect(0.8)
                .offset(y: 170)
                .rotationEffect(.degrees(270))
            HeView(he: game.board.shan.he[2], highlightedIndex: lastDapaiIndex(for: 2))
                .scaleEffect(0.8)
                .offset(y: 100)
                .rotationEffect(.degrees(180))
            HeView(he: game.board.shan.he[3], highlightedIndex: lastDapaiIndex(for: 3))
                .scaleEffect(0.8)
                .offset(y: 170)
                .rotationEffect(.degrees(90))

            ShoupaiView(
                shoupai: game.board.shan.shoupai[0],
                onTapPai: onTapPaiHandler,
                highlightedIndices: highlightedIndices,
                selectedIndices: Set(game.humanPlayer?.status.selectedChi ?? [])
            )
            .offset(y: 180)

            ShoupaiView(shoupai: game.board.shan.shoupai[1], isTajia: !revealAll && !(isPingju && isTenpai(1)))
                .offset(y: 260)
                .rotationEffect(.degrees(270))
            ShoupaiView(shoupai: game.board.shan.shoupai[2], isTajia: !revealAll && !(isPingju && isTenpai(2)))
                .offset(y: 160)
                .rotationEffect(.degrees(180))
            ShoupaiView(shoupai: game.board.shan.shoupai[3], isTajia: !revealAll && !(isPingju && isTenpai(3)))
                .offset(y: 250)
                .rotationEffect(.degrees(90))

            // プレイヤーアクションボタン
            if !displayedActions.isEmpty {
                VStack(spacing: 4) {
                    if let message = game.infoMessage {
                        Text(message)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(6)
                    }
                    PlayerButtonView(visibleActions: displayedActions) { action in
                        game.handlePlayerAction(action)
                    }
                }
                .scaleEffect(0.7)
                .offset(y: 140)
            }

            // デバッグボタン（右上）
            VStack {
                HStack {
                    Spacer()
                    Button {
                        revealAll.toggle()
                    } label: {
                        Image(systemName: revealAll ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(revealAll ? .yellow : .white.opacity(0.5))
                            .padding(10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 12)
                }
                Spacer()
            }
        }
        // 和了・流局ダイアログ
        .overlay {
            if let result = game.huleResult {
                RoundResultView(result: result) {
                    game.dismissHuleResult()
                }
            }
        }
        // 終局サマリー
        .overlay {
            if let summary = game.gameResult {
                GameResultView(result: summary) {
                    dismiss()
                }
            }
        }
        .onAppear {
            setupGame()
        }
    }

    // MARK: - ゲーム進行
    // ゲームロジックはGame.advance()/processPlayerActions()が担うため、startを呼ぶだけ
    func setupGame() {
        guard autoStart else { return }
        game.start()
    }
}

#Preview("通常", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [])
}

#Preview("槓子", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [0: ["m1","m1","m1","m1","p5","p5","p5","p5","z1","z1","z1","z1","z5"]]
    game.board.shan.shoupai[0].zimo = Pai("z5")
    game.status.zimo = "z5"
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("七対子ツモ和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    // 七対子: m1×2, m3×2, p5×2, s7×2, z1×2, z3×2, z5×2
    let bingpai = ["m1","m1","m3","m3","p5","p5","s7","s7","z1","z1","z3","z3","z5"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.board.shan.shoupai[0].zimo = Pai("z5")
    game.status.zimo = "z5"
    game.hule(player: 0, kind: .zimo)
    return BoardView(game: game, debugActions: [], autoStart: false)
}


#Preview("七対子混老頭ツモ和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    // 七対子: m1×2, m3×2, p5×2, s7×2, z1×2, z3×2, z5×2
    let bingpai = ["m1","m1","m9","m9","p1","p1","s9","s9","z1","z1","z3","z3","z5"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.status.player = 1   // 放銃者
    game.status.dapai = "z5"
    game.hule(player: 0, kind: .rong)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("四暗刻ツモ和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    let bingpai = ["m1","m1","m1","m9","m9","m9","s9","s9","s9","z1","z1","z3","z3"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.board.shan.shoupai[0].zimo = Pai("z3")
    game.status.zimo = "z3"
    game.hule(player: 0, kind: .zimo)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("国士無双13面", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    let bingpai = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.board.shan.shoupai[0].zimo = Pai("z5")
    game.status.zimo = "z1"
    game.hule(player: 0, kind: .zimo)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("トイトイ三暗刻ロン和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    // 一気通貫: m1-2-3, m4-5-6, m7-8-9(ロン), p3×3, s7×2
    let bingpai = ["m1","m1","m1","m9","m9","m9","s9","s9","s9","z1","z1","z3","z3"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.status.player = 1   // 放銃者
    game.status.dapai = "z3"
    game.hule(player: 0, kind: .rong)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("一気通貫ロン和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    // 一気通貫: m1-2-3, m4-5-6, m7-8-9(ロン), p3×3, s7×2
    let bingpai = ["m1","m2","m3","m4","m5","m6","m7","m8","p3","p3","p3","s7","s7"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.status.player = 1   // 放銃者
    game.status.dapai = "m9"
    game.hule(player: 0, kind: .rong)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("副露ありロン和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    // 白ポン + 断么九: 手牌 m2-3-4, p5-6-7, s3-4-5, s7×2(対) + z5×3(ポン副露)
    let bingpai = ["m2","m3","m4","p5","p6","p7","s3","s4","s5","s7"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    var nakiPai=Pai("z5");nakiPai.rotated=true
    game.board.shan.shoupai[0].fulou = [[nakiPai, Pai("z5"), Pai("z5")]]
    game.players[0].status.isMenqian = false
    game.status.player = 2   // 放銃者
    game.status.dapai = "s7"
    game.hule(player: 0, kind: .rong)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("副露ありタンヤオ和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    let bingpai = ["p5","p6","p7","s3","s4","s5","s2","s2","s7","s8",]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    var nakiPai=Pai("p2");nakiPai.rotated=true
    game.board.shan.shoupai[0].fulou = [[nakiPai, Pai("p3"), Pai("p4")]]
    game.players[0].status.isMenqian = false
    game.status.player = 2   // 放銃者
    game.status.dapai = "s6"
    game.hule(player: 0, kind: .rong)
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("聴牌", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m2","m3","p5","p6","p7","s3","s4","s5","s6","s7","z3","z3"],  // テンパイ z1/z3
        1: ["m4","m6","m8","p1","p3","p5","s7","s8","s9","z2","z2","z5","z5"],
        2: ["m7","p4","p8","s2","s4","s6","z4","z6","z7","m2","p2","s1","m9"],
        3: ["m1","m3","m5","p6","p7","p9","s1","s3","s5","z7","z7","p9","p9"],
    ]
    
    return BoardView(game: game, debugActions: [], autoStart: false)
}


#Preview("流局", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m2","m3","p5","p6","p7","s3","s4","s5","z1","z1","z3","z3"],  // テンパイ z1/z3
        1: ["m4","m5","m6","p1","p2","p3","s7","s8","s9","z2","z2","z5","z5"],  // テンパイ z2/z5
        2: ["m7","p4","p8","s2","s4","s6","z4","z6","z7","m2","p2","s1","m9"],  // ノーテン
        3: ["m1","m2","m3","p6","p7","p8","s1","s2","s3","z7","z7","p9","p9"],  // テンパイ z7/p9
    ]
    game.board.score.honba = 1
    game.board.score.lizhibang = 2
    game.pingju()
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("対局終了", traits: .landscapeLeft) {
    let history: [RoundRecord] = [
        RoundRecord(jushu: .東一局, honba: 0, kind: .rong,   hulePlayer: 2, dealerPlayer: 0, scoreChanges: [0,     0, +2000,  -2000], lizhiPlayers: []),
        RoundRecord(jushu: .東一局, honba: 1, kind: .rong,   hulePlayer: 2, dealerPlayer: 0, scoreChanges: [-3200, 0, +3200,  0    ], lizhiPlayers: []),
        RoundRecord(jushu: .東一局, honba: 2, kind: .rong,   hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8300, 0, 0,     +10300], lizhiPlayers: [0, 3]),
        RoundRecord(jushu: .東二局, honba: 0, kind: .rong,   hulePlayer: 1, dealerPlayer: 1, scoreChanges: [0,  +2300, -1300, 0    ], lizhiPlayers: [0]),
        RoundRecord(jushu: .東三局, honba: 0, kind: .rong,   hulePlayer: 3, dealerPlayer: 2, scoreChanges: [-7700, 0, 0,    +8700 ], lizhiPlayers: [2]),
        RoundRecord(jushu: .東四局, honba: 0, kind: .rong,   hulePlayer: 2, dealerPlayer: 3, scoreChanges: [-2600, 0, +3600, 0    ], lizhiPlayers: [2]),
        RoundRecord(jushu: .南一局, honba: 0, kind: .pingju, hulePlayer: nil, dealerPlayer: 0, scoreChanges: [0, 0, 0, 0],           lizhiPlayers: []),
        RoundRecord(jushu: .南一局, honba: 1, kind: .zimo,   hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8000, 0, 0,    +8000 ], lizhiPlayers: []),
        RoundRecord(jushu: .南一局, honba: 1, kind: .zimo,   hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8000, 0, 0,    +8000 ], lizhiPlayers: []),
    ]
    let game = Game()
    game.gameResult = SummaryResult(
        roundHistory: history,
        finalScores: [
            (feng: .西, points: -6800),
            (feng: .北, points: 27300),
            (feng: .東, points: 30500),
            (feng: .南, points: 49000),
        ],
        finalPoints: [-56.8, -12.7, 10.5, 59.0]
    )
    return BoardView(game: game, debugActions: [])
}

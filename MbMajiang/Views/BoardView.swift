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
    /// デバッグ: 全プレイヤーの手牌を公開するトグル
    @State private var revealAll: Bool = false

    init(game: Game, debugActions: Set<PlayerButtonAction> ) {
        self._game = State(initialValue: game)
        self.debugActions = debugActions
    }

    /// 実際に表示するボタン（gameのactionsが空の場合はdebugActionsを使用）
    private var displayedActions: Set<PlayerButtonAction> {
        game.playerActions.isEmpty ? debugActions : game.playerActions
    }

    /// チー選択中にハイライトするインデックス
    /// 1枚目未選択: chiCandidatesに含まれる全インデックス
    /// 1枚目選択済み: 同じペアの残り1枚
    private var chiHighlightedIndices: Set<Int>? {
        guard let human = game.humanPlayer, human.status.isSelectingChi else { return nil }
        let candidates = human.status.chiCandidates
        let selected = human.status.selectedChi
        if selected.isEmpty {
            return Set(candidates.flatMap { $0 })
        } else {
            return Set(candidates.filter { $0.contains(selected[0]) }.flatMap { $0 })
                .subtracting([selected[0]])
        }
    }

    var body: some View {
        ZStack {
            BackgroundLayer()

            VStack {
                Spacer()
                ScoreBoardView(game.board.score, game.board.shan.wangpai, game.board.shan.shan.count)
                Spacer()
            }
            .padding(.horizontal, 40)

            HeView(he: game.board.shan.he[0])
                .scaleEffect(0.8)
                .offset(y: 100)
            HeView(he: game.board.shan.he[1])
                .scaleEffect(0.8)
                .offset(y: 170)
                .rotationEffect(.degrees(270))
            HeView(he: game.board.shan.he[2])
                .scaleEffect(0.8)
                .offset(y: 100)
                .rotationEffect(.degrees(180))
            HeView(he: game.board.shan.he[3])
                .scaleEffect(0.8)
                .offset(y: 170)
                .rotationEffect(.degrees(90))

            ShoupaiView(
                shoupai: game.board.shan.shoupai[0],
                onTapPai: game.canDapai ? { game.humanPlayer?.selectDapai($0) }
                        : (game.humanPlayer?.status.isSelectingChi == true) ? { game.humanPlayer?.selectChi($0) }
                        : nil,
                highlightedIndices: game.humanPlayer?.status.isSelectingRiichi == true
                    ? game.humanPlayer?.status.lizhiCandidateIndices
                    : chiHighlightedIndices,
                selectedIndices: Set(game.humanPlayer?.status.selectedChi ?? [])
            )
            .offset(y: 180)

            ShoupaiView(shoupai: game.board.shan.shoupai[1], isTajia: !revealAll)
                .offset(y: 260)
                .rotationEffect(.degrees(270))
            ShoupaiView(shoupai: game.board.shan.shoupai[2], isTajia: !revealAll)
                .offset(y: 160)
                .rotationEffect(.degrees(180))
            ShoupaiView(shoupai: game.board.shan.shoupai[3], isTajia: !revealAll)
                .offset(y: 250)
                .rotationEffect(.degrees(90))

            // プレイヤーアクションボタン
            if !displayedActions.isEmpty {
                PlayerButtonView(visibleActions: displayedActions) { action in
                    game.handlePlayerAction(action)
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
                HuleDialogView(result: result) {
                    game.dismissHuleResult()
                }
            }
        }
        // 終局サマリー
        .overlay {
            if let summary = game.summaryResult {
                SummaryView(result: summary) {
                    game.summaryResult = nil
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
        game.start()
    }
}

#Preview("通常", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [])
}

#Preview("ツモ和了ボタン", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [.cancel, .zimo])
}

#Preview("リーチボタン", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [.cancel, .lizhi])
}

#Preview("ロン・チー・ポンボタン", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [.cancel, .chi, .peng, .rong])
}

#Preview("全ボタン", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [.cancel, .noten, .chi, .peng, .gang, .lizhi, .rong, .zimo, .pingju])
}

#Preview("終局サマリー", traits: .landscapeLeft) {
    let history: [RoundRecord] = [
        RoundRecord(jushu: .東一局, honba: 0, kind: .rong,   hulePlayer: 2, dealerPlayer: 0, scoreChanges: [0,     0, +2000,  -2000], lizhiPlayers: []),
        RoundRecord(jushu: .東一局, honba: 1, kind: .rong,   hulePlayer: 2, dealerPlayer: 0, scoreChanges: [-3200, 0, +3200,  0    ], lizhiPlayers: []),
        RoundRecord(jushu: .東一局, honba: 2, kind: .rong,   hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8300, 0, 0,     +10300], lizhiPlayers: [0, 3]),
        RoundRecord(jushu: .東二局, honba: 0, kind: .rong,   hulePlayer: 1, dealerPlayer: 1, scoreChanges: [0,  +2300, -1300, 0    ], lizhiPlayers: [0]),
        RoundRecord(jushu: .東三局, honba: 0, kind: .rong,   hulePlayer: 3, dealerPlayer: 2, scoreChanges: [-7700, 0, 0,    +8700 ], lizhiPlayers: [2]),
        RoundRecord(jushu: .東四局, honba: 0, kind: .rong,   hulePlayer: 2, dealerPlayer: 3, scoreChanges: [-2600, 0, +3600, 0    ], lizhiPlayers: [2]),
        RoundRecord(jushu: .南一局, honba: 0, kind: .pingju, hulePlayer: nil, dealerPlayer: 0, scoreChanges: [0, 0, 0, 0],           lizhiPlayers: []),
        RoundRecord(jushu: .南一局, honba: 1, kind: .zimo,   hulePlayer: 3, dealerPlayer: 0, scoreChanges: [-8000, 0, 0,    +8000 ], lizhiPlayers: []),
    ]
    let game = Game()
    game.summaryResult = SummaryResult(
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

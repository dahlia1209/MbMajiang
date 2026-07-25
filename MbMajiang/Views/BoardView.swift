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
    @State private var showQuitAlert = false
    @State private var isBGMMuted = false
    @State private var hasStarted: Bool
    @State private var showCustomDetails = false

    init(game: Game, debugActions: Set<PlayerButtonAction>, autoStart: Bool = true, showStartButton: Bool = false) {
        self._game = State(initialValue: game)
        self.debugActions = debugActions
        self.autoStart = autoStart
        self._hasStarted = State(initialValue: !showStartButton)
    }

    /// 実際に表示するボタン（gameのactionsが空の場合はdebugActionsを使用）
    private var displayedActions: Set<PlayerButtonAction> {
        game.playerActions.isEmpty ? debugActions : game.playerActions
    }

    private var isPingju: Bool {
        game.huleResult?.kind == .pingju
    }

    private func isTenpai(_ playerIdx: Int) -> Bool {
        let tiles = game.board.shan.shoupai[playerIdx].visibleLabels.map { Pai.normalize($0) }
        return Hule.xiangting(tiles) == 0
    }

    private func lastDapaiIndex(for playerIdx: Int) -> Int? {
        guard let last = game.status.lastDapai, last.player == playerIdx else { return nil }
        return last.index
    }



    var body: some View {
        ZStack {
            BackgroundLayer(imageName: game.settings.boardTheme.imageName)

            VStack {
                Spacer()
                ScoreBoardView(game.board.score, hasStarted ? game.board.shan.wangpai : Wangpai(), game.board.shan.paishu,
                               lizhiPlayers: game.players.map { $0.status.isLizhi })
                Spacer()
            }
            .padding(.horizontal, 40)

            HeView(he: game.board.shan.he[0], highlightedIndex: lastDapaiIndex(for: 0))
                .offset(y: 100)
            HeView(he: game.board.shan.he[1], highlightedIndex: lastDapaiIndex(for: 1))
                .offset(y: 200)
                .rotationEffect(.degrees(270))
            HeView(he: game.board.shan.he[2], highlightedIndex: lastDapaiIndex(for: 2))
                .offset(y: 100)
                .rotationEffect(.degrees(180))
            HeView(he: game.board.shan.he[3], highlightedIndex: lastDapaiIndex(for: 3))
                .offset(y: 200)
                .rotationEffect(.degrees(90))

            PlayerHandSection(game: game, hasStarted: hasStarted)

            ShoupaiView(shoupai: game.board.shan.shoupai[1], isTajia: !revealAll && !(isPingju && isTenpai(1)),
                        baopai: game.board.shan.wangpai.baopai.map { $0.normalized })
                .offset(y: 300)
                .rotationEffect(.degrees(270))
            ShoupaiView(shoupai: game.board.shan.shoupai[2], isTajia: !revealAll && !(isPingju && isTenpai(2)),
                        baopai: game.board.shan.wangpai.baopai.map { $0.normalized })
                .offset(y: 160)
                .rotationEffect(.degrees(180))
            ShoupaiView(shoupai: game.board.shan.shoupai[3], isTajia: !revealAll && !(isPingju && isTenpai(3)),
                        baopai: game.board.shan.wangpai.baopai.map { $0.normalized })
                .offset(y: 290)
                .rotationEffect(.degrees(90))

            // 打牌カウントダウン（一打10秒モードは一打の残り時間、持ち時間モードは持ち時間。持ち時間を使い切った後は秒読み中の一打を表示）
            if game.isTurnTimerActive {
                let total = max(0, Int(ceil(game.totalTimeRemaining)))
                let turn = max(0, Int(ceil(game.turnTimeRemaining)))
                let hasBank = game.settings.totalTimeBank > 0
                let label = (hasBank && total > 0) ? "\(total)" : "\(turn)"
                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .offset(x:230,y: 100)
            }

            // プレイヤーアクションボタン
            if !displayedActions.isEmpty {
                PlayerButtonView(visibleActions: displayedActions) { action in
                    game.handlePlayerAction(action)
                }
                .scaleEffect(0.7)
                .offset(y: 120)
            }
            
            // 待ち牌エリア（打牌アシスト有効時のみ）
            if game.settings.agariHaiDisplay && !game.machiTiles.isEmpty {
                VStack(spacing: 4) {
                    if !game.machiFuritenSet.isEmpty {
                        Text("フリテン")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    HStack(spacing: 4) {
                        ForEach(game.machiTiles, id: \.self) { tile in
                            let hasYaku = game.machiYakuSet.contains(tile)
                            VStack(spacing: 2) {
                                PaiView(tile)
                                Text(hasYaku ? "役有" : "役無")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(hasYaku ? .yellow : .white.opacity(0.4))
                            }
                        }
                    }
                }
                .scaleEffect(1.4)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .cornerRadius(10)
                .offset(y: 110)
            }

            // infoMessage（フリテン・クイカエ等）
            if let message = game.infoMessage {
                Text(message)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(6)
                    .offset(y: 100)
            }

            // 終了・BGMボタン（左上）
            HStack {
                VStack(spacing: 8) {
                    Button {
                        showQuitAlert = true
                    } label: {
                        Text("×")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button {
                        isBGMMuted.toggle()
                        SoundManager.shared.setBGMMuted(isBGMMuted)
                    } label: {
                        Image(systemName: isBGMMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isBGMMuted ? .white.opacity(0.7) : .yellow)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button {
                        game.isFulouSkipEnabled.toggle()
                    } label: {
                        ZStack {
                            Text("鳴")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(game.isFulouSkipEnabled ? .white.opacity(0.7) : .yellow)
                            if game.isFulouSkipEnabled {
                                Rectangle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 5, height: 24)
                                    .rotationEffect(.degrees(-45))
                                Rectangle()
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 1.5, height: 24)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.top, 12)
                Spacer()
            }

            // 対局前ルールパネル（自分の手牌の少し上、開始前のみ表示）
            if !hasStarted {
                preStartPanel
                    .offset(y: 0)
            }

            // 手牌表示トグル（設定で有効時のみ表示）
            if game.settings.showHandDisplayOption {
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
        }
        .environment(\.tileTheme, game.settings.tileTheme)
        .onTapGesture {
            game.pendingDapaiIndex = nil
            game.machiTiles = []
            game.machiYakuSet = []
            game.machiFuritenSet = []
        }
        // アクションバナー（ポンなど、ゲームを止めない）
        .overlay {
            if let imageName = game.actionBannerImage {
                ActionBannerView(imageName: imageName)
                    .id(imageName)
                    .rotationEffect(bannerRotation(for: game.actionBannerPlayer))
                    .offset(bannerOffset(for: game.actionBannerPlayer))
                    .allowsHitTesting(false)
            }
        }
        // リーチカットイン
        .overlay {
            if game.lizhiCutInPlayer != nil {
                LizhiCutInView {
                    game.dismissLizhiCutIn()
                }
            }
        }
        // 局開始カットイン
        .overlay {
            if !game.roundCutInRoundNames.isEmpty {
                RoundCutInView(
                    roundImageNames: game.roundCutInRoundNames,
                    honbaImageNames: game.roundCutInHonbaNames
                ) {
                    game.dismissRoundCutIn()
                }
                .allowsHitTesting(false)
            }
        }
        // ツモ・ロンカットイン
        .overlay {
            if let player = game.huleCutInPlayer, let imageName = game.huleCutInImageName {
                HuleCutInView(imageName: imageName) {
                    game.dismissHuleCutIn()
                }
                .rotationEffect(bannerRotation(for: player))
                .offset(bannerOffset(for: player))
                .allowsHitTesting(false)
            }
        }
        // 流局カットイン
        .overlay {
            if game.pingjuCutInActive {
                PingjuCutInView {
                    game.dismissPingjuCutIn()
                }
            }
        }
        // テンパイカットイン（流局後、プレイヤーごとに順番に表示）
        .overlay {
            if let player = game.tenpaiCutInCurrentPlayer {
                TenpaiCutInView {
                    game.dismissTenpaiCutIn()
                }
                .rotationEffect(bannerRotation(for: player))
                .offset(bannerOffset(for: player))
                .id(player)
            }
        }
        // 和了・流局ダイアログ（カットイン終了後に表示）
        .overlay {
            if let result = game.huleResult,
               game.huleCutInPlayer == nil,
               !game.pingjuCutInActive,
               game.tenpaiCutInCurrentPlayer == nil {
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
        .onChange(of: game.isSelectingDapai) { _, isSelecting in
            if !isSelecting {
                game.machiTiles = []
                game.machiYakuSet = []
                game.machiFuritenSet = []
                game.pendingDapaiIndex = nil
            }
        }
        .onChange(of: game.huleCutInPlayer) { _, player in
            if player != nil { SoundManager.shared.stopBGM() }
        }
        .onChange(of: game.pingjuCutInActive) { _, active in
            if active { SoundManager.shared.stopBGM() }
        }
        .onChange(of: game.roundCutInRoundNames) { _, names in
            if !names.isEmpty { SoundManager.shared.playBGM(game.board.score.round.bgmName) }
        }
        .alert("対局を終了しますか？", isPresented: $showQuitAlert) {
            Button("終了", role: .destructive) { dismiss() }
            Button("キャンセル", role: .cancel) {}
        }
        .onAppear {
            setupGame()
            if hasStarted {
                SoundManager.shared.playBGM(game.board.score.round.bgmName)
            }
        }
        .onDisappear {
            SoundManager.shared.stopBGM()
            game.stopTurnTimer()
        }
    }

    // MARK: - バナー位置
    private func bannerOffset(for player: Int?) -> CGSize {
        switch player {
        case 0:  return CGSize(width:    0, height:  80)  // 自分（下）
        case 1:  return CGSize(width:  220, height:   0)  // 下家（右）
        case 2:  return CGSize(width:    0, height: -80)  // 対面（上）
        case 3:  return CGSize(width: -220, height:   0)  // 上家（左）
        default: return .zero
        }
    }

    private func bannerRotation(for player: Int?) -> Angle {
        switch player {
        case 1:  return .degrees(-90)
        case 2:  return .degrees(180)
        case 3:  return .degrees(90)
        default: return .zero
        }
    }

    // MARK: - 対局前ルールパネル

    private var goldColor: Color { Color(red: 0.82, green: 0.68, blue: 0.25) }
    private var goldLightColor: Color { Color(red: 0.97, green: 0.93, blue: 0.83) }

    private var preStartPanel: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 12) {
                Text("対局ルール")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(goldColor)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.9), radius: 2)

                HStack(spacing: 8) {
                    Text("局数")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(goldLightColor.opacity(0.85))
                        .shadow(color: .black.opacity(0.9), radius: 2)
                    Spacer()
                    Picker("局数", selection: Bindable(game.settings).kyokuCount) {
                        ForEach(GameSettings.KyokuCount.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                .frame(width: 260)

                cpuStyleUnifiedRow

                assistToggleRow

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showCustomDetails.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(showCustomDetails ? "詳細設定を閉じる" : "詳細設定を開く")
                        Image(systemName: showCustomDetails ? "chevron.left" : "chevron.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(goldColor.opacity(0.85))
                }

                Button {
                    startGame()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(goldColor.opacity(0.25))
                            .blur(radius: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                LinearGradient(colors: [goldLightColor, goldColor],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.4)))
                        Text("対局開始  ▶")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(colors: [goldLightColor, goldColor],
                                               startPoint: .leading, endPoint: .trailing))
                            .tracking(4)
                    }
                    .frame(width: 200, height: 46)
                    .contentShape(Rectangle())
                }
            }
            .frame(width: 260)

            if showCustomDetails {
                Rectangle()
                    .fill(goldColor.opacity(0.25))
                    .frame(width: 1, height: 300)

                ScrollView {
                    DetailSettingsSection(settings: game.settings)
                        .padding(.vertical, 4)
                }
                .frame(width: 300, height: 300)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(goldColor.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var assistToggleRow: some View {
        HStack(spacing: 8) {
            Text("アシスト機能")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(goldLightColor.opacity(0.85))
                .shadow(color: .black.opacity(0.9), radius: 2)
            Spacer()
            Toggle("", isOn: Binding(
                get: { game.settings.dapaiAssist },
                set: { newValue in
                    game.settings.dapaiAssist = newValue
                    game.settings.agariHaiDisplay = newValue
                    game.settings.fulouAssist = newValue
                }
            ))
            .labelsHidden()
            .tint(goldColor)
        }
        .frame(width: 260)
    }

    private var cpuStyleUnifiedRow: some View {
        HStack(spacing: 8) {
            Text("CPUの強さ")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(goldLightColor.opacity(0.85))
                .shadow(color: .black.opacity(0.9), radius: 2)
            Spacer()
            Picker("", selection: Binding(
                get: { game.settings.cpuStyles.first ?? .fulouOffense },
                set: { newValue in
                    for i in game.settings.cpuStyles.indices {
                        game.settings.cpuStyles[i] = newValue
                    }
                }
            )) {
                ForEach(GameSettings.CpuStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLightColor)
            .lineLimit(1)
            .fixedSize()
        }
        .frame(width: 260)
    }

    // MARK: - ゲーム進行
    // ゲームロジックはGame.advance()/processPlayerActions()が担うため、startを呼ぶだけ
    func setupGame() {
        guard autoStart else { return }
        game.start()
        hasStarted = true
    }

    // 対局開始ボタン（手動開始）。ルールパネルで変更された設定を反映するため、この時点で配牌をやり直す
    private func startGame() {
        game.settings.save()
        game = Game(settings: game.settings)
        game.start()
        hasStarted = true
        SoundManager.shared.playBGM(game.board.score.round.bgmName)
    }
}

// MARK: - PlayerHandSection
/// プレイヤー0の手牌エリア。game.pendingDapaiIndexをここに閉じ込めることで、
/// タップのたびにBoardView全体が再描画されるのを防ぐ。
private struct PlayerHandSection: View {
    var game: Game
    var hasStarted: Bool
    @State private var cachedXiantingInfo: (count: Int, indices: Set<Int>) = (99, [])

    private static let allTileLabels: [String] =
        (1...9).flatMap { n in ["m\(n)", "p\(n)", "s\(n)"] } + (1...7).map { "z\($0)" }

    private func computeMachiForDiscard(at index: Int) -> (tiles: [String], yakuSet: Set<String>, furitenSet: Set<String>) {
        guard game.settings.agariHaiDisplay else { return ([], [], []) }
        guard let human = game.humanPlayer else { return ([], [], []) }
        let tiles = human.shoupai.normalizedAllLabels
        guard tiles.indices.contains(index) else { return ([], [], []) }
        let hand = tiles.indices.filter { $0 != index }.map { tiles[$0] }
        guard Hule.xiangting(hand) == 0 else { return ([], [], []) }
        let he = game.board.shan.he[0]
        let riverLabels = Set((he.qipai + he.calledPai).map { Pai.normalize($0.label) })
        let selectedLabel = Pai.normalize(tiles[index])
        let furitenCheckLabels = riverLabels.union([selectedLabel])
        var machiSet = Set<String>()
        var yakuSet = Set<String>()
        for tile in Self.allTileLabels {
            let hand14 = (hand + [tile]).sorted()
            if !Hule.winningDecompositions(hand14).isEmpty {
                machiSet.insert(tile)
                if game.checkMachiHasYaku(hand13: hand, winTile: tile) {
                    yakuSet.insert(tile)
                }
            }
        }
        let furitenSet = machiSet.intersection(furitenCheckLabels)
        return (tiles: Self.allTileLabels.filter { machiSet.contains($0) }, yakuSet: yakuSet, furitenSet: furitenSet)
    }

    private var highlightedIndices: Set<Int>? {
        guard let human = game.humanPlayer else { return nil }
        if human.status.isSelectingChi {
            let candidates = human.status.chiCandidates
            let selected = human.status.selectedChiIndices
            if selected.isEmpty {
                return Set(candidates.flatMap { $0 })
            } else {
                return Set(candidates.filter { $0.contains(selected[0]) }.flatMap { $0 })
                    .subtracting([selected[0]])
            }
        } else if human.status.isSelectingPeng {
            let candidates = human.status.pengCandidates
            let selected = human.status.selectedPengIndices
            if selected.isEmpty {
                return Set(candidates.flatMap { $0 })
            } else {
                return Set(candidates.filter { $0.contains(selected[0]) }.flatMap { $0 })
                    .subtracting([selected[0]])
            }
        } else if human.status.isSelectingAngang {
            let gangziLabels = human.status.validAngangLabels
            let normalized = human.shoupai.normalizedAllLabels
            return Set(normalized.indices.filter { gangziLabels.contains(normalized[$0]) })
        } else if human.status.isSelectingKagang {
            let gangziLabels = Set(human.shoupai.kagangzi)
            let normalized = human.shoupai.normalizedAllLabels
            return Set(normalized.indices.filter { gangziLabels.contains(normalized[$0]) })
        } else if human.status.isSelectingRiichi {
            return Set(human.status.lizhiCandidateIndices)
        }

        // ポン・チー・明カンボタン表示中の候補ハイライト（副露アシストが有効な場合のみ）
        guard game.settings.fulouAssist else { return nil }
        var indices = Set<Int>()
        let actions = human.status.availableButtonActions
        if (actions.contains(.peng) || actions.contains(.minggang)),
           let dapai = game.status.dapai {
            indices.formUnion(human.shoupai.getPengCandidate(dapai))
        }
        if actions.contains(.chi) {
            indices.formUnion(human.status.chiCandidates.flatMap { $0 })
        }
        return indices.isEmpty ? nil : indices
    }

    private var onTapPaiHandler: ((Int) -> Void)? {
        if game.isSelectingChi {
            return { game.humanPlayer?.selectChi($0) }
        } else if game.isSelectingPeng {
            return { game.humanPlayer?.selectPeng($0) }
        } else if game.isSelectingAngang {
            return { game.humanPlayer?.selectAngang($0) }
        } else if game.isSelectingKagang {
            return { game.humanPlayer?.selectKagang($0) }
        } else if game.isSelectingDapai {
            if game.humanPlayer?.status.isLizhi == true {
                // リーチ中ツモ切り: ツモ牌のみ2タップ方式
                return { index in
                    guard index == game.humanPlayer?.shoupai.bingpai.count else { return }
                    if game.pendingDapaiIndex == index {
                        game.humanPlayer?.selectDapai(index)
                        game.pendingDapaiIndex = nil
                        game.machiTiles = []
                        game.machiYakuSet = []
                        game.machiFuritenSet = []
                    } else {
                        game.pendingDapaiIndex = index
                        let result = computeMachiForDiscard(at: index)
                        game.machiTiles = result.tiles
                        game.machiYakuSet = result.yakuSet
                        game.machiFuritenSet = result.furitenSet
                    }
                }
            } else if game.humanPlayer?.status.isSelectingRiichi == true {
                // リーチ打牌選択: 2タップ方式（リーチ自体が役なので全待ち牌は役あり）
                return { index in
                    if game.pendingDapaiIndex == index {
                        game.humanPlayer?.selectDapai(index)
                        game.pendingDapaiIndex = nil
                        game.machiTiles = []
                        game.machiYakuSet = []
                        game.machiFuritenSet = []
                    } else {
                        game.pendingDapaiIndex = index
                        let result = computeMachiForDiscard(at: index)
                        game.machiTiles = result.tiles
                        game.machiYakuSet = Set(result.tiles)
                        game.machiFuritenSet = result.furitenSet
                    }
                }
            } else {
                return { index in
                    if let human = game.humanPlayer,
                       !human.status.forbiddenDapaiLabels.isEmpty,
                       human.shoupai.normalizedAllLabels.indices.contains(index),
                       human.status.forbiddenDapaiLabels.contains(human.shoupai.normalizedAllLabels[index]) {
                        game.infoMessage = "クイカエ"
                        return
                    }
                    if game.pendingDapaiIndex == index {
                        game.humanPlayer?.selectDapai(index)
                        game.pendingDapaiIndex = nil
                        game.machiTiles = []
                        game.machiYakuSet = []
                        game.machiFuritenSet = []
                    } else {
                        game.pendingDapaiIndex = index
                        let result = computeMachiForDiscard(at: index)
                        game.machiTiles = result.tiles
                        game.machiYakuSet = result.yakuSet
                        game.machiFuritenSet = result.furitenSet
                    }
                }
            }
        }
        return nil
    }

    private var effectiveDiscardIndices: Set<Int> {
        guard game.isSelectingDapai && game.settings.dapaiAssist else { return [] }
        return cachedXiantingInfo.indices
    }

    private var xiantingInfo: (count: Int, indices: Set<Int>) {
        guard let human = game.humanPlayer else { return (99, []) }
        let tiles = human.shoupai.normalizedAllLabels
        var best = 99
        var indices = Set<Int>()
        for index in tiles.indices {
            let removedTiles = tiles.indices.filter { $0 != index }.map { tiles[$0] }
            let count = Hule.xiangting(removedTiles)
            if count < best {
                best = count
                indices = [index]
            } else if count == best {
                indices.insert(index)
            }
        }
        return (best, indices)
    }

    private var xiantingLabel: String {
        switch cachedXiantingInfo.count {
        case  0: return "テンパイ"
        default: return "\(cachedXiantingInfo.count)向聴"
        }
    }

    var body: some View {
        ShoupaiView(
            shoupai: game.board.shan.shoupai[0],
            isTajia: !hasStarted,
            onTapPai: onTapPaiHandler,
            highlightedIndices: highlightedIndices,
            selectedIndices: game.isSelectingDapai
                ? (game.pendingDapaiIndex.map { [$0] } ?? [])
                : game.isSelectingChi
                    ? Set(game.humanPlayer?.status.selectedChiIndices   ?? [])
                    : Set(game.humanPlayer?.status.selectedPengIndices   ?? []) ,
            baopai: game.board.shan.wangpai.baopai.map { $0.normalized },
            scale: 1.5,
            effectiveDiscardIndices: effectiveDiscardIndices
        )
        .overlay(alignment: .topLeading) {
            if game.isSelectingDapai && game.settings.dapaiAssist {
                Text(xiantingLabel)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.65))
                    .cornerRadius(6)
                    .fixedSize()
                    .offset(x: 520, y: 180)
            }
        }
        .offset(y: 180)
        .onChange(of: game.isSelectingDapai) { _, isSelecting in
            if isSelecting {
                cachedXiantingInfo = xiantingInfo
            } else {
                game.pendingDapaiIndex = nil
                cachedXiantingInfo = (99, [])
            }
        }
    }
}

#Preview("通常", traits: .landscapeLeft) {
    BoardView(game: Game(), debugActions: [])
}

#Preview("槓子", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [0: ["m1","m1","m1","m1","p0","p5","p5","p5","z1","z1","z1","z1","z5"]]
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
    game.status.player = 0
    game.zimoHule()
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
    game.ronHule([0])
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("四暗刻ツモ和了", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    let bingpai = ["m1","m1","m1","m9","m9","m9","s9","s9","s9","z1","z1","z3","z3"]
    game.board.shan.shoupai[0].bingpai = bingpai.map { Pai($0) }
    game.board.shan.shoupai[0].zimo = Pai("z3")
    game.status.zimo = "z3"
    game.status.player = 0
    game.zimoHule()
    return BoardView(game: game, debugActions: [], autoStart: false)
}


#Preview("九蓮宝燈9面", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","m9"],
        1: ["m4","m6","m8","p1","p3","p5","s7","s8","s9","z2","z2","z5","z5"],
        2: ["m7","p4","p8","s2","s4","s6","z4","z6","z7","m2","p2","s1","m9"],
        3: ["m4","m7","m9","p6","p7","p9","s1","s3","s5","z7","z7","p9","p9"],
    ]
    
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
    game.ronHule([0])
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
    game.ronHule([0])
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
    game.ronHule([0])
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
    game.ronHule([0])
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
    game.settings.kiriageMangan=true
    game.settings.dapaiAssist=true
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("四暗刻", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m1","m1","m9","m9","m9","s9","s9","s9","z1","z1","z1","z3"],
        1: ["m4","m6","m8","p1","p3","p5","s7","s8","s9","z2","z2","z5","z5"],
        2: ["m7","p4","p8","s2","s4","s6","z4","z6","z7","m2","p2","s1","m9"],
        3: ["m1","m3","m5","p6","p7","p9","s1","s3","s5","z7","z7","p9","p9"],
    ]
    game.settings.doubleYakumanAri=false
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("5役", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m3","m3","m4","m4","m5","m5","p3","p4","p5","s3","s4","s8","s8"],  // テンパイ z1/z3
        1: ["m4","m6","m8","p1","p3","p5","s7","s8","s9","z2","z2","z5","z5"],
        2: ["m7","p4","p8","s2","s4","s6","z4","z6","z7","m2","p2","s1","m9"],
        3: ["m1","m3","m5","p6","p7","p9","s1","s3","s5","z7","z7","p9","p9"],
    ]
    
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("全員聴牌", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m2","m3","p5","p6","p7","s3","s4","s5","s6","s7","z3","z5"],  // テンパイ z1/z3
        1: ["m4","m5","m6","p1","p2","p3","s7","s8","s9","z2","z2","z5","z5"],
        2: ["m4","m5","m6","p1","p2","p3","s7","s8","s9","z2","z2","z5","z5"],
        3: ["m4","m5","m6","p1","p2","p3","s7","s8","s9","z2","z2","z5","z5"],
    ]
    game.settings.tochukuryokuAri = false
    game.settings.dojiHuleMax = .tripleRon
    return BoardView(game: game, debugActions: [], autoStart: false)
}


#Preview("流局", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m2","m3","p5","p6","p7","s3","s4","s5","z1","z1","z3","z3"],  // テンパイ z1/z3
        1: ["m4","m4","p6","p6","p2","p2","s7","s7","s8","z2","z2","z5","z5"],  // テンパイ z2/z5
        2: ["m7","p4","p8","s2","s4","s6","z4","z6","z7","m2","p2","s1","m9"],  // ノーテン
        3: ["m1","m2","m3","p6","p7","p8","s1","s2","s3","z7","z7","p9","p9"],  // テンパイ z7/p9
    ]
    game.board.score.honba = 1
    game.board.score.lizhibang = 2
    game.pingju()
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("九種九牌", traits: .landscapeLeft) {
    let game = Game()
    game.kaiju()
    game.debugHands = [
        0: ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"],
        1: ["m1","m6","m8","p2","p4","p9","s2","s4","s8","z6","z7","z1","z2"],
        2: ["m2","m4","m6","p3","p5","p7","s3","s5","s9","z6","z7","z1","z2"],
        3: ["m3","m5","m7","p2","p4","p6","s2","s4","s6","z6","z7","z1","z2"],
    ]
    game.settings.nagashiManganAri = true
    return BoardView(game: game, debugActions: [], autoStart: false)
}

#Preview("四風連打", traits: .landscapeLeft) {
    // 全プレイヤー: z1（東）が孤立牌 → AIは必ずz1を最初に打つ
    // 人間プレイヤー（0）も z1 をタップして打牌すれば四風連打成立
    let game = Game()
    game.debugHands = [
        0: ["m1","m2","m3","m4","m5","m6","p1","p2","p3","s1","s1","z1","z2"],
        1: ["m1","m2","m3","m4","m5","m6","p1","p2","p3","s1","s1","z1","z2"],
        2: ["m1","m2","m3","m4","m5","m6","p1","p2","p3","s1","s1","z1","z2"],
        3: ["m1","m2","m3","m4","m5","m6","p1","p2","p3","s1","s1","z1","z2"],
    ]
    return BoardView(game: game, debugActions: [])
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

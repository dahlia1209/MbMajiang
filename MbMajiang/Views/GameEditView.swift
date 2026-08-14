import SwiftUI
import UIKit
import StoreKit

/// タイトル画面の「対局編集」から開く、対局の見た目（背景・牌デザイン・BGM）を編集するための画面。
/// 対局画面と同じく卓は裏向きのプレビュー状態で表示し、対局そのものは開始しない。
struct GameEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameSettings.self) private var settings
    @State private var game = Game()
    @State private var showBgmDetail = false
    @State private var showGenericTileDetail = false
    @State private var showTileBackDetail = false
    @State private var showCanvasDetail = false
    /// 自家手牌の位置調整パネル。対局編集パネルとは独立させ、パネル表示アイコンで隠しても表示し続ける
    @State private var showHandPositionPanel = false
    @State private var borderThemeSelected = false
    @State private var store = StoreManager.shared
    @State private var showShop = false
    @State private var showCanvasEditor = false
    @State private var shopContextMessage: String?
    @State private var previewingTrack: GameSettings.BGMTrack?
    @State private var isPanelHidden = false
    @State private var tileCategory: TileCategory = .manzu
    @State private var expandedSection: EditSection? = .tileFace

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    private static let roundLabels = ["東一局", "東二局", "東三局", "東四局", "南一局", "南二局", "南三局", "南四局"]

    /// 牌デザインをプレビューする際に自分の手牌へ表示する牌の種類
    private enum TileCategory: String, CaseIterable {
        case manzu  = "萬"
        case pinzu  = "筒"
        case souzu  = "索"
        case honors = "字"

        var tiles: [String] {
            switch self {
            case .manzu:  return ["m1", "m2", "m3", "m4", "m5", "m0", "m6", "m7", "m8", "m9"]
            case .pinzu:  return ["p1", "p2", "p3", "p4", "p5", "p0", "p6", "p7", "p8", "p9"]
            case .souzu:  return ["s1", "s2", "s3", "s4", "s5", "s0", "s6", "s7", "s8", "s9"]
            case .honors: return ["z1", "z2", "z3", "z4", "z5", "z6", "z7"]
            }
        }

        var next: TileCategory {
            let all = TileCategory.allCases
            let i = all.firstIndex(of: self)!
            return all[(i + 1) % all.count]
        }
    }

    /// 左側パネルのアコーディオン開閉対象となるセクション
    private enum EditSection {
        case tileFace, tileBack, background, bgm, mahjongTable
    }

    /// アコーディオンの開閉を切り替える。開くセクションが変わる際は、開いていた詳細パネルも閉じる
    private func toggleSection(_ section: EditSection) {
        showGenericTileDetail = false
        showTileBackDetail = false
        showBgmDetail = false
        showCanvasDetail = false
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedSection = (expandedSection == section) ? nil : section
        }
    }

    /// アコーディオンの見出し行。タップで該当セクションの開閉を切り替える
    private func accordionHeader(_ title: String, section: EditSection) -> some View {
        Button {
            toggleSection(section)
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.85))
                    .shadow(color: .black.opacity(0.9), radius: 2)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(goldLight.opacity(0.6))
                    .rotationEffect(.degrees(expandedSection == section ? 90 : 0))
            }
            .frame(width: 260)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func applyTileCategory(_ category: TileCategory) {
        let tiles = category.tiles
        let padding = Array(repeating: "_", count: max(0, 13 - tiles.count))
        game.board.shan.shoupai[0].bingpai = (tiles + padding).map { Pai($0) }
    }

    var body: some View {
        ZStack {
            BackgroundLayer(imageName: settings.effectiveBoardImageName,
                             overlayImage: settings.boardTheme == .canvas ? settings.boardCanvasImage : nil,
                             color: settings.boardBackgroundColor)

            VStack {
                Spacer()
                ScoreBoardView(game.board.score, Wangpai(), game.board.shan.paishu,
                               lizhiPlayers: [false, false, false, false])
                Spacer()
            }
            .padding(.horizontal, 40)

            HeView(he: He())
                .offset(y: 100)
            HeView(he: He())
                .offset(y: 200)
                .rotationEffect(.degrees(270))
            HeView(he: He())
                .offset(y: 100)
                .rotationEffect(.degrees(180))
            HeView(he: He())
                .offset(y: 200)
                .rotationEffect(.degrees(90))

            ShoupaiView(shoupai: game.board.shan.shoupai[0], isTajia: false, scale: 1.5)
                .offset(x: settings.handOffsetX, y: settings.handOffsetY)
            ShoupaiView(shoupai: game.board.shan.shoupai[1], isTajia: true)
                .offset(y: 300)
                .rotationEffect(.degrees(270))
            ShoupaiView(shoupai: game.board.shan.shoupai[2], isTajia: true)
                .offset(y: 160)
                .rotationEffect(.degrees(180))
            ShoupaiView(shoupai: game.board.shan.shoupai[3], isTajia: true)
                .offset(y: 290)
                .rotationEffect(.degrees(90))

            if !isPanelHidden {
                editPanel
                    .transition(.opacity)
            }

            if showHandPositionPanel {
                handPositionPanel
                    .transition(.opacity)
            }

            closeButton

            if showShop {
                ShopView(isPresented: $showShop, contextMessage: shopContextMessage)
                    .transition(.opacity)
            }
        }
        .environment(\.tileTheme, settings.tileTheme)
        .environment(\.genericTileColors, settings.genericTileColors)
        .environment(\.tileBackColor, settings.effectiveTileBackAppearance)
        .onAppear {
            applyTileCategory(tileCategory)
            borderThemeSelected = settings.tileBackDesignTheme == .striped
        }
        .onDisappear {
            settings.save()
            SoundManager.shared.stopBGM()
        }
        .fullScreenCover(isPresented: $showCanvasEditor) {
            CanvasEditorView(initialDrawingData: settings.boardCanvasDrawingDatas[settings.selectedCanvasSlot.rawValue],
                              backgroundColor: boardCanvasBackgroundColorBinding,
                              name: canvasSlotNameBinding,
                              defaultName: settings.selectedCanvasSlot.label) { drawingData, imageData in
                let i = settings.selectedCanvasSlot.rawValue
                settings.boardCanvasDrawingDatas[i] = drawingData
                settings.boardCanvasImageDatas[i] = imageData
            }
        }
    }

    /// 課金コンテンツが必要な操作を許可する前にチェックし、未購入ならショップを開く
    /// 未購入の場合、該当商品の購入確認シートをその場で表示する。商品が読み込めていない場合のみショップ画面にフォールバックする
    /// 未購入の場合に表示する、購入ボタン付きのバナー。購入が成功すると`onUnlock`を呼んでロックを解除する
    private func purchaseBanner(_ message: String, productID: StoreManager.ProductID, onUnlock: @escaping () -> Void) -> some View {
        let product = store.products.first(where: { $0.id == productID.rawValue })
        let owned = store.purchasedProductIDs.contains(productID.rawValue)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(product?.displayName ?? message)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(goldLight)
                Spacer()
                if let product {
                    Text(product.displayPrice)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(gold)
                }
            }

            Text(message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    if let product {
                        if await store.purchase(product) {
                            onUnlock()
                        }
                    } else {
                        shopContextMessage = nil
                        showShop = true
                    }
                }
            } label: {
                Text(owned ? "購入済み" : "購入して解放する")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(owned ? .white.opacity(0.7) : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(owned ? Color.gray.opacity(0.4) : gold)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(owned)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(gold.opacity(0.4), lineWidth: 1))
        )
    }

    // MARK: - Edit Panel

    private var editPanel: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 12) {
                Text("対局編集")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(gold)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.9), radius: 2)

                ScrollView {
                    VStack(spacing: 12) {
                        tileFaceColorSection
                        tileBackColorSection
                        boardBackgroundSection

                        bgmSection
                        mahjongTableSection
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 300)
            }
            .frame(width: 260)

            if showBgmDetail || showGenericTileDetail || showTileBackDetail || showCanvasDetail {
                Rectangle()
                    .fill(gold.opacity(0.25))
                    .frame(width: 1, height: 300)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if showGenericTileDetail {
                            tileFaceColorDetailContent
                        }
                        if showTileBackDetail {
                            tileBackColorDetailContent
                        }
                        if showCanvasDetail {
                            canvasDetailContent
                        }
                        if showBgmDetail {
                            bgmDetailContent
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(width: 260, height: 300)
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
                        .stroke(gold.opacity(0.5), lineWidth: 1)
                )
        )
        .offset(y: 0)
    }

    private var bgmDetailContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("局ごとのBGM")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold.opacity(0.8))
                .tracking(2)

            ForEach(0..<Self.roundLabels.count, id: \.self) { index in
                bgmRoundRow(index)
            }
        }
    }

    private enum DetailPanel {
        case genericTile, tileBack, bgm, canvas
    }

    /// 詳細設定パネルは右側の共有領域に1つだけ表示する。開くときは他の詳細設定を閉じる
    private func toggleDetailPanel(_ panel: DetailPanel) {
        let isCurrentlyOpen: Bool
        switch panel {
        case .genericTile: isCurrentlyOpen = showGenericTileDetail
        case .tileBack:    isCurrentlyOpen = showTileBackDetail
        case .bgm:         isCurrentlyOpen = showBgmDetail
        case .canvas:      isCurrentlyOpen = showCanvasDetail
        }
        showGenericTileDetail = false
        showTileBackDetail = false
        showBgmDetail = false
        showCanvasDetail = false
        if !isCurrentlyOpen {
            switch panel {
            case .genericTile: showGenericTileDetail = true
            case .tileBack:    showTileBackDetail = true
            case .bgm:         showBgmDetail = true
            case .canvas:      showCanvasDetail = true
            }
        }
    }

    /// 対局ルールパネルの「詳細設定」行と同じ見た目。項目名（既定は「詳細設定」）＋値「開く/閉じる」
    private func detailToggleRow(label: String = "詳細設定", isOpen: Bool, onToggle: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { onToggle() }
        } label: {
            HStack(spacing: 8) {
                Color.clear.frame(width: 16)
                Text(label)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.85))
                    .shadow(color: .black.opacity(0.9), radius: 2)
                Spacer()
                HStack(spacing: 4) {
                    Text(isOpen ? "閉じる" : "開く")
                    Image(systemName: isOpen ? "chevron.left" : "chevron.right")
                        .font(.system(size: 10))
                }
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold.opacity(0.85))
            }
            .frame(width: 260)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bgmSection: some View {
        VStack(spacing: 8) {
            accordionHeader("対局BGM", section: .bgm)

            if expandedSection == .bgm {
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.bgmBulkTrack },
                        set: { newValue in
                            settings.bgmBulkTrack = newValue
                            settings.bgmMode = .bulk
                        }
                    )) {
                        ForEach(GameSettings.BGMTrack.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(goldLight)
                    .lineLimit(1)
                    .fixedSize()
                    previewButton(settings.bgmBulkTrack)
                }
                .frame(width: 260)
                .disabled(settings.bgmMode == .perRound)
                .opacity(settings.bgmMode == .perRound ? 0.4 : 1)

                HStack(spacing: 8) {
                    Color.clear.frame(width: 16)
                    Text("局ごとに設定")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.85))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { settings.bgmMode == .perRound },
                        set: { newValue in
                            settings.bgmMode = newValue ? .perRound : .bulk
                            if !newValue { showBgmDetail = false }
                        }
                    ))
                    .labelsHidden()
                    .tint(gold)
                }
                .frame(width: 260)

                if settings.bgmMode == .perRound {
                    detailToggleRow(label: "", isOpen: showBgmDetail) {
                        toggleDetailPanel(.bgm)
                    }
                }
            }
        }
    }

    private var mahjongTableSection: some View {
        VStack(spacing: 8) {
            accordionHeader("麻雀卓", section: .mahjongTable)

            if expandedSection == .mahjongTable {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showHandPositionPanel.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Color.clear.frame(width: 16)
                        Text("自家手牌")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(goldLight.opacity(0.85))
                            .frame(width: 72, alignment: .leading)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("位置調整")
                            Image(systemName: showHandPositionPanel ? "chevron.left" : "chevron.right")
                                .font(.system(size: 10))
                        }
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(gold.opacity(0.85))
                    }
                    .frame(width: 260)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 自家手牌の位置調整パネル。対局編集パネルとは独立した位置に表示し、手牌に被らないようにする
    private var handPositionPanel: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Text("自家手牌の位置")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(gold.opacity(0.8))
                        .tracking(2)

                    handPositionDPad

                    Button {
                        settings.handOffsetX = 0
                        settings.handOffsetY = 180
                    } label: {
                        Text("リセット")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(goldLight.opacity(0.7))
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(gold.opacity(0.5), lineWidth: 1))
                )
                .padding(.top, 20)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }

    /// 自家手牌の位置を上下左右に微調整する十字キー
    private var handPositionDPad: some View {
        let step: Double = 4
        return VStack(spacing: 6) {
            handPositionDPadButton("chevron.up") { settings.handOffsetY -= step }
            HStack(spacing: 6) {
                handPositionDPadButton("chevron.left") { settings.handOffsetX -= step }
                Color.clear.frame(width: 44, height: 44)
                handPositionDPadButton("chevron.right") { settings.handOffsetX += step }
            }
            handPositionDPadButton("chevron.down") { settings.handOffsetY += step }
        }
    }

    private func handPositionDPadButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(goldLight)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func previewButton(_ track: GameSettings.BGMTrack) -> some View {
        Button {
            if previewingTrack == track {
                SoundManager.shared.stopBGM()
                previewingTrack = nil
            } else {
                SoundManager.shared.playBGM(track.bgmName)
                previewingTrack = track
            }
        } label: {
            Image(systemName: previewingTrack == track ? "stop.fill" : "play.fill")
                .font(.system(size: 11))
                .foregroundStyle(goldLight)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }

    private func bgmRoundRow(_ index: Int) -> some View {
        HStack(spacing: 8) {
            Text(Self.roundLabels[index])
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.85))
                .frame(width: 72, alignment: .leading)
            Spacer()
            Picker("", selection: Binding(
                get: { settings.bgmByRound[index] },
                set: { newValue in
                    settings.bgmByRound[index] = newValue
                    settings.bgmMode = .perRound
                }
            )) {
                ForEach(GameSettings.BGMTrack.allCases, id: \.self) { track in
                    Text(track.rawValue).tag(track)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            previewButton(settings.bgmByRound[index])
        }
    }

    private var tileBackColorSection: some View {
        VStack(spacing: 8) {
            accordionHeader("牌デザイン（裏）", section: .tileBack)

            if expandedSection == .tileBack {
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16)
                    Text("テーマ")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.85))
                        .frame(width: 72, alignment: .leading)
                    Spacer()
                    Picker("", selection: tileBackDesignThemeBinding) {
                        ForEach(GameSettings.TileBackDesignTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(goldLight)
                    .lineLimit(1)
                    .fixedSize()
                }
                .frame(width: 260)

                if !borderThemeSelected {
                    HStack(spacing: 8) {
                        Color.clear.frame(width: 16)
                        Text("カラー")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(goldLight.opacity(0.85))
                            .frame(width: 72, alignment: .leading)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.tileBackColorMode == .detailed ? .custom : settings.tileBackColor },
                            set: { newValue in
                                if newValue == .custom {
                                    settings.tileBackColorMode = .detailed
                                } else {
                                    settings.tileBackColor = newValue
                                    settings.tileBackColorMode = .simple
                                }
                            }
                        )) {
                            ForEach(GameSettings.TileBackColor.allCases, id: \.self) { color in
                                Text(color.rawValue).tag(color)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(goldLight)
                        .lineLimit(1)
                        .fixedSize()
                    }
                    .frame(width: 260)

                    if settings.tileBackColorMode == .detailed {
                        HStack(spacing: 8) {
                            Color.clear.frame(width: 16)
                            Text("カスタム")
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundStyle(goldLight.opacity(0.85))
                                .frame(width: 72, alignment: .leading)
                            Spacer()
                            ColorPicker("", selection: tileBackColorCustomBinding, supportsOpacity: false)
                                .labelsHidden()
                        }
                        .frame(width: 260)
                    }
                } else {
                    HStack(spacing: 8) {
                        Color.clear.frame(width: 16)
                        Text("カラー")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(goldLight.opacity(0.85))
                            .frame(width: 72, alignment: .leading)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.tileBackColorMode == .detailed ? .custom : settings.tileBackColorScheme },
                            set: { newValue in
                                if newValue == .custom {
                                    settings.tileBackColorMode = .detailed
                                } else {
                                    settings.tileBackColorScheme = newValue
                                    settings.tileBackColorMode = .simple
                                }
                            }
                        )) {
                            ForEach(GameSettings.TileBackColorScheme.allCases, id: \.self) { scheme in
                                Text(scheme.rawValue).tag(scheme)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(goldLight)
                        .lineLimit(1)
                        .fixedSize()
                    }
                    .frame(width: 260)

                    if settings.tileBackColorMode == .detailed {
                        detailToggleRow(label: "カスタム", isOpen: showTileBackDetail) {
                            toggleDetailPanel(.tileBack)
                        }
                    }
                }
            }
        }
    }

    private var boardBackgroundSection: some View {
        VStack(spacing: 8) {
            accordionHeader("背景", section: .background)

            if expandedSection == .background {
                if settings.boardTheme == .canvas {
                    boardThemePickerRow
                    boardCanvasRow
                } else if settings.boardTheme == .animal {
                    boardThemePickerRow
                    boardAnimalRow
                } else {
                    boardThemePickerRow

                    if settings.boardTheme == .original {
                        HStack(spacing: 8) {
                            Color.clear.frame(width: 16)
                            Text("カラー")
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundStyle(goldLight.opacity(0.85))
                                .frame(width: 72, alignment: .leading)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settings.boardBackgroundColorMode == .detailed ? .custom : settings.boardBackgroundColorPreset },
                                set: { newValue in
                                    if newValue == .custom {
                                        settings.boardBackgroundColorMode = .detailed
                                    } else {
                                        settings.boardBackgroundColorPreset = newValue
                                        settings.boardBackgroundColorMode = .simple
                                    }
                                }
                            )) {
                                ForEach(GameSettings.BoardBackgroundColor.allCases, id: \.self) { color in
                                    Text(color.rawValue).tag(color)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(goldLight)
                            .lineLimit(1)
                            .fixedSize()
                        }
                        .frame(width: 260)

                        if settings.boardBackgroundColorMode == .detailed {
                            HStack(spacing: 8) {
                                Color.clear.frame(width: 16)
                                Text("カスタム")
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundStyle(goldLight.opacity(0.85))
                                    .frame(width: 72, alignment: .leading)
                                Spacer()
                                ColorPicker("", selection: boardBackgroundColorCustomBinding, supportsOpacity: false)
                                    .labelsHidden()
                            }
                            .frame(width: 260)
                        }
                    }
                }
            }
        }
    }

    private var boardThemePickerRow: some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: 16)
            Text("テーマ")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.85))
                .frame(width: 72, alignment: .leading)
            Spacer()
            Picker("", selection: Binding(
                get: { settings.boardTheme },
                set: { newValue in
                    if newValue == .canvas && !store.hasCanvasTheme {
                        showGenericTileDetail = false
                        showTileBackDetail = false
                        showBgmDetail = false
                        showCanvasDetail = true
                    } else {
                        settings.boardTheme = newValue
                    }
                }
            )) {
                ForEach(GameSettings.BoardTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
        }
        .frame(width: 260)
    }

    /// 「アニマル」テーマで表示する動物を選ぶ行
    private var boardAnimalRow: some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: 16)
            Text("アニマル")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.85))
                .frame(width: 72, alignment: .leading)
            Spacer()
            Picker("", selection: Bindable(settings).animalBoardBackground) {
                ForEach(GameSettings.AnimalBoardBackground.allCases, id: \.self) { animal in
                    Text(animal.rawValue).tag(animal)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
        }
        .frame(width: 260)
    }

    /// 「キャンバス」テーマで使うキャンバス枠（1〜5）の選択行
    private var boardCanvasRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Color.clear.frame(width: 16)
                Text("キャンバス")
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.85))
                    .frame(width: 72, alignment: .leading)
                Spacer()
                Picker("", selection: Bindable(settings).selectedCanvasSlot) {
                    ForEach(GameSettings.CanvasSlot.allCases, id: \.self) { slot in
                        Text(settings.canvasSlotDisplayName(slot)).tag(slot)
                    }
                }
                .pickerStyle(.menu)
                .tint(goldLight)
                .lineLimit(1)
                .fixedSize()
            }
            .frame(width: 260)

            boardCanvasEditButton
        }
    }

    /// 選択中のキャンバス枠の名前を編集するバインディング
    private var canvasSlotNameBinding: Binding<String> {
        Binding(
            get: { settings.canvasSlotNames[settings.selectedCanvasSlot.rawValue] },
            set: { settings.canvasSlotNames[settings.selectedCanvasSlot.rawValue] = $0 }
        )
    }

    /// 選択中のキャンバス枠を手書き編集画面で開くボタン
    private var boardCanvasEditButton: some View {
        Button { showCanvasEditor = true } label: {
            HStack(spacing: 4) {
                Text("編集")
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
            }
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(gold.opacity(0.85))
            .frame(width: 260, alignment: .trailing)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var tileFaceColorSection: some View {
        VStack(spacing: 8) {
            accordionHeader("牌デザイン（表）", section: .tileFace)

            if expandedSection == .tileFace {
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16)
                    Text("カラー")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.85))
                        .frame(width: 72, alignment: .leading)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.genericTileColorMode == .detailed ? .custom : settings.genericColorScheme },
                        set: { newValue in
                            if newValue == .custom {
                                settings.genericTileColorMode = .detailed
                            } else {
                                settings.genericColorScheme = newValue
                                settings.genericTileColorMode = .simple
                            }
                        }
                    )) {
                        ForEach(GameSettings.GenericColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.rawValue).tag(scheme)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(goldLight)
                    .lineLimit(1)
                    .fixedSize()
                }
                .frame(width: 260)

                if settings.genericTileColorMode == .detailed {
                    detailToggleRow(label: "カスタム", isOpen: showGenericTileDetail) {
                        toggleDetailPanel(.genericTile)
                    }
                }
            }
        }
    }


    private var tileBackColorDetailContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("牌デザイン（裏）詳細")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold.opacity(0.8))
                .tracking(2)

            if !store.hasBorderTheme {
                HStack(spacing: 18) {
                    Spacer()
                    borderPreviewTile(.zebra).scaleEffect(2.0)
                    borderPreviewTile(.lesserPanda).scaleEffect(2.0)
                    borderPreviewTile(.manul).scaleEffect(2.0)
                    Spacer()
                }
                .padding(.vertical, 14)
                purchaseBanner("牌デザイン（裏）の「ボーダー」テーマで、本数やカラーを自由に組み合わせた縞模様に設定できるようになります", productID: .borderTheme) {
                    settings.tileBackDesignTheme = .striped
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("本数")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.85))
                        .frame(width: 72, alignment: .leading)
                    Spacer()
                    Picker("", selection: Bindable(settings).tileBackBorderCount) {
                        ForEach(Array(GameSettings.tileBackBorderCountRange), id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(goldLight)
                    .lineLimit(1)
                    .fixedSize()
                }

                HStack(spacing: 8) {
                    Text("カラー1")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.85))
                        .frame(width: 72, alignment: .leading)
                    Spacer()
                    ColorPicker("", selection: tileBackBorderColor1CustomBinding, supportsOpacity: false)
                        .labelsHidden()
                }

                HStack(spacing: 8) {
                    Text("カラー2")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.85))
                        .frame(width: 72, alignment: .leading)
                    Spacer()
                    ColorPicker("", selection: tileBackBorderColor2CustomBinding, supportsOpacity: false)
                        .labelsHidden()
                }
            }
            .disabled(!store.hasBorderTheme)
            .opacity(store.hasBorderTheme ? 1 : 0.5)
        }
    }

    /// ボーダーテーマがどんな見た目になるか購入前にイメージできるよう、しまうま配色の牌裏をプレビュー表示する
    private func borderPreviewTile(_ scheme: GameSettings.TileBackColorScheme) -> some View {
        PaiView("z1", reveal: false)
            .environment(\.tileBackColor, .striped(count: scheme.count, color1: scheme.color1, color2: scheme.color2))
    }

    private var tileBackBorderColor1CustomBinding: Binding<Color> {
        Binding(
            get: { settings.tileBackBorderColor1Custom },
            set: { newColor in
                let ui = UIColor(newColor)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ui.getRed(&r, green: &g, blue: &b, alpha: &a)
                settings.tileBackBorderColor1CustomRed = Double(r)
                settings.tileBackBorderColor1CustomGreen = Double(g)
                settings.tileBackBorderColor1CustomBlue = Double(b)
            }
        )
    }

    private var tileBackBorderColor2CustomBinding: Binding<Color> {
        Binding(
            get: { settings.tileBackBorderColor2Custom },
            set: { newColor in
                let ui = UIColor(newColor)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ui.getRed(&r, green: &g, blue: &b, alpha: &a)
                settings.tileBackBorderColor2CustomRed = Double(r)
                settings.tileBackBorderColor2CustomGreen = Double(g)
                settings.tileBackBorderColor2CustomBlue = Double(b)
            }
        )
    }

    private var canvasDetailContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("キャンバス詳細")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold.opacity(0.8))
                .tracking(2)

            HStack {
                Spacer()
                canvasPreview
                Spacer()
            }
            .padding(.vertical, 6)

            if !store.hasCanvasTheme {
                purchaseBanner("背景に自由に手書きした絵を設定できるようになります", productID: .canvasTheme) {
                    settings.boardTheme = .canvas
                }
            }
        }
    }

    /// キャンバステーマがどんな見た目になるか購入前にイメージできるよう、簡単な手書き風のイラストをプレビュー表示する
    private var canvasPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.95, green: 0.92, blue: 0.82))
            Path { path in
                path.move(to: CGPoint(x: 8, y: 34))
                path.addCurve(to: CGPoint(x: 30, y: 10),
                               control1: CGPoint(x: 14, y: 6), control2: CGPoint(x: 20, y: 40))
                path.addCurve(to: CGPoint(x: 52, y: 30),
                               control1: CGPoint(x: 40, y: -8), control2: CGPoint(x: 46, y: 44))
            }
            .stroke(Color(red: 0.75, green: 0.2, blue: 0.2), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { path in
                path.move(to: CGPoint(x: 14, y: 28))
                path.addLine(to: CGPoint(x: 46, y: 18))
            }
            .stroke(Color(red: 0.2, green: 0.4, blue: 0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Circle()
                .fill(Color(red: 0.3, green: 0.55, blue: 0.3))
                .frame(width: 8, height: 8)
                .offset(x: 20, y: 12)
        }
        .frame(width: 60, height: 44)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(gold.opacity(0.5), lineWidth: 1))
    }

    private var tileFaceColorDetailContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("牌デザイン（表）詳細")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold.opacity(0.8))
                .tracking(2)

            if !store.hasDetailedColors {
                HStack(spacing: 6) {
                    Spacer()
                    genericColorPreviewTile("m1").scaleEffect(1.6)
                    genericColorPreviewTile("p1").scaleEffect(1.6)
                    genericColorPreviewTile("s1").scaleEffect(1.6)
                    genericColorPreviewTile("z1").scaleEffect(1.6)
                    Spacer()
                }
                .padding(.vertical, 14)

                purchaseBanner("牌デザイン（表）の「カスタムカラー」で、RGBを自由に選んで好きな色に設定できるようになります", productID: .detailedColors) {
                    settings.genericTileColorMode = .detailed
                }
            }

            genericTileColorDetailRows
                .disabled(!store.hasDetailedColors)
                .opacity(store.hasDetailedColors ? 1 : 0.5)
        }
    }

    /// 詳細設定（RGB自由選択）がどんな見た目になるか購入前にイメージできるよう、カラフルな配色の牌をプレビュー表示する
    private func genericColorPreviewTile(_ code: String) -> some View {
        PaiView(code)
            .environment(\.genericTileColors, GameSettings.GenericTileColors(
                manzuDigit: Color(red: 0.85, green: 0.1, blue: 0.55),
                manzuWan:   Color(red: 0.95, green: 0.35, blue: 0.05),
                pinzuRed:   Color(red: 0.95, green: 0.35, blue: 0.05),
                pinzuGreen: Color(red: 0.05, green: 0.55, blue: 0.85),
                souzuRed:   Color(red: 0.9, green: 0.15, blue: 0.15),
                souzuGreen: Color(red: 0.15, green: 0.65, blue: 0.25),
                honorWind:  Color(red: 0.55, green: 0.15, blue: 0.85),
                honorHatsu: Color(red: 0.15, green: 0.65, blue: 0.25),
                honorChun:  Color(red: 0.9, green: 0.15, blue: 0.15),
                akaDora:    Color(red: 0.95, green: 0.35, blue: 0.05),
                souzuBirdAccent: Color(red: 0.05, green: 0.55, blue: 0.85)
            ))
    }

    private var genericTileColorDetailRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            genericColorGroupHeader("萬子")
            genericCustomRow("漢数字", rgbColorBinding(
                r: Bindable(settings).genericManzuDigitColorRed,
                g: Bindable(settings).genericManzuDigitColorGreen,
                b: Bindable(settings).genericManzuDigitColorBlue))
            genericCustomRow("萬", rgbColorBinding(
                r: Bindable(settings).genericManzuWanColorRed,
                g: Bindable(settings).genericManzuWanColorGreen,
                b: Bindable(settings).genericManzuWanColorBlue))

            genericColorGroupHeader("筒子")
            genericCustomRow("基調", rgbColorBinding(
                r: Bindable(settings).genericPinzuGreenColorRed,
                g: Bindable(settings).genericPinzuGreenColorGreen,
                b: Bindable(settings).genericPinzuGreenColorBlue))
            genericCustomRow("差し色", rgbColorBinding(
                r: Bindable(settings).genericPinzuRedColorRed,
                g: Bindable(settings).genericPinzuRedColorGreen,
                b: Bindable(settings).genericPinzuRedColorBlue))

            genericColorGroupHeader("索子")
            genericCustomRow("基調", rgbColorBinding(
                r: Bindable(settings).genericSouzuGreenColorRed,
                g: Bindable(settings).genericSouzuGreenColorGreen,
                b: Bindable(settings).genericSouzuGreenColorBlue))
            genericCustomRow("差し色", rgbColorBinding(
                r: Bindable(settings).genericSouzuRedColorRed,
                g: Bindable(settings).genericSouzuRedColorGreen,
                b: Bindable(settings).genericSouzuRedColorBlue))
            genericCustomRow("一索差し色", rgbColorBinding(
                r: Bindable(settings).genericSouzuBirdAccentColorRed,
                g: Bindable(settings).genericSouzuBirdAccentColorGreen,
                b: Bindable(settings).genericSouzuBirdAccentColorBlue))

            genericColorGroupHeader("字牌")
            genericCustomRow("風牌", rgbColorBinding(
                r: Bindable(settings).genericHonorWindColorRed,
                g: Bindable(settings).genericHonorWindColorGreen,
                b: Bindable(settings).genericHonorWindColorBlue))
            genericCustomRow("發", rgbColorBinding(
                r: Bindable(settings).genericHonorHatsuColorRed,
                g: Bindable(settings).genericHonorHatsuColorGreen,
                b: Bindable(settings).genericHonorHatsuColorBlue))
            genericCustomRow("中", rgbColorBinding(
                r: Bindable(settings).genericHonorChunColorRed,
                g: Bindable(settings).genericHonorChunColorGreen,
                b: Bindable(settings).genericHonorChunColorBlue))

            genericColorGroupHeader("赤ドラ（共通）")
            genericCustomRow("色", rgbColorBinding(
                r: Bindable(settings).genericAkaDoraColorRed,
                g: Bindable(settings).genericAkaDoraColorGreen,
                b: Bindable(settings).genericAkaDoraColorBlue))
        }
    }

    private func genericColorGroupHeader(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(gold.opacity(0.7))
            .tracking(1)
            .padding(.top, 4)
    }

    private func genericCustomRow(_ label: String, _ binding: Binding<Color>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.85))
                .frame(width: 72, alignment: .leading)
            Spacer()
            ColorPicker("", selection: binding, supportsOpacity: false)
                .labelsHidden()
        }
    }

    private func rgbColorBinding(r: Binding<Double>, g: Binding<Double>, b: Binding<Double>) -> Binding<Color> {
        Binding(
            get: { Color(red: r.wrappedValue, green: g.wrappedValue, blue: b.wrappedValue) },
            set: { newColor in
                let ui = UIColor(newColor)
                var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
                ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
                r.wrappedValue = Double(rr)
                g.wrappedValue = Double(gg)
                b.wrappedValue = Double(bb)
            }
        )
    }


    private var boardBackgroundColorCustomBinding: Binding<Color> {
        Binding(
            get: { settings.boardBackgroundColorCustom },
            set: { newColor in
                let ui = UIColor(newColor)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ui.getRed(&r, green: &g, blue: &b, alpha: &a)
                settings.boardBackgroundColorRed = Double(r)
                settings.boardBackgroundColorGreen = Double(g)
                settings.boardBackgroundColorBlue = Double(b)
            }
        )
    }

    private var boardCanvasBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { settings.boardCanvasBackgroundColor },
            set: { newColor in
                let ui = UIColor(newColor)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ui.getRed(&r, green: &g, blue: &b, alpha: &a)
                let i = settings.selectedCanvasSlot.rawValue
                settings.boardCanvasBackgroundColorsRed[i] = Double(r)
                settings.boardCanvasBackgroundColorsGreen[i] = Double(g)
                settings.boardCanvasBackgroundColorsBlue[i] = Double(b)
            }
        )
    }

    private var tileBackDesignThemeBinding: Binding<GameSettings.TileBackDesignTheme> {
        Binding(
            get: { borderThemeSelected ? .striped : .original },
            set: { newValue in
                borderThemeSelected = (newValue == .striped)
                if newValue == .striped {
                    if store.hasBorderTheme {
                        settings.tileBackDesignTheme = .striped
                    } else {
                        showGenericTileDetail = false
                        showBgmDetail = false
                        showTileBackDetail = true
                    }
                } else {
                    settings.tileBackDesignTheme = .original
                }
            }
        )
    }

    private var tileBackColorCustomBinding: Binding<Color> {
        Binding(
            get: { settings.tileBackColorCustom },
            set: { newColor in
                let ui = UIColor(newColor)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ui.getRed(&r, green: &g, blue: &b, alpha: &a)
                settings.tileBackColorCustomRed = Double(r)
                settings.tileBackColorCustomGreen = Double(g)
                settings.tileBackColorCustomBlue = Double(b)
            }
        )
    }

    private func themePickerRow<T: CaseIterable & Hashable & RawRepresentable>(
        _ label: String,
        selection: Binding<T>
    ) -> some View where T.AllCases: RandomAccessCollection, T.RawValue == String {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.85))
                .shadow(color: .black.opacity(0.9), radius: 2)
            Spacer()
            Picker("", selection: selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
        }
        .frame(width: 260)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                VStack(spacing: 8) {
                    Button(action: { dismiss() }) {
                        Text("×")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isPanelHidden.toggle() }
                    } label: {
                        Image(systemName: isPanelHidden ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16))
                            .foregroundColor(isPanelHidden ? .white.opacity(0.5) : .yellow)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button {
                        tileCategory = tileCategory.next
                        applyTileCategory(tileCategory)
                    } label: {
                        Text(tileCategory.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button {
                        shopContextMessage = nil
                        showShop = true
                    } label: {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(gold)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.leading, 12)
                .padding(.top, 12)
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    GameEditView()
        .environment(GameSettings())
}

import SwiftUI

struct GameSettingsView: View {
    @Environment(GameSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    /// 対局画面のプレスタートパネルから「詳細設定」として開かれた場合はtrue。
    /// このときフッターは対局を開始せず、設定を保存して画面を閉じるだけにする
    var embedded: Bool = false
    @State private var startedGame: Game? = nil
    @State private var isLocked = false

    private let gold      = Color(red: 0.8, green: 0.6, blue: 0.2)
    private let goldLight = Color(red: 1.0, green: 0.92, blue: 0.6)
    private let labelW: CGFloat = 148

    private enum SettingsCategory: String, CaseIterable, Identifiable {
        case rule       = "基本設定"
        case cpu        = "CPU設定"
        case display    = "表示設定"
        case score      = "点数設定"
        case tile       = "牌設定"
        case progress   = "進行設定"
        case riichiDora = "立直・ドラ"
        case yakuman    = "役満"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .rule:       return "list.bullet.rectangle"
            case .cpu:        return "cpu"
            case .display:    return "eye"
            case .score:      return "number.square"
            case .tile:       return "square.stack.3d.up"
            case .progress:   return "flag.checkered"
            case .riichiDora: return "sparkles"
            case .yakuman:    return "crown"
            }
        }

        var isLockable: Bool {
            switch self {
            case .score, .tile, .progress, .riichiDora, .yakuman: return true
            case .rule, .cpu, .display: return false
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BackgroundLayer()

                VStack(spacing: 0) {
                    header

                    Divider()
                        .background(gold.opacity(0.3))
                        .padding(.horizontal, 60)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(SettingsCategory.allCases) { category in
                                sectionBlock(category)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 60)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }

                    footer
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .fullScreenCover(item: $startedGame) { game in
            BoardView(game: game, debugActions: [], autoStart: false, showStartButton: true)
        }
        .onAppear { isLocked = settings.selectedPreset != .custom }
        .onDisappear { settings.save() }
        .transaction { $0.disablesAnimations = true }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { settings.save(); dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("戻る")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(gold)
            }
            .buttonStyle(.plain)
            .padding(.leading, 60)

            Spacer()

            Text("対局ルール")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold)
                .tracking(6)

            Spacer()

            Color.clear.frame(width: 80)
        }
        .frame(height: 44)
    }

    // MARK: - Section (single-list layout)

    private func sectionBlock(_ category: SettingsCategory) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(gold)
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(goldLight)
                if category.isLockable && isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(gold.opacity(0.4))
                }
            }

            categoryDetail(category)

            if category != SettingsCategory.allCases.last {
                Divider().background(gold.opacity(0.15))
            }
        }
    }

    // MARK: - Detail (Preview area)

    @ViewBuilder
    private func categoryDetail(_ category: SettingsCategory) -> some View {
        switch category {
        case .rule:       ruleDetail
        case .cpu:        cpuDetail
        case .display:    displayDetail
        case .score:      scoreDetail
        case .tile:       tileDetail
        case .progress:   progressDetail
        case .riichiDora: riichiDoraDetail
        case .yakuman:    yakumanDetail
        }
    }

    private var ruleDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            radioRow("局数", selection: Bindable(settings).kyokuCount)
            timeLimitRow
            presetRow
        }
    }

    private var cpuDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            radioRow("下家のタイプ", selection: cpuStyleBinding(0))
            radioRow("対面のタイプ", selection: cpuStyleBinding(1))
            radioRow("上家のタイプ", selection: cpuStyleBinding(2))
        }
    }

    private func cpuStyleBinding(_ seatIndex: Int) -> Binding<GameSettings.CpuStyle> {
        Binding(
            get: { settings.cpuStyles[seatIndex] },
            set: { settings.cpuStyles[seatIndex] = $0 }
        )
    }

    private var displayDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            boolRow("打牌アシスト", isOn: Bindable(settings).dapaiAssist)
            boolRow("副露アシスト", isOn: Bindable(settings).fulouAssist)
            boolRow("手牌表示オプション", isOn: Bindable(settings).showHandDisplayOption)
        }
    }

    private var scoreDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            numberRow("配給原点",
                value: Binding(get: { settings.haikyuGenten },
                               set: { settings.haikyuGenten = $0 }))
            junikitenRow
            radioRow("連風牌", selection: Bindable(settings).renpuFu)
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.4 : 1)
    }

    private var tileDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            akadoraRow
            boolRow("クイタン", isOn: Bindable(settings).kuitanAri)
            radioRow("喰い替え", selection: Bindable(settings).kuichikaeLevel)
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.4 : 1)
    }

    private var progressDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            boolRow("途中流局", isOn: Bindable(settings).tochukuryokuAri)
            boolRow("流し満貫", isOn: Bindable(settings).nagashiManganAri)
            boolRow("ノーテン宣言", isOn: Bindable(settings).notenSengenAri)
            boolRow("ノーテン罰", isOn: Bindable(settings).notenBatsuAri)
            radioRow("同時和了", selection: Bindable(settings).dojiHuleMax)
            radioRow("連荘方式", selection: Bindable(settings).renzhuFang)
            boolRow("トビ終了", isOn: Bindable(settings).tobiEndAri)
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.4 : 1)
    }

    private var riichiDoraDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            boolRow("一発", isOn: Bindable(settings).ippatsuAri)
            boolRow("裏ドラ", isOn: Bindable(settings).uradoraAri)
            kandoraRow
            boolRow("カン裏", isOn: Bindable(settings).kanUraAri)
            radioRow("リーチ後の暗槓", selection: Bindable(settings).riichiAnkanLevel)
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.4 : 1)
    }

    private var yakumanDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            boolRow("役満の複合", isOn: Bindable(settings).yakumanFukugouAri)
            boolRow("ダブル役満", isOn: Bindable(settings).doubleYakumanAri)
            boolRow("数え役満", isOn: Bindable(settings).kazoeYakumanAri)
            boolRow("役満パオ", isOn: Bindable(settings).yakumanPaoAri)
            boolRow("切り上げ満貫", isOn: Bindable(settings).kiriageMangan)
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.4 : 1)
    }

    // MARK: - Generic Row Builders

    private func boolRow(_ title: String, isOn: Binding<Bool>) -> some View {
        row(title) {
            radioButton("なし", selected: !isOn.wrappedValue) { isOn.wrappedValue = false }
            radioButton("あり", selected:  isOn.wrappedValue) { isOn.wrappedValue = true  }
        }
    }

    private func radioRow<T: CaseIterable & Hashable & RawRepresentable>(
        _ title: String,
        selection: Binding<T>
    ) -> some View where T.AllCases: RandomAccessCollection, T.RawValue == String {
        row(title) {
            ForEach(Array(T.allCases), id: \.self) { option in
                radioButton(option.rawValue, selected: selection.wrappedValue == option) {
                    selection.wrappedValue = option
                }
            }
        }
    }

    private func numberRow(_ title: String, value: Binding<Int>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            rowLabel(title)
            numField(value: value, width: 80)
            Spacer()
        }
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            rowLabel(title)
            HStack(spacing: 14) { content() }
            Spacer()
        }
    }

    private func rowLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(goldLight)
            .frame(width: labelW, alignment: .leading)
    }

    // MARK: - Special Rows

    private var presetRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            rowLabel("ルール")
            HStack(spacing: 14) {
                ForEach(GameSettings.Preset.allCases, id: \.self) { preset in
                    let isCustom   = preset == .custom
                    let isSelected = isCustom ? !isLocked : (isLocked && settings.selectedPreset == preset)
                    Button {
                        if isCustom {
                            settings.selectedPreset = .custom
                            isLocked = false
                        } else {
                            settings.applyPreset(preset)
                            isLocked = true
                        }
                    } label: {
                        Text(preset.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? goldLight : goldLight.opacity(0.45))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? gold.opacity(0.25) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? gold.opacity(0.6) : gold.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
    }

    private var junikitenRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                rowLabel("順位点")
                HStack(spacing: 10) {
                    rankFieldDisplay(rank: "1着", value: settings.junkiten1)
                    ForEach(0..<3, id: \.self) { i in
                        rankFieldEdit(rank: "\(i + 2)着",
                                      binding: Binding(
                                        get: { settings.junikitenRanks[i] },
                                        set: { settings.junikitenRanks[i] = $0 }))
                    }
                }
                Spacer()
            }
            HStack(spacing: 6) {
                Color.clear.frame(width: labelW + 12)
                checkboxButton("ポイントを四捨五入する", isOn: Bindable(settings).junkitenRounding)
            }
        }
    }

    private var akadoraRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            rowLabel("赤牌")
            HStack(spacing: 12) {
                akadoraInput("萬", value: Bindable(settings).akadoraMan)
                akadoraInput("筒", value: Bindable(settings).akadoraPin)
                akadoraInput("索", value: Bindable(settings).akadoraSou)
            }
            Spacer()
        }
    }

    private func akadoraInput(_ label: String, value: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 12)).foregroundStyle(gold.opacity(0.6))
            numField(value: value, width: 36)
        }
    }

    private var kandoraRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("カンドラ") {
                radioButton("なし", selected: !settings.kandoraAri) { settings.kandoraAri = false }
                radioButton("あり", selected:  settings.kandoraAri) { settings.kandoraAri = true  }
            }
//            HStack(spacing: 6) {
//                Color.clear.frame(width: labelW + 12)
//                checkboxButton("後乗せ", isOn: Bindable(settings).kandoraNochigakeAri)
//            }
        }
    }

    // MARK: - Atomic Components

    private func radioButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 11))
                    .foregroundStyle(selected ? gold : gold.opacity(0.35))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(selected ? goldLight : goldLight.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private func checkboxButton(_ label: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundStyle(isOn.wrappedValue ? gold : gold.opacity(0.35))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(gold.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    private func numField(value: Binding<Int>, width: CGFloat) -> some View {
        TextField("", value: value, format: .number)
            .textFieldStyle(.plain)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(goldLight)
            .frame(width: width)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(fieldBackground)
    }

    private func rankFieldDisplay(rank: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Text(rank).font(.system(size: 11)).foregroundStyle(gold.opacity(0.55))
            Text("\(value)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.4))
                .frame(width: 52)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(gold.opacity(0.15), lineWidth: 0.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.02)))
                )
        }
    }

    private func rankFieldEdit(rank: String, binding: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(rank).font(.system(size: 11)).foregroundStyle(gold.opacity(0.55))
            TextField("", value: binding, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(goldLight)
                .frame(width: 52)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(fieldBackground)
        }
    }

    private var timeLimitRow: some View {
        radioRow("長考時間", selection: Bindable(settings).thinkingTimeMode)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(gold.opacity(0.4), lineWidth: 0.5)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
                .background(gold.opacity(0.3))
                .padding(.horizontal, 60)

            Button {
                if embedded {
                    settings.save()
                    dismiss()
                } else {
                    startGame()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.82, green: 0.68, blue: 0.25).opacity(0.25))
                        .blur(radius: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.97, green: 0.93, blue: 0.83),
                                         Color(red: 0.82, green: 0.68, blue: 0.25)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
                    Text(embedded ? "閉じる" : "対局開始  ▶")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.97, green: 0.93, blue: 0.83),
                                         Color(red: 0.82, green: 0.68, blue: 0.25)],
                                startPoint: .leading, endPoint: .trailing))
                        .tracking(4)
                }
                .frame(width: 220, height: 50)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
        .background(Color(red: 30/255, green: 85/255, blue: 25/255).opacity(0.97))
    }

    // MARK: - Actions

    private func startGame() {
        startedGame = Game(settings: settings)
    }
}

#Preview(traits: .landscapeLeft) {
    GameSettingsView()
        .environment(GameSettings())
}

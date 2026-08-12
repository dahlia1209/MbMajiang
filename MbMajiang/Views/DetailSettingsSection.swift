//
//  DetailSettingsSection.swift
//  MbMajiang
//
//  対局前パネルの「詳細を調整」展開時に表示する、ルールプリセット「カスタム」選択時の細かい設定項目。
//

import SwiftUI

struct DetailSettingsSection: View {
    @Bindable var settings: GameSettings

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)
    private let labelW: CGFloat = 130

    private static let haikyuGentenRange = Array(stride(from: 20000, through: 50000, by: 5000))
    private static let junikitenRange = Array(stride(from: -50, through: 50, by: 10))

    private var isLocked: Bool { settings.selectedPreset != .custom }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            group("基本") {
                presetRow
                radioRow("長考時間", selection: $settings.thinkingTimeMode)
                boolRow("切り上げ満貫", isOn: $settings.kiriageMangan)
            }
            group("CPU") {
                cpuStyleRow("下家", seatIndex: 0)
                cpuStyleRow("対面", seatIndex: 1)
                cpuStyleRow("上家", seatIndex: 2)
            }
            group("アシスト") {
                boolRow("打牌アシスト", isOn: $settings.dapaiAssist)
                boolRow("アガリ牌表示", isOn: $settings.agariHaiDisplay)
                boolRow("副露アシスト", isOn: $settings.fulouAssist)
                yesNoRow("手役一覧", isOn: $settings.showTeyakuList)
                yesNoRow("遊び方", isOn: $settings.showHowToPlayAssist)
                boolRow("手牌表示オプション", isOn: $settings.showHandDisplayOption)
            }
            group("点数") {
                numberRow("配給原点", value: $settings.haikyuGenten, options: Self.haikyuGentenRange)
                junikitenRow
                radioRow("連風牌", selection: $settings.renpuFu)
            }
            .disabled(isLocked)
            .opacity(isLocked ? 0.4 : 1)

            group("牌") {
                akadoraRow
                boolRow("クイタン", isOn: $settings.kuitanAri)
                radioRow("喰い替え", selection: $settings.kuichikaeLevel)
            }
            .disabled(isLocked)
            .opacity(isLocked ? 0.4 : 1)

            group("進行") {
                boolRow("途中流局", isOn: $settings.tochukuryokuAri)
                boolRow("流し満貫", isOn: $settings.nagashiManganAri)
                boolRow("ノーテン宣言", isOn: $settings.notenSengenAri)
                boolRow("ノーテン罰", isOn: $settings.notenBatsuAri)
                radioRow("同時和了", selection: $settings.dojiHuleMax)
                radioRow("連荘方式", selection: $settings.renzhuFang)
                boolRow("トビ終了", isOn: $settings.tobiEndAri)
            }
            .disabled(isLocked)
            .opacity(isLocked ? 0.4 : 1)

            group("立直・ドラ") {
                boolRow("一発", isOn: $settings.ippatsuAri)
                boolRow("裏ドラ", isOn: $settings.uradoraAri)
                boolRow("カンドラ", isOn: $settings.kandoraAri)
                boolRow("カン裏", isOn: $settings.kanUraAri)
            }
            .disabled(isLocked)
            .opacity(isLocked ? 0.4 : 1)

            group("役満") {
                boolRow("役満の複合", isOn: $settings.yakumanFukugouAri)
                boolRow("ダブル役満", isOn: $settings.doubleYakumanAri)
                boolRow("数え役満", isOn: $settings.kazoeYakumanAri)
                boolRow("役満パオ", isOn: $settings.yakumanPaoAri)
            }
            .disabled(isLocked)
            .opacity(isLocked ? 0.4 : 1)
        }
    }

    // MARK: - Special Rows

    private var presetRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel("ルール")
            Picker("", selection: Binding(
                get: { settings.selectedPreset },
                set: { newValue in
                    if newValue == .custom {
                        settings.selectedPreset = .custom
                    } else {
                        settings.applyPreset(newValue)
                    }
                }
            )) {
                ForEach(GameSettings.Preset.allCases, id: \.self) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private func cpuStyleRow(_ label: String, seatIndex: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(label)
            Picker("", selection: cpuStyleBinding(seatIndex)) {
                ForEach(GameSettings.CpuStyle.allCases, id: \.self) { style in
                    Text(style.detailPanelLabel).tag(style)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private func cpuStyleBinding(_ seatIndex: Int) -> Binding<GameSettings.CpuStyle> {
        Binding(
            get: { settings.cpuStyles[seatIndex] },
            set: { settings.cpuStyles[seatIndex] = $0 }
        )
    }

    private var akadoraRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowLabel("赤牌枚数")
            akadoraPicker("萬子", value: $settings.akadoraMan)
            akadoraPicker("筒子", value: $settings.akadoraPin)
            akadoraPicker("索子", value: $settings.akadoraSou)
        }
    }

    private func akadoraPicker(_ label: String, value: Binding<Int>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Color.clear.frame(width: 16)
            rowLabel(label)
            Picker("", selection: value) {
                ForEach(0...4, id: \.self) { n in Text("\(n)").tag(n) }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private var junikitenRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("順位点")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(goldLight)

            rankStaticRow("1着", value: settings.junkiten1)
            rankEditRow("2着", binding: $settings.junikitenRanks[0])
            rankEditRow("3着", binding: $settings.junikitenRanks[1])
            rankEditRow("4着", binding: $settings.junikitenRanks[2])

            boolRow("端数処理（四捨五入）", isOn: $settings.junkitenRounding)
        }
    }

    private func rankStaticRow(_ rank: String, value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(rank)
            Text("\(value)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.4))
                .frame(width: 60)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(fieldBackground)
            Spacer()
        }
    }

    private func rankEditRow(_ rank: String, binding: Binding<Int>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(rank)
            Picker("", selection: binding) {
                ForEach(Self.junikitenRange, id: \.self) { n in Text("\(n)").tag(n) }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    // MARK: - Group

    @ViewBuilder
    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(gold.opacity(0.8))
                .tracking(2)
            content()
        }
    }

    // MARK: - Row Builders (すべてセレクトボックス形式)

    private func boolRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(title)
            Picker("", selection: isOn) {
                Text("なし").tag(false)
                Text("あり").tag(true)
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private func yesNoRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(title)
            Picker("", selection: isOn) {
                Text("いいえ").tag(false)
                Text("はい").tag(true)
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private func radioRow<T: CaseIterable & Hashable & RawRepresentable>(
        _ title: String,
        selection: Binding<T>
    ) -> some View where T.AllCases: RandomAccessCollection, T.RawValue == String {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(title)
            Picker("", selection: selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private func numberRow(_ title: String, value: Binding<Int>, options: [Int]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            rowLabel(title)
            Picker("", selection: value) {
                ForEach(options, id: \.self) { n in Text("\(n)").tag(n) }
            }
            .pickerStyle(.menu)
            .tint(goldLight)
            .lineLimit(1)
            .fixedSize()
            Spacer()
        }
    }

    private func rowLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(goldLight.opacity(0.85))
            .shadow(color: .black.opacity(0.9), radius: 2)
            .frame(width: labelW, alignment: .leading)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(gold.opacity(0.4), lineWidth: 0.5)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
    }
}

#Preview(traits: .landscapeLeft) {
    ScrollView {
        DetailSettingsSection(settings: GameSettings())
            .padding(20)
    }
}

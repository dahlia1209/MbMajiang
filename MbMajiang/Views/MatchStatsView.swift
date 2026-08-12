//
//  MatchStatsView.swift
//  MbMajiang
//

import SwiftUI
import Charts

/// 自分（プレイヤー index 0）の通算成績を表示する画面
struct MatchStatsView: View {
    @Binding var isPresented: Bool
    @Environment(GameSettings.self) private var settings

    @State private var stats = PlayerLifetimeStats.load()
    @State private var selectedMode: GameSettings.KyokuCount
    @State private var collapsedYakuGroups: Set<String> = Set(MatchStatsView.yakuGroupOrder)

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    private let rankColors: [Color] = [
        Color(red: 0.95, green: 0.75, blue: 0.25), // 1位: gold
        Color(red: 0.78, green: 0.80, blue: 0.84), // 2位: silver
        Color(red: 0.76, green: 0.5, blue: 0.32),  // 3位: bronze
        Color(red: 0.45, green: 0.45, blue: 0.52)  // 4位: gray
    ]

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
        _selectedMode = State(initialValue: GameSettings().kyokuCount)
    }

    private var current: PlayerLifetimeStats.ModeStats {
        stats[selectedMode]
    }

    var body: some View {
        ZStack {
            // 遷移元の画面（同じビュー階層内の背後のコンテンツ）をぼかして見せる
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                modePicker
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kpiRow

                        HStack(alignment: .top, spacing: 14) {
                            rankDistributionCard
                            roundRateCard
                        }

                        HStack(alignment: .top, spacing: 14) {
                            pointCard
                            top5YakuCard
                        }

                        yakuSection
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            selectedMode = settings.kyokuCount
            stats = PlayerLifetimeStats.load()
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Header
    private var header: some View {
        ZStack {
            Text("対局成績")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(goldLight)
                .shadow(color: .black.opacity(0.9), radius: 2)
                .frame(maxWidth: .infinity)

            HStack {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isPresented = false } }) {
                    Text("×")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 36)
    }

    private var modePicker: some View {
        Picker("", selection: $selectedMode) {
            ForEach(GameSettings.KyokuCount.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - KPIヘッドライン
    private var kpiRow: some View {
        HStack(spacing: 10) {
            kpiCard(icon: "gamecontroller.fill", value: "\(current.gameCount)", label: "試合数")
            kpiCard(icon: "chart.line.uptrend.xyaxis", value: formatDecimal(current.averageRank, suffix: ""), label: "平均着順")
            kpiCard(icon: "crown.fill", value: formatPercent(current.topRate), label: "トップ率")
            kpiCard(icon: "yensign.circle.fill", value: formatPoint(current.totalPoints), label: "通算ポイント")
        }
    }

    private func kpiCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(gold)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardBackground)
    }

    // MARK: - 着順分布（ドーナツチャート）
    private var rankDistributionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("着順分布")

            if current.gameCount > 0 {
                HStack(spacing: 16) {
                    Chart {
                        ForEach(Array(current.rankCounts.enumerated()), id: \.offset) { index, count in
                            SectorMark(angle: .value("回数", count), innerRadius: .ratio(0.62), angularInset: 1.5)
                                .foregroundStyle(rankColors[index])
                                .cornerRadius(2)
                        }
                    }
                    .frame(width: 96, height: 96)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: 6) {
                                Circle().fill(rankColors[index]).frame(width: 8, height: 8)
                                Text("\(index + 1)位")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(goldLight.opacity(0.85))
                                Spacer()
                                Text("\(current.rankCounts[index])回")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("対局データがありません")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - 局内容（レートバー）
    private var roundRateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("局内容")

            VStack(spacing: 12) {
                rateBar("副露率", current.fulouRate)
                rateBar("リーチ率", current.lizhiRate)
                rateBar("アガリ率", current.agariRate)
                rateBar("放銃率", current.houjuuRate)
            }
            .padding(.vertical, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func rateBar(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.8))
                Spacer()
                Text(formatPercent(value))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.35))
                    Capsule().fill(gold)
                        .frame(width: geo.size.width * CGFloat(min(max(value, 0), 100)) / 100)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - 項目一覧
    private var pointItems: [(String, String)] {
        [
            ("平均打点", "\(Int(current.averageAgariPoints.rounded()))点"),
            ("放銃平均打点", "\(Int(current.averageHoujuuPoints.rounded()))点"),
            ("ベストスコア", formatScore(current.bestScore ?? 0)),
            ("総局数", "\(current.roundCount)"),
        ]
    }

    // MARK: - 和了役一覧（翻数ごとにグルーピング）
    private struct YakuStat: Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    private struct YakuGroup: Identifiable {
        let label: String
        let items: [YakuStat]
        var total: Int { items.reduce(0) { $0 + $1.count } }
        var id: String { label }
    }

    /// 東西南北・白發中を区別せず1つにまとめて表示するための対応表（表示名 → 集計対象の元の役名）
    private static let mergedYakuNames: [(display: String, sources: [String])] = {
        let winds = ["東", "南", "西", "北"]
        return [
            ("場風牌", winds.map { "場風（\($0)）" }),
            ("自風牌", winds.map { "自風（\($0)）" }),
            ("連風牌", winds.map { "連風牌（\($0)）" }),
            ("白・發・中", ["白", "發", "中"]),
        ]
    }()

    /// 表示用の役名一覧（まとめられる役はまとめ、それ以外は元の役名をそのまま使う）
    private static let displayYakuNames: [(display: String, sources: [String])] = {
        let mergedSourceNames = Set(mergedYakuNames.flatMap(\.sources))
        let individual = Yaku.allPossibleNames
            .filter { !mergedSourceNames.contains($0) }
            .map { (display: $0, sources: [$0]) }
        return mergedYakuNames + individual
    }()

    private func yakuStat(for entry: (display: String, sources: [String])) -> YakuStat {
        let count = entry.sources.reduce(0) { $0 + (current.yakuCounts[$1] ?? 0) }
        return YakuStat(name: entry.display, count: count)
    }

    /// 役名から翻数グループを判定する。鳴きによる翻減はグルーピング上は無視し、門前基準の翻数で分類する
    private func hanGroupLabel(for name: String) -> String {
        switch name {
        case "場風牌", "自風牌", "連風牌", "白・發・中":
            return "1翻"
        case "門前清自摸和", "立直", "一発", "槍槓", "嶺上開花", "海底摸月", "河底撈魚",
             "平和", "断么九", "一盃口":
            return "1翻"
        case "ダブル立直", "三色同順", "三色同刻", "一気通貫", "混全帯么九",
             "七対子", "対対和", "三暗刻", "三槓子", "小三元", "混老頭":
            return "2翻"
        case "二盃口", "混一色", "純全帯么九":
            return "3翻"
        case "清一色":
            return "6翻"
        case "国士無双十三面待ち", "四暗刻単騎待ち", "大四喜", "純正九蓮宝燈":
            return "ダブル役満"
        case "国士無双", "四暗刻", "大三元", "小四喜", "字一色", "緑一色",
             "清老頭", "九蓮宝燈", "四槓子", "天和", "地和":
            return "役満"
        default: // ドラ, 裏ドラ
            return "ドラ"
        }
    }

    /// グループの並び順（ドラ→1翻→2翻→3翻→6翻→役満→ダブル役満の固定順）
    private static let yakuGroupOrder = ["ドラ", "1翻", "2翻", "3翻", "6翻", "役満", "ダブル役満"]

    private var yakuGroups: [YakuGroup] {
        let dict = Dictionary(grouping: Self.displayYakuNames) { hanGroupLabel(for: $0.display) }
        return Self.yakuGroupOrder.compactMap { label -> YakuGroup? in
            guard let entries = dict[label] else { return nil }
            let items = entries
                .map { yakuStat(for: $0) }
                .sorted { $0.count > $1.count }
            return YakuGroup(label: label, items: items)
        }
    }

    /// アガリ回数が多い役TOP5（ドラ・0回の役は除外）
    private var top5Yaku: [YakuStat] {
        Array(
            Self.displayYakuNames
                .filter { $0.display != "ドラ" }
                .map { yakuStat(for: $0) }
                .filter { $0.count > 0 }
                .sorted { $0.count > $1.count }
                .prefix(5)
        )
    }

    private var top5YakuCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(gold)
                sectionHeader("アガリ役 TOP5")
            }

            if top5Yaku.isEmpty {
                Text("対局データがありません")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(top5Yaku.enumerated()), id: \.element.id) { index, item in
                        top5YakuRow(rank: index + 1, item: item, agariCount: current.agariCount)
                        if index < top5Yaku.count - 1 {
                            Divider().background(gold.opacity(0.12))
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func top5YakuRow(rank: Int, item: YakuStat, agariCount: Int) -> some View {
        let percent = agariCount > 0 ? Double(item.count) / Double(agariCount) * 100 : 0
        return HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(gold)
                .frame(width: 16, alignment: .center)

            Text(item.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(goldLight)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 150, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.25))
                    Capsule().fill(gold)
                        .frame(width: geo.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
                }
            }
            .frame(height: 5)

            Text(formatPercent(percent))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
    }

    // MARK: - 打点
    private var pointCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("打点")
            VStack(spacing: 10) {
                ForEach(pointItems.indices, id: \.self) { i in
                    pointRow(pointItems[i].0, pointItems[i].1)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func pointRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    /// 左列（ドラ・1翻）と右列（2翻以降）に分けて表示する
    private var leftColumnYakuGroups: [YakuGroup] {
        yakuGroups.filter { $0.label == "ドラ" || $0.label == "1翻" }
    }

    private var rightColumnYakuGroups: [YakuGroup] {
        yakuGroups.filter { $0.label != "ドラ" && $0.label != "1翻" }
    }

    private var yakuSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("和了役一覧")

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(leftColumnYakuGroups) { group in
                        yakuGroupCard(group)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rightColumnYakuGroups) { group in
                        yakuGroupCard(group)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func yakuGroupCard(_ group: YakuGroup) -> some View {
        let maxCount = max(group.items.map(\.count).max() ?? 0, 1)
        let isCollapsed = collapsedYakuGroups.contains(group.label)
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isCollapsed { collapsedYakuGroups.remove(group.label) }
                    else { collapsedYakuGroups.insert(group.label) }
                }
            } label: {
                HStack {
                    Text(group.label)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(gold)
                    Spacer()
                    Text("計\(group.total)回")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.5))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(goldLight.opacity(0.5))
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        yakuRow(item, maxCount: maxCount)
                        if index < group.items.count - 1 {
                            Divider().background(gold.opacity(0.12))
                        }
                    }
                }
                .background(cardBackground)
            }
        }
    }

    private func yakuRow(_ item: YakuStat, maxCount: Int) -> some View {
        let achieved = item.count > 0
        return HStack(spacing: 10) {
            Text(item.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(achieved ? goldLight : goldLight.opacity(0.35))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 160, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.25))
                    if achieved {
                        Capsule().fill(gold)
                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                    }
                }
            }
            .frame(height: 5)

            Text("\(item.count)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(achieved ? .white : goldLight.opacity(0.35))
                .frame(width: 26, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
    }

    // MARK: - グリッド表示
    private func gridSection(_ title: String, items: [(String, String)], minCellWidth: CGFloat = 130) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minCellWidth), spacing: 10)], spacing: 10) {
                ForEach(items.indices, id: \.self) { i in
                    statCell(items[i].0, items[i].1)
                }
            }
        }
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(cardBackground)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(goldLight.opacity(0.6))
            .tracking(2)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.black.opacity(0.3))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(gold.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Formatting
    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    private func formatDecimal(_ value: Double, suffix: String) -> String {
        String(format: "%.1f\(suffix)", value)
    }

    private func formatPoint(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "\(sign)%.1f", value)
    }

    private func formatScore(_ value: Int) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        return n.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview(traits: .landscapeLeft) {
    MatchStatsView(isPresented: .constant(true))
        .environment(GameSettings())
}

//
//  PlayerButtonView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/12.
//

import SwiftUI

// MARK: - PlayerButtonAction

enum PlayerButtonAction: CaseIterable, Hashable {
    case cancel  // ×
    case noten   // ノー聴
    case chi     // チー
    case peng    // ポン
    case gang    // カン
    case angang    // 暗カン
    case kagang    // 加カン
    case minggang    // 明カン
    case lizhi    // リーチ
    case rong     // ロン
    case zimo     // ツモ
    case pingju   // 流局
    case kyuushu  // 九種九牌

    nonisolated var label: String {
        switch self {
        case .cancel: return "×"
        case .noten:  return "ノー聴"
        case .chi:    return "チー"
        case .peng:   return "ポン"
        case .gang:   return "カン"
        case .angang:   return "カン"
        case .kagang:   return "加カン"
        case .minggang:   return "カン"
        case .lizhi:  return "リーチ"
        case .rong:   return "ロン"
        case .zimo:     return "ツモ"
        case .pingju:   return "テンパイ"
        case .kyuushu:  return "九種九牌"
        }
    }

    // ボタンの背景色
     var color: Color {
        switch self {
        case .cancel:         return Color(white: 0.35)
        case .noten:          return Color(red: 0.5, green: 0.3, blue: 0.1)
        case .chi:            return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .peng:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .gang:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .angang:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .kagang:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .minggang:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .lizhi:          return Color(red: 0.6, green: 0.45, blue: 0.1)
        case .rong:           return Color(red: 0.55, green: 0.15, blue: 0.15)
        case .zimo:           return Color(red: 0.55, green: 0.15, blue: 0.15)
        case .pingju:         return Color(red: 0.25, green: 0.25, blue: 0.45)
        case .kyuushu:        return Color(red: 0.25, green: 0.25, blue: 0.45)
        }
    }
}

// MARK: - PlayerButtonView
struct PlayerButtonView: View {
    /// 表示するボタンのセット（含まれないボタンは非表示）
    var visibleActions: Set<PlayerButtonAction>
    var onAction: (PlayerButtonAction) -> Void

    // HTMLの並び順に固定
    private let order: [PlayerButtonAction] = [
        .cancel, .noten, .chi, .peng, .gang, .angang, .kagang, .minggang, .lizhi, .rong, .zimo, .pingju, .kyuushu
    ]

    var body: some View {
        HStack(spacing: 30) {
            ForEach(order, id: \.self) { action in
                if visibleActions.contains(action) {
                    Button {
                        onAction(action)
                    } label: {
                        Text(action.label)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 64, minHeight: 48)
                            .padding(.horizontal, 10)
                            .background(action.color)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.55))
        .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    ZStack {
        Color.green.opacity(0.4).ignoresSafeArea()
        PlayerButtonView(
            visibleActions: [.cancel, .chi, .peng, .lizhi, .rong, .zimo]
        ) { action in
            print("tapped: \(action)")
        }
    }
}

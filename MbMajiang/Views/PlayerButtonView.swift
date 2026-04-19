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
    case lizhi   // リーチ
    case rong    // ロン
    case zimo    // ツモ
    case pingju  // 流局

    nonisolated var label: String {
        switch self {
        case .cancel: return "×"
        case .noten:  return "ノー聴"
        case .chi:    return "チー"
        case .peng:   return "ポン"
        case .gang:   return "カン"
        case .lizhi:  return "リーチ"
        case .rong:   return "ロン"
        case .zimo:   return "ツモ"
        case .pingju: return "流局"
        }
    }

    // ボタンの背景色
    nonisolated var color: Color {
        switch self {
        case .cancel:         return Color(white: 0.35)
        case .noten:          return Color(red: 0.5, green: 0.3, blue: 0.1)
        case .chi:            return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .peng:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .gang:           return Color(red: 0.2, green: 0.45, blue: 0.2)
        case .lizhi:          return Color(red: 0.6, green: 0.45, blue: 0.1)
        case .rong:           return Color(red: 0.55, green: 0.15, blue: 0.15)
        case .zimo:           return Color(red: 0.55, green: 0.15, blue: 0.15)
        case .pingju:         return Color(red: 0.25, green: 0.25, blue: 0.45)
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
        .cancel, .noten, .chi, .peng, .gang, .lizhi, .rong, .zimo, .pingju
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(order, id: \.self) { action in
                if visibleActions.contains(action) {
                    Button {
                        onAction(action)
                    } label: {
                        Text(action.label)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 52, minHeight: 36)
                            .padding(.horizontal, 8)
                            .background(action.color)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .cornerRadius(8)
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

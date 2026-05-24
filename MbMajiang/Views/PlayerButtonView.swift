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
        case .cancel: return "スキップ"
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

    // フレーム画像を使うボタンの色（nil = テキストのみ）
    var tintColor: Color? {
        switch self {
        case .chi:                          return Color(red: 0.2, green: 0.65, blue: 0.25)
        case .peng:                         return Color(red: 0.15, green: 0.6,  blue: 0.65)
        case .gang, .angang, .kagang, .minggang:
                                            return Color(red: 0.55, green: 0.2,  blue: 0.7)
        case .lizhi:                        return Color(red: 0.75, green: 0.55, blue: 0.1)
        case .rong:                         return Color(red: 0.7,  green: 0.15, blue: 0.15)
        case .zimo:                         return Color(red: 0.6,  green: 0.15, blue: 0.5)
        case .cancel:                       return Color(white: 0.55)
        default:                            return nil
        }
    }

    // tintColor を持たないボタンの背景色
    var color: Color {
        switch self {
        case .cancel:   return Color(white: 0.35)
        case .noten:    return Color(red: 0.5, green: 0.3, blue: 0.1)
        case .pingju:   return Color(red: 0.25, green: 0.25, blue: 0.45)
        case .kyuushu:  return Color(red: 0.25, green: 0.25, blue: 0.45)
        default:        return Color(red: 0.2, green: 0.45, blue: 0.2)
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
        .noten, .chi, .peng, .gang, .angang, .kagang, .minggang, .lizhi, .rong, .zimo, .pingju, .kyuushu, .cancel
    ]

    var body: some View {
        HStack(spacing: 30) {
            ForEach(order, id: \.self) { action in
                if visibleActions.contains(action) {
                    Button {
                        onAction(action)
                    } label: {
                        if let tint = action.tintColor {
                            ZStack {
                                Image("buttonFrame")
                                    .resizable()
                                    .scaledToFit()
                                    .colorMultiply(tint)
                                Text(action.label)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                            }
                            .frame(height: 90)
                        } else {
                            Text(action.label)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 100, minHeight: 90)
                                .padding(.horizontal, 10)
                                .background(action.color)
                                .cornerRadius(8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

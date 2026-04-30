//
//  FulouGroupView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/19.
//

import SwiftUI

struct FulouGroupView: View {
    let group: [Pai]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(group.indices, id: \.self) { i in
                PaiView(pai: group[i])
            }
        }
    }

    /// グループの合計横幅（rotated牌は30pt、通常牌は22pt）
    static func width(of group: [Pai]) -> CGFloat {
        group.reduce(0) { $0 + ($1.rotated ? 30 : 22) }
    }
}

#Preview {
    // ポン（上家から）: [rotated打牌, 手牌, 手牌]
    var dapai = Pai("z7"); dapai.rotated = true
    let group: [Pai] = [dapai, Pai("z7"), Pai("z7")]
    return FulouGroupView(group: group)
        .padding()
        .background(Color.green.opacity(0.3))
}

//
//  HeView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/05.
//

import SwiftUI

struct HeView: View {
    var he: He
    var highlightedIndex: Int? = nil

    // 1行6枚 × 22px
    private let rowWidth: CGFloat = 22 * 6

    var body: some View {
        let row1 = Array(he.qipai.prefix(6))
        let row2 = he.qipai.count > 6  ? Array(he.qipai[6..<min(12, he.qipai.count)]) : []
        let row3 = he.qipai.count > 12 ? Array(he.qipai[12...]) : []

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(row1.indices, id: \.self) { i in
                    paiCell(row1[i], globalIndex: i)
                }
            }
            .frame(width: rowWidth, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(row2.indices, id: \.self) { i in
                    paiCell(row2[i], globalIndex: 6 + i)
                }
            }
            .frame(width: rowWidth, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(row3.indices, id: \.self) { i in
                    paiCell(row3[i], globalIndex: 12 + i)
                }
            }
            .frame(width: rowWidth, alignment: .leading)
        }
        .frame(width: rowWidth, height: 30 * 3, alignment: .topLeading)
    }

    @ViewBuilder
    private func paiCell(_ pai: Pai, globalIndex: Int) -> some View {
        PaiView(pai.label)
            .rotationEffect(pai.rotated ? .degrees(90) : .degrees(0))
            .opacity(globalIndex == highlightedIndex ? 0.5 : 1.0)
    }
}

#Preview(traits: .landscapeLeft) {
    HeView(he:He(qipai: [Pai("m1"),Pai("m2"),Pai("m3"),Pai("m4"),Pai("m5"),Pai("m6"),Pai("p1"),Pai("p2"),Pai("p3"),Pai("p4"),Pai("p5"),Pai("p6"),Pai("s1"),Pai("s2"),Pai("s3"),Pai("s4"),Pai("s5"),Pai("s6"),Pai("z1")]))
}

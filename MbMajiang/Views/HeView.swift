//
//  HeView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/05.
//

import SwiftUI

struct HeView: View {
    var he:He
    
    var body: some View {
        let row1 = Array(he.qipai.prefix(6))
        let row2 = he.qipai.count > 6 ? Array(he.qipai[6..<min(12, he.qipai.count)]) : []
        let row3 = he.qipai.count > 12 ? Array(he.qipai[12...]) : []
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(row1, id: \.self) { pai in
                    PaiView(pai.label)
                }
            }
            HStack(spacing: 0) {
                ForEach(row2, id: \.self) { pai in
                    PaiView(pai.label)
                }
            }
            HStack(spacing: 0) {
                ForEach(row3, id: \.self) { pai in
                    PaiView(pai.label)
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HeView(he:He(qipai: [Pai("m1"),Pai("m2"),Pai("m3"),Pai("m4"),Pai("m5"),Pai("m6"),Pai("p1"),Pai("p2"),Pai("p3"),Pai("p4"),Pai("p5"),Pai("p6"),Pai("s1"),Pai("s2"),Pai("s3"),Pai("s4"),Pai("s5"),Pai("s6"),Pai("z1")]))
}

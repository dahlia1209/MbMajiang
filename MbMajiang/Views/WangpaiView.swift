//
//  WangpaiView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/04.
//

import SwiftUI

struct WangpaiView: View {
    var wangpai:Wangpai=Wangpai()
    
    var body: some View {
        doraSection
        }
    
    var doraSection: some View {
        
            HStack(spacing: 0) {
                    // baopaiの数だけドラを表示
                    ForEach(wangpai.baopai, id: \.self) { pai in
                        PaiView(pai.label)
                    }
                    // 残りを裏向きで表示
                    ForEach(0..<(5 - wangpai.baopai.count), id: \.self) { _ in
                        PaiView("_")
                    }
                }
    }
    
    
}


#Preview {
    WangpaiView(wangpai: Wangpai(
        baopai: [Pai("p1")],
        libaopai: [Pai("s1"),Pai("s2"),Pai("s3"),Pai("s4"),Pai("s5"),Pai("s6"),Pai("s7"),Pai("s8"),Pai("s9"),],
        lingshang: [Pai("z1"),Pai("z2"),Pai("z3"),Pai("z4")]
    ))
}

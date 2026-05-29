//
//  TileView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/01.
//

import SwiftUI

struct PaiView: View {
    var pai: Pai
    @Environment(\.tileTheme) private var tileTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(isRevealed() ? Color.white : Color(red: 229/255, green: 179/255, blue: 67/255))

            if self.isRevealed() {
                let imageName = tileTheme.imageName(for: pai.label)
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                }
            }
        }
        .clipped()
        .frame(width: 22, height: 30)
        .rotationEffect(pai.rotated ? .degrees(90) : .zero)
        .frame(width: pai.rotated ? 30 : 22, height: pai.rotated ? 22 : 30)
        .opacity(isHidden() ? 0 : 1)
    }
    
    mutating func hide() {
        self.pai.hidden = true
    }
    
    func isHidden() -> Bool {
        return self.pai.hidden
        }
    
    mutating func reveal() {
        self.pai.revealed = true
    }
    
    mutating func reverse() {
        self.pai.revealed = false
    }
    
    func isRevealed() -> Bool {
        return pai.label != "_" && self.pai.revealed
    }
}

extension PaiView {
    init(_ code: String, reveal: Bool = true, hidden: Bool = false) {
        self.pai = Pai(code)
        self.pai.revealed = reveal
        self.pai.hidden = hidden
    }
}

#Preview("通常") {
    PaiView("p4")
}

#Preview("裏") {
    PaiView("p4", reveal: false)
}

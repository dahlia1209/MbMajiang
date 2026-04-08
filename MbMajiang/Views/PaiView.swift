//
//  TileView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/04/01.
//

import SwiftUI

struct PaiView: View {
    var pai:Pai
    
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(self.isRevealed() ? Color.white : Color(red: 229/255, green: 179/255, blue: 67/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(self.isRevealed() ? Color.gray.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 0.5)
                )

            if self.isRevealed() {
                if let uiImage = UIImage(named: pai.label) {
                        Image(uiImage: uiImage)
                            .resizable()
                    }
            }
        }
        .frame(width: 22, height: 30)
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
    init(_ code: String, _ reveal: Bool=true, _ hidden:Bool = false)  {
        self.pai = Pai(code)
        self.pai.revealed=reveal
        self.pai.hidden=hidden
    }
}

#Preview {
    PaiView("p4")
}

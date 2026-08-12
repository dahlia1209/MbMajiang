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
    @Environment(\.tileBackColor) private var tileBackColor
    @Environment(\.genericTileColors) private var genericTileColors

    var body: some View {
        ZStack {
            if isRevealed() {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white)
                if tileTheme == .original,
                   let layers = GameSettings.genericTileLayers(for: pai.label, colors: genericTileColors) {
                    ForEach(layers.masks, id: \.name) { mask in
                        Image(mask.name)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(mask.color)
                    }
                    Image(layers.fixed)
                        .resizable()
                } else {
                    let imageName = tileTheme.imageName(for: pai.label)
                    if let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                    }
                }
            } else {
                tileBackView
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

    @ViewBuilder
    private var tileBackView: some View {
        switch tileBackColor {
        case .solid(let color):
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
        case .striped(let count, let color1, let color2):
            VStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    (i % 2 == 0 ? color1 : color2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
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

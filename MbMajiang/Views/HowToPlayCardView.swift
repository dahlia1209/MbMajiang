//
//  HowToPlayCardView.swift
//  MbMajiang
//
//  「遊び方」チュートリアルのカード本体（見出し・本文・ページ送り）。
//  タイトル画面からの`HowToPlayView`と、対局中アシストの遊び方パネルの両方から共通で使う。
//

import SwiftUI

struct HowToPlayCardView: View {
    @State private var currentChapter = 0

    /// 最終ページに「CPU対局を開始する」ボタンを表示するか。対局中アシストからの表示では非表示にする
    var showStartGameButton: Bool = true
    var onStartGame: (() -> Void)? = nil

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    private var chapters: [HowToPlayChapter] { HowToPlayContent.chapters }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            Divider().background(gold.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(chapters[currentChapter].blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .id(currentChapter)

            Divider().background(gold.opacity(0.3))
            cardFooter
        }
        .frame(width: 560, height: 340)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.45)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gold.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var cardHeader: some View {
        HStack {
            Text(chapters[currentChapter].title)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(goldLight)
                .shadow(color: .black.opacity(0.9), radius: 2)
                .lineLimit(1)
            Spacer()
            Text("\(currentChapter + 1) / \(chapters.count)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(gold.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var isLastChapter: Bool { currentChapter == chapters.count - 1 }

    private var cardFooter: some View {
        HStack(spacing: 10) {
            navButton("◀ 前へ", enabled: currentChapter > 0) {
                currentChapter -= 1
            }
            Spacer()
            if showStartGameButton && isLastChapter {
                startGameButton
                Spacer()
            }
            navButton("次へ ▶", enabled: !isLastChapter) {
                currentChapter += 1
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var startGameButton: some View {
        Button {
            onStartGame?()
        } label: {
            Text("CPU対局を開始する")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(colors: [goldLight, gold], startPoint: .leading, endPoint: .trailing))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(gold.opacity(0.28))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(gold.opacity(0.8), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func navButton(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(enabled ? goldLight : goldLight.opacity(0.25))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(gold.opacity(enabled ? 0.22 : 0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(gold.opacity(enabled ? 0.6 : 0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func blockView(_ block: HowToPlayBlock) -> some View {
        switch block {
        case .paragraph(let text):
            paragraph(text)

        case .tiles(let codes, let caption):
            VStack(alignment: .leading, spacing: 6) {
                tileRow(codes: codes)
                if let caption { paragraph(caption) }
            }

        case .tileGroups(let groups, let caption):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 20) {
                    ForEach(Array(groups.enumerated()), id: \.offset) { _, codes in
                        tileRow(codes: codes)
                    }
                }
                if let caption { paragraph(caption) }
            }

        case .fulouExample(let hand, let fulou, let caption):
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .bottom, spacing: 20) {
                    tileRow(codes: hand)
                    tileFulouRow(codes: fulou)
                }
                paragraph(caption)
            }

        case .pointSticks(let sticks):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(sticks.enumerated()), id: \.offset) { _, item in
                    Image(item.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                    paragraph(item.caption)
                }
            }
        }
    }

    private func tileRow(codes: [String]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(codes.enumerated()), id: \.offset) { _, code in
                PaiView(code)
            }
        }
    }

    private func tileFulouRow(codes: [String]) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(codes.enumerated()), id: \.offset) { index, code in
                if index == 0 {
                    PaiView(pai: {
                        var p = Pai(code)
                        p.revealed = true
                        p.rotated = true
                        return p
                    }())
                } else {
                    PaiView(code)
                }
            }
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(goldLight.opacity(0.9))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview(traits: .landscapeLeft) {
    HowToPlayCardView()
}

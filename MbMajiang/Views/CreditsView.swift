//
//  CreditsView.swift
//  MbMajiang
//

import SwiftUI

/// アプリの開発者情報・バージョン情報を表示するクレジット画面
struct CreditsView: View {
    @Binding var isPresented: Bool

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            // 遷移元の画面（同じビュー階層内の背後のコンテンツ）をぼかして見せる
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("レッツ麻雀")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(goldLight)
                            Text("Version \(appVersion)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(goldLight.opacity(0.6))
                        }
                        .padding(.top, 12)

                        creditSection("開発", items: [
                            ("開発者", "（開発者名を入力してください）")
                        ])

                        creditSection("使用BGM", items: [
                            ("打ち上げ花火 / 幕末舞曲〜戦〜", "甘茶の音楽工房"),
                            ("旅館・宿っぽい曲 他", "もみじばミュージック"),
                        ])

                        creditSection("使用ボイス", items: [
                            ("ずんだもん", "VOICEVOX")
                        ])

                        Text("プレイいただきありがとうございます。")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(goldLight.opacity(0.75))
                            .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        ZStack {
            Text("クレジット")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(goldLight)
                .shadow(color: .black.opacity(0.9), radius: 2)
                .frame(maxWidth: .infinity)

            HStack {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isPresented = false } }) {
                    Text("×")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 36)
    }

    private func creditSection(_ title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.6))
                .tracking(2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(goldLight.opacity(0.7))
                        Spacer()
                        Text(item.1)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(goldLight)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)

                    if index < items.count - 1 {
                        Divider().background(gold.opacity(0.2))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(gold.opacity(0.25), lineWidth: 1))
            )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview(traits: .landscapeLeft) {
    CreditsView(isPresented: .constant(true))
}

//
//  CreditsView.swift
//  MbMajiang
//

import SwiftUI
import UIKit

/// アプリの開発者情報・バージョン情報を表示するクレジット画面
struct CreditsView: View {
    @Binding var isPresented: Bool

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// 実行中のAppアイコン画像（Info.plistのCFBundleIconsから解決）
    private var appIcon: UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let last = files.last
        else { return nil }
        return UIImage(named: last)
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
                    VStack(spacing: 28) {
                        appHeader

                        creditSection("使用フォント", items: [
                            ("新レトロ丸ゴシック", "文字魚（Typographish）"),
                        ])

                        creditSection("使用BGM", items: [
                            ("ねこのさんぽみち", "みんなの創作支援サイトTスタ"),
                            ("嶺上開花", "みんなの創作支援サイトTスタ"),
                            ("和風のBGM", "みんなの創作支援サイトTスタ"),
                            ("神ノ声", "もみじば"),
                            ("追い風（Wuxia2）", "sei / PeriTune"),
                            ("疾風（Shenxian）", "sei / PeriTune"),
                        ])

                        creditSection("使用効果音", items: [
                            ("打牌音・牌選択音", "ノタの森"),
                        ])

                        creditSection("使用ボイス", items: [
                            ("ずんだもん", "VOICEVOX"),
                        ])

                        creditSection("牌デザイン", items: [
                            ("牌デザイン（表）", "ライムライト（majan.civillink.net）"),
                        ])

                        creditSection("開発", items: [
                            ("開発者", "Ryu Nakamura"),
                            ("アプリアイコン", "Mie Takeuchi"),
                            ("Webサイト", "ryu-nakamura.com"),
                        ])
                    }
                    .padding(20)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    /// アプリアイコン・名前・バージョンをまとめた見出しブロック
    private var appHeader: some View {
        VStack(spacing: 8) {
            if let appIcon {
                Image(uiImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(gold.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("レッツ麻雀")
                    .font(.custom("ShinRetroMaruGothic-Bold", size: 20))
                    .foregroundStyle(.white)
                Text("Version \(appVersion)")
                    .font(.custom("ShinRetroMaruGothic-Bold", size: 20))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private var header: some View {
        ZStack {
            Text("クレジット")
                .font(.custom("ShinRetroMaruGothic-Bold", size: 16))
                .foregroundStyle(.white)
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
        .padding(.bottom, 12)
    }

    private func creditSection(_ title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("ShinRetroMaruGothic-Bold", size: 12))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top) {
                        Text(item.0)
                            .font(.custom("ShinRetroMaruGothic-Bold", size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 12)
                        Text(item.1)
                            .font(.custom("ShinRetroMaruGothic-Bold", size: 12))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
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

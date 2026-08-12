//
//  ShopView.swift
//  MbMajiang
//

import SwiftUI
import StoreKit

/// 課金コンテンツ（詳細設定・ボーダーテーマ）の購入・復元を行う画面
struct ShopView: View {
    @Binding var isPresented: Bool
    @State private var store = StoreManager.shared
    @State private var purchasingID: String?

    /// 呼び出し元で「この機能がロックされています」と伝えるための見出し（任意）
    var contextMessage: String? = nil

    private let gold      = Color(red: 0.82, green: 0.68, blue: 0.25)
    private let goldLight = Color(red: 0.97, green: 0.93, blue: 0.83)

    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            // 遷移元の画面（同じビュー階層内の背後のコンテンツ）をぼかして見せる
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if let contextMessage {
                    Text(contextMessage)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(goldLight.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        if store.isLoading && store.products.isEmpty {
                            ProgressView()
                                .tint(goldLight)
                                .padding(.top, 40)
                        } else if !purchasableProducts.isEmpty {
                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                ForEach(purchasableProducts, id: \.id) { product in
                                    productCard(product)
                                }
                            }
                        }
                    }
                    .padding(20)
                }

                if let message = store.lastErrorMessage {
                    Text(message)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.85))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }

                restoreButton
                    .padding(.bottom, 20)
            }
        }
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
            await store.updatePurchasedProducts()
        }
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        ZStack {
            Text("追加コンテンツ")
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

    /// 「全部アンロック」を除いた、個別に購入できる商品（一旦バンドル販売は行わない）
    private var purchasableProducts: [Product] {
        store.products.filter { $0.id != StoreManager.ProductID.allUnlock.rawValue }
    }

    /// 個別商品カード。上部にテーマカラーの背景付きプレビュー、下部に商品情報とボタンを縦に並べる
    private func productCard(_ product: Product) -> some View {
        let owned = store.purchasedProductIDs.contains(product.id)
        return VStack(alignment: .leading, spacing: 0) {
            ZStack {
                cardBackground(for: product.id)
                productPreview(product)
                    .scaleEffect(1.4)
            }
            .frame(height: 74)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(product.displayName)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(goldLight)
                        .lineLimit(1)
                    Spacer()
                    Text(product.displayPrice)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(gold)
                }
                Text(product.description)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(goldLight.opacity(0.65))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 24, alignment: .top)

                purchaseButton(product, owned: owned, prominent: false)
            }
            .padding(10)
        }
        .background(Color.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(gold.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }

    /// 商品ごとの世界観が伝わるよう、プレビュー背後に敷くテーマカラーのグラデーション
    @ViewBuilder
    private func cardBackground(for productID: String) -> some View {
        switch StoreManager.ProductID(rawValue: productID) {
        case .detailedColors:
            LinearGradient(colors: [Color(red: 0.55, green: 0.15, blue: 0.55), Color(red: 0.15, green: 0.45, blue: 0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
        case .borderTheme:
            LinearGradient(colors: [Color(red: 0.12, green: 0.1, blue: 0.08), Color(red: 0.55, green: 0.46, blue: 0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
        case .canvasTheme:
            LinearGradient(colors: [Color(red: 0.82, green: 0.75, blue: 0.58), Color(red: 0.6, green: 0.5, blue: 0.36)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
        case .allUnlock, .none:
            LinearGradient(colors: [gold.opacity(0.4), Color.black.opacity(0.25)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func purchaseButton(_ product: Product, owned: Bool, prominent: Bool) -> some View {
        let isPurchasing = purchasingID == product.id
        let buttonText: String = owned ? "購入済み" : (prominent ? "購入して解放する" : "購入する")
        let buttonBackground: Color = owned ? Color.gray.opacity(0.4) : gold.opacity(0.9)
        let buttonForeground: Color = owned ? .white.opacity(0.7) : .black

        return Button {
            Task {
                purchasingID = product.id
                await store.purchase(product)
                purchasingID = nil
            }
        } label: {
            HStack {
                Spacer()
                if isPurchasing {
                    ProgressView().tint(.black)
                } else {
                    Text(buttonText)
                        .font(.system(size: prominent ? 14 : 11, weight: .bold, design: .monospaced))
                }
                Spacer()
            }
            .padding(.vertical, prominent ? 10 : 6)
            .background(buttonBackground)
            .foregroundStyle(buttonForeground)
            .clipShape(RoundedRectangle(cornerRadius: prominent ? 8 : 6))
        }
        .buttonStyle(.plain)
        .disabled(owned || purchasingID != nil)
        .shadow(color: owned ? .clear : gold.opacity(0.5), radius: prominent ? 8 : 5)
    }

    /// 何が手に入るかひと目で伝えるための、商品ごとのミニプレビュー
    @ViewBuilder
    private func productPreview(_ product: Product) -> some View {
        switch StoreManager.ProductID(rawValue: product.id) {
        case .borderTheme:
            borderPreviewCluster
        case .detailedColors:
            colorPreviewCluster
        case .canvasTheme:
            canvasPreview
        case .allUnlock:
            VStack(spacing: 4) {
                borderPreviewCluster
                colorPreviewCluster
            }
        case .none:
            EmptyView()
        }
    }

    /// キャンバステーマ（手書き機能）のイメージを伝えるための、簡単な手書き風イラストのプレビュー
    private var canvasPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.95, green: 0.92, blue: 0.82))
            Path { path in
                path.move(to: CGPoint(x: 8, y: 34))
                path.addCurve(to: CGPoint(x: 30, y: 10),
                               control1: CGPoint(x: 14, y: 6), control2: CGPoint(x: 20, y: 40))
                path.addCurve(to: CGPoint(x: 52, y: 30),
                               control1: CGPoint(x: 40, y: -8), control2: CGPoint(x: 46, y: 44))
            }
            .stroke(Color(red: 0.75, green: 0.2, blue: 0.2), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { path in
                path.move(to: CGPoint(x: 14, y: 28))
                path.addLine(to: CGPoint(x: 46, y: 18))
            }
            .stroke(Color(red: 0.2, green: 0.4, blue: 0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Circle()
                .fill(Color(red: 0.3, green: 0.55, blue: 0.3))
                .frame(width: 8, height: 8)
                .offset(x: 20, y: 12)
        }
        .frame(width: 56, height: 40)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(gold.opacity(0.5), lineWidth: 1))
    }

    private var borderPreviewCluster: some View {
        HStack(spacing: 3) {
            borderPreviewTile(.zebra)
            borderPreviewTile(.lesserPanda)
            borderPreviewTile(.manul)
        }
        .scaleEffect(1.3)
    }

    private func borderPreviewTile(_ scheme: GameSettings.TileBackColorScheme) -> some View {
        PaiView("z1", reveal: false)
            .environment(\.tileBackColor, .striped(count: scheme.count, color1: scheme.color1, color2: scheme.color2))
    }

    /// カスタムカラー（RGB自由選択）がどんな見た目になるか伝えるための、カラフルな配色の牌プレビュー
    private var colorPreviewCluster: some View {
        HStack(spacing: 2) {
            genericColorPreviewTile("m1")
            genericColorPreviewTile("p1")
            genericColorPreviewTile("s1")
            genericColorPreviewTile("z1")
        }
    }

    private func genericColorPreviewTile(_ code: String) -> some View {
        PaiView(code)
            .environment(\.genericTileColors, GameSettings.GenericTileColors(
                manzuDigit: Color(red: 0.85, green: 0.1, blue: 0.55),
                manzuWan:   Color(red: 0.95, green: 0.35, blue: 0.05),
                pinzuRed:   Color(red: 0.95, green: 0.35, blue: 0.05),
                pinzuGreen: Color(red: 0.05, green: 0.55, blue: 0.85),
                souzuRed:   Color(red: 0.9, green: 0.15, blue: 0.15),
                souzuGreen: Color(red: 0.15, green: 0.65, blue: 0.25),
                honorWind:  Color(red: 0.55, green: 0.15, blue: 0.85),
                honorHatsu: Color(red: 0.15, green: 0.65, blue: 0.25),
                honorChun:  Color(red: 0.9, green: 0.15, blue: 0.15),
                akaDora:    Color(red: 0.95, green: 0.35, blue: 0.05),
                souzuBirdAccent: Color(red: 0.05, green: 0.55, blue: 0.85)
            ))
    }

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("購入を復元する")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(goldLight.opacity(0.85))
                .underline()
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .landscapeLeft) {
    ShopView(isPresented: .constant(true))
}

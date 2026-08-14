import SwiftUI

struct TitleView: View {
    @Environment(GameSettings.self) private var settings
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var blinkOpacity: Double = 1.0
    @State private var showMenu: Bool = false
    @State private var isSettingsPresented = false
    @State private var isHowToPlayPresented = false
    @State private var startedGame: Game? = nil
    @State private var isGameEditPresented = false
    @State private var isMatchStatsPresented = false
    @State private var isShopPresented = false
    @State private var isCreditsPresented = false

    var body: some View {
        ZStack {
            // ① 背景画像
            Image("original/titleBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.15)
                .ignoresSafeArea()

            // ② メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                titleSection
                Spacer()
                startButton
                    .opacity(buttonOpacity)
                Spacer().frame(height: 60)
            }

            // ③ 追加コンテンツ（ショップ）・クレジットの動線
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        shopButton
                        creditsButton
                    }
                }
                Spacer()
            }
            .padding(.top, 64)
            .padding(.trailing, 24)
            .opacity(buttonOpacity)

            if isShopPresented {
                ShopView(isPresented: $isShopPresented)
                    .transition(.opacity)
            }

            if isMatchStatsPresented {
                MatchStatsView(isPresented: $isMatchStatsPresented)
                    .transition(.opacity)
            }

            if isCreditsPresented {
                CreditsView(isPresented: $isCreditsPresented)
                    .transition(.opacity)
            }

                }
        .onTapGesture {
            guard !isShopPresented, !isMatchStatsPresented, !isCreditsPresented else { return }
            if showMenu {
                withAnimation(.easeOut(duration: 0.2)) { showMenu = false }
            } else {
                withAnimation(.easeOut(duration: 0.25)) { showMenu = true }
            }
        }
        .onAppear { animateIn() }
        .fullScreenCover(isPresented: $isSettingsPresented) {
            GameSettingsView()
        }
        .fullScreenCover(isPresented: $isHowToPlayPresented) {
            HowToPlayView()
        }
        .fullScreenCover(item: $startedGame) { game in
            BoardView(game: game, debugActions: [], autoStart: false, showStartButton: true)
        }
        .fullScreenCover(isPresented: $isGameEditPresented) {
            GameEditView()
        }
        .transaction(value: isSettingsPresented) { transaction in
            transaction.disablesAnimations = true
        }
        .transaction(value: isHowToPlayPresented) { transaction in
            transaction.disablesAnimations = true
        }
        .transaction(value: isGameEditPresented) { transaction in
            transaction.disablesAnimations = true
        }
    }

    // MARK: - Shop Button
    private var shopButton: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isShopPresented = true } }) {
            Image(systemName: "cart.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 0.82, green: 0.68, blue: 0.25))
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color(red: 0.82, green: 0.68, blue: 0.25).opacity(0.6), lineWidth: 1)
                )
        }
    }

    // MARK: - Credits Button
    private var creditsButton: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isCreditsPresented = true } }) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 0.82, green: 0.68, blue: 0.25))
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color(red: 0.82, green: 0.68, blue: 0.25).opacity(0.6), lineWidth: 1)
                )
        }
    }

    private func menuButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.83))
                .frame(width: 140, height: 44)
                .background(Color(red: 0.08, green: 0.28, blue: 0.12).opacity(0.85))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.82, green: 0.68, blue: 0.25).opacity(0.9), lineWidth: 1.5)
                )
        }
    }
    
    
    // MARK: - Title Section
    var titleSection: some View {
        VStack(spacing: 16) {
            // ⑤ 装飾ライン（上）
            decorativeDivider
            
            // ⑥ サブタイトル（英語 or 読み）
            Text("LET'S MAHJONG")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.82, green: 0.68, blue: 0.25))
                .tracking(8)
                .shadow(color: Color.black.opacity(0.5), radius: 3)
                .opacity(subtitleOpacity)

            // ⑦ メインタイトル（大きく迫力ある）「レッツ」だけ文字間を詰める
            mainTitleText
                .font(.custom("ShinRetroMaruGothic-Bold", size: 108))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.93, blue: 0.83),
                            Color(red: 0.82, green: 0.68, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.05, green: 0.2, blue: 0.08).opacity(0.9), radius: 6, x: 2, y: 2)
                .shadow(color: Color(red: 0.05, green: 0.2, blue: 0.08).opacity(0.5), radius: 20)


            // ⑨ 装飾ライン（下）
            decorativeDivider
        }
        .padding(.horizontal, 60)
    }

    /// 「レッツ 麻雀」のタイトル文字。「レッツ」だけ文字間を詰める（AttributedStringを1つのTextにまとめる。Text + Textの結合は非推奨のため）
    private var mainTitleText: Text {
        var lets = AttributedString("レッツ")
        lets.tracking = -18
        let space = AttributedString(" ")
        let majiang = AttributedString("麻雀")
        return Text(lets + space + majiang)
    }

    // MARK: - Decorative Divider
    var decorativeDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(red: 0.82, green: 0.68, blue: 0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // 中央の菱形
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .foregroundColor(Color(red: 0.82, green: 0.68, blue: 0.25))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.82, green: 0.68, blue: 0.25), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .opacity(subtitleOpacity)
    }
    
    // MARK: - Touch To Start / Inline Menu
    var startButton: some View {
        ZStack {
            // TOUCH TO START テキスト
            Text("TOUCH TO START")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.82, green: 0.68, blue: 0.25))
                .shadow(color: Color.black.opacity(0.6), radius: 4)
                .tracking(4)
                .opacity(showMenu ? 0 : blinkOpacity)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: blinkOpacity
                )

            // インラインメニュー
            HStack(spacing: 12) {
                menuButton("CPU対局") {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        startedGame = Game(settings: settings)
                    }
                }
                menuButton("対局編集") { isGameEditPresented = true }
                menuButton("対局成績") { withAnimation(.easeInOut(duration: 0.2)) { isMatchStatsPresented = true } }
                menuButton("遊び方") { isHowToPlayPresented = true }
            }
            .opacity(showMenu ? 1 : 0)
            .animation(.easeOut(duration: 0.25), value: showMenu)
        }
    }
    
    // MARK: - Animation
    func animateIn() {
        SoundManager.shared.play("title")
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            subtitleOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            buttonOpacity = 1
        }
        // 点滅開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            blinkOpacity = 0.5
        }
    }
}

#Preview (traits: .landscapeLeft){
    TitleView()
        .environment(GameSettings())
}

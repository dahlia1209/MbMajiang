import SwiftUI

struct TitleView: View {
    @State private var game: Game = Game()
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -30
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0.4
    @State private var isGameStarted = false
    
    var body: some View {
        ZStack {
            // ① 背景グラデーション
            BackgroundLayer()
            
            // ② メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                
                // ③ タイトルロゴ
                titleSection
                
                Spacer()
                
                // ④ スタートボタン
                startButton
                    .opacity(buttonOpacity)
                
                Spacer().frame(height: 60)
            }
        }
        .onAppear { animateIn() }
        .fullScreenCover(isPresented: $isGameStarted) {
            BoardView(game: game, debugActions: [])
                }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
    
    
    // MARK: - Title Section
    var titleSection: some View {
        VStack(spacing: 16) {
            // ⑤ 装飾ライン（上）
            decorativeDivider
            
            // ⑥ サブタイトル（英語 or 読み）
            Text("MAJIANG")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.8, green: 0.6, blue: 0.2))
                .tracking(8)
                .opacity(subtitleOpacity)
            
            // ⑦ メインタイトル（大きく迫力ある）
            Text("麻雀")
                .font(.system(size: 96, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.92, blue: 0.6),
                            Color(red: 0.9, green: 0.7, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.1).opacity(0.8), radius: 20)
                .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.1).opacity(0.4), radius: 40)
                .opacity(titleOpacity)
                .offset(y: titleOffset)
            
   
            // ⑨ 装飾ライン（下）
            decorativeDivider
        }
        .padding(.horizontal, 60)
    }
    
    // MARK: - Decorative Divider
    var decorativeDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(red: 0.8, green: 0.6, blue: 0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            // 中央の菱形
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.2))
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.8, green: 0.6, blue: 0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .opacity(subtitleOpacity)
    }
    
    // MARK: - Start Button
    var startButton: some View {
        Button(action: {
            game = Game()
            isGameStarted = true
        }) {
            ZStack {
                // グロウ効果
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.8, green: 0.6, blue: 0.1).opacity(0.3))
                    .blur(radius: 12)
                    .opacity(glowOpacity)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: glowOpacity
                    )
                
                // ボタン本体
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.4),
                                Color(red: 0.7, green: 0.5, blue: 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.05))
                    )
                
                Text("START  ▶")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.92, blue: 0.6),
                                Color(red: 0.9, green: 0.7, blue: 0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(4)
            }
            .frame(width: 220, height: 54)
        }
    }
    
    // MARK: - Animation
    func animateIn() {
        withAnimation(.easeOut(duration: 0.8)) {
            titleOpacity = 1
            titleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            subtitleOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            buttonOpacity = 1
        }
        // グロウのパルス開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            glowOpacity = 0.8
        }
    }
}

#Preview (traits: .landscapeLeft){
    TitleView()
}

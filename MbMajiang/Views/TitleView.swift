import SwiftUI

struct TitleView: View {
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -30
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var blinkOpacity: Double = 1.0
    @State private var showMenu: Bool = false
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            // ① 背景画像
            Image("titleBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.25)
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

                }
        .onTapGesture {
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
        .transaction(value: isSettingsPresented) { transaction in
            transaction.disablesAnimations = true
        }
    }

    private func menuButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.83))
                .frame(width: 140, height: 44)
                .background(Color(red: 0.5, green: 0.04, blue: 0.1).opacity(0.75))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.75, green: 0.55, blue: 0.15).opacity(0.8), lineWidth: 1.5)
                )
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
                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.83))
                .tracking(8)
                .shadow(color: Color.black.opacity(0.6), radius: 4)
                .opacity(subtitleOpacity)

            // ⑦ メインタイトル（大きく迫力ある）
            Text("麻雀")
                .font(.system(size: 96, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.93, blue: 0.83),
                            Color(red: 0.75, green: 0.55, blue: 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.4, green: 0.0, blue: 0.05).opacity(0.9), radius: 6, x: 2, y: 2)
                .shadow(color: Color(red: 0.55, green: 0.05, blue: 0.1).opacity(0.5), radius: 20)
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
                        colors: [.clear, Color(red: 0.75, green: 0.55, blue: 0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // 中央の菱形
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .foregroundColor(Color(red: 0.75, green: 0.55, blue: 0.15))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.75, green: 0.55, blue: 0.15), .clear],
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
                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.83))
                .shadow(color: Color.black.opacity(0.7), radius: 4)
                .tracking(4)
                .opacity(showMenu ? 0 : blinkOpacity)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: blinkOpacity
                )

            // インラインメニュー
            HStack(spacing: 12) {
                menuButton("CPU戦") { isSettingsPresented = true }
                menuButton("ネット対戦") { }
                menuButton("設定") { }
            }
            .opacity(showMenu ? 1 : 0)
            .animation(.easeOut(duration: 0.25), value: showMenu)
        }
    }
    
    // MARK: - Animation
    func animateIn() {
        SoundManager.shared.play("title")
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

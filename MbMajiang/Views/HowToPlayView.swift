import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var game = Game()
    @State private var showQuitAlert = false

    var body: some View {
        ZStack {
            BackgroundLayer(imageName: game.settings.boardTheme.imageName)

            VStack {
                Spacer()
                ScoreBoardView(game.board.score, Wangpai(), game.board.shan.paishu,
                               lizhiPlayers: [false, false, false, false])
                Spacer()
            }
            .padding(.horizontal, 40)

            HeView(he: He())
                .offset(y: 100)
            HeView(he: He())
                .offset(y: 200)
                .rotationEffect(.degrees(270))
            HeView(he: He())
                .offset(y: 100)
                .rotationEffect(.degrees(180))
            HeView(he: He())
                .offset(y: 200)
                .rotationEffect(.degrees(90))

            ShoupaiView(shoupai: game.board.shan.shoupai[0], isTajia: true, scale: 1.5)
                .offset(y: 180)
            ShoupaiView(shoupai: game.board.shan.shoupai[1], isTajia: true)
                .offset(y: 300)
                .rotationEffect(.degrees(270))
            ShoupaiView(shoupai: game.board.shan.shoupai[2], isTajia: true)
                .offset(y: 160)
                .rotationEffect(.degrees(180))
            ShoupaiView(shoupai: game.board.shan.shoupai[3], isTajia: true)
                .offset(y: 290)
                .rotationEffect(.degrees(90))

            closeButton
        }
        .alert("遊び方を終了しますか？", isPresented: $showQuitAlert) {
            Button("終了", role: .destructive) { dismiss() }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Button(action: { showQuitAlert = true }) {
                    Text("×")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.leading, 12)
                .padding(.top, 12)
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HowToPlayView()
}

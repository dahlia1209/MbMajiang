import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameSettings.self) private var settings
    @State private var game = Game()
    @State private var startedGame: Game? = nil

    var body: some View {
        ZStack {
            BackgroundLayer(imageName: game.settings.effectiveBoardImageName, color: game.settings.boardBackgroundColor)

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

            HowToPlayCardView(showStartGameButton: true) {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    startedGame = Game(settings: settings)
                }
            }

            closeButton
        }
        .environment(\.tileBackColor, settings.effectiveTileBackAppearance)
        .fullScreenCover(item: $startedGame) { game in
            BoardView(game: game, debugActions: [], autoStart: false, showStartButton: true)
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
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
        .environment(GameSettings())
}

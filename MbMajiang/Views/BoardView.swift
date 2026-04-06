//
//  BoardView.swift
//  MbMajiang
//
//  Created by Ryu Nakamura on 2026/03/30.
//

import SwiftUI

struct BoardView: View {
    @State private var game: Game
    
    init(game: Game) {
            self._game = State(initialValue: game)
        }
        
    var body: some View {
        ZStack {
            BackgroundLayer()

            VStack {
                Spacer()
                ScoreBoardView(game.board.score,game.board.shan.wangpai,game.board.shan.shan.count)
                Spacer()
            }
            .padding(.horizontal, 40)
            
            
            ShoupaiView(shoupai: game.board.shan.shoupai[0])
                .offset(x:-40,y:170)
            HeView(he:game.board.shan.he[0])
                .scaleEffect(0.8)
                .offset(y:80)
            
            ShoupaiView(shoupai: game.board.shan.shoupai[1],isTajia: true)
                .offset(y:250)
            .rotationEffect(.degrees(270))
            HeView(he:game.board.shan.he[1])
                .scaleEffect(0.7)
                .offset(x:-60,y:150)
                .rotationEffect(.degrees(270))
            
            ShoupaiView(shoupai: game.board.shan.shoupai[2],isTajia: true)
            .offset(y:160)
            .rotationEffect(.degrees(180))
            HeView(he:game.board.shan.he[2])
                .scaleEffect(0.8)
                .offset(x:-40,y:80)
                .rotationEffect(.degrees(180))
            
            ShoupaiView(shoupai: game.board.shan.shoupai[3],isTajia: true)
            .offset(y:250)
            .rotationEffect(.degrees(90))
            HeView(he:game.board.shan.he[3])
                .scaleEffect(0.8)
                .offset(x:-60,y:150)
                .rotationEffect(.degrees(90))
            
            
        }
        .onAppear {
                    setupGame()
                }
    }
    
    func setupGame() {
            game.onAction = { [weak game] status in
                guard let game else { return }
                switch status.action {
                case .kaiju:
                    game.qipai()
                case .qipai:
                    game.zimo()
                case .zimo:
                    if status.player != 0 {
                        game.dapai()
                    }
                    // player == 0 はユーザー操作待ち
                case .dapai:
                    game.zimo()
                default:
                    break
                }
            }
            game.start()  
        }
}



#Preview(traits: .landscapeLeft) {
    BoardView(game:Game()
    )
}

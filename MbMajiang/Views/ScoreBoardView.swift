//
//  ScoreBoardView.swift
//  MbMajiang
//

import SwiftUI

struct ScoreBoardView: View {
    var score:Score
    var wangpai:Wangpai
    var paishu: Int
    var lizhiPlayers: [Bool] = [false, false, false, false]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10){
                // ① 局情報
                roundInfoSection
                // ② ドラ・牌数
                doraSection
            }
            .fixedSize()
            // ③ 点数
            scoreSection
        }
        .fixedSize()
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black)
    }
    
    // MARK: - Round Info
    var roundInfoSection: some View {
        HStack {
            Text(score.round.rawValue)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 0.9, green: 0.78, blue: 0.28))
                .tracking(2)
            
            VStack(spacing: 4) {
                Text("本場　\(score.honba)")
                Text("供託　\(score.lizhibang)")
            }
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Dora Section
    var doraSection: some View {
        VStack(spacing: 8) {
            WangpaiView(wangpai: wangpai)
            Text("残り　\(self.paishu)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Score Section
    var scoreSection: some View {
        ZStack {
            scoreLabel(playerIdx: 0).offset(y: 20)
            scoreLabel(playerIdx: 1).offset(x: 80)
            scoreLabel(playerIdx: 2).offset(y: -15)
            scoreLabel(playerIdx: 3).offset(x: -80)
        }
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(.white.opacity(0.7))
        .frame(maxWidth: .infinity)
        .frame(height: 60)
    }

    private func scoreLabel(playerIdx: Int) -> some View {
        let isLizhi = lizhiPlayers.indices.contains(playerIdx) && lizhiPlayers[playerIdx]
        let feng = score.defen[playerIdx].0.label
        let pts  = score.defen[playerIdx].1
        return VStack(spacing: 2) {
            if isLizhi {
                Image("1000")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 6)
            }
//            Image("1000")
//                .resizable()
//                .scaledToFit()
//                .frame(height: 6)
            Text("\(feng)　\(pts)")
                .foregroundColor(playerIdx == 0
                    ? Color(red: 0.9, green: 0.78, blue: 0.28)
                    : .white.opacity(0.7))
            
            
            
        }
    }
}

extension ScoreBoardView {
    init(_ score: Score, _ wangpai: Wangpai, _ paishu: Int, lizhiPlayers: [Bool] = [false, false, false, false]) {
        self.score = score
        self.wangpai = wangpai
        self.paishu = paishu
        self.lizhiPlayers = lizhiPlayers
    }
}


#Preview(traits: .landscapeLeft) {
    ScoreBoardView(
        Score(
            round: .南一局,
            honba: 1,
            lizhibang: 1,
            defen: [
                ( .東 , 25000),
                (.南, 25000),
                (.西, 25000),
                (.北, 25000)
            ]
        ),
        Wangpai(baopai: [Pai("p1")]),
        70
    )
}

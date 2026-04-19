//
//  ScoreBoardView.swift
//  MbMajiang
//

import SwiftUI

struct ScoreBoardView: View {
    var score:Score
    var wangpai:Wangpai
    var paishu: Int
    
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
            Text("\(score.defen[0].0.label)　\(score.defen[0].1, specifier: "%d")")
                .offset(y: 20)
                .foregroundColor(Color(red: 0.9, green: 0.78, blue: 0.28))
            
            Text("\(score.defen[1].0.label)　\(score.defen[1].1, specifier: "%d")")
                .offset(x: 60)
            
            Text("\(score.defen[2].0.label)　\(score.defen[2].1, specifier: "%d")")
                .offset(y: -20)
            
            Text("\(score.defen[3].0.label)　\(score.defen[3].1, specifier: "%d")")
                .offset(x: -60)
        }
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(.white.opacity(0.7))
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
}

extension ScoreBoardView {
    init(_ score: Score, _ wangpai:Wangpai, _ paishu:Int)  {
        self.score = score
        self.wangpai=wangpai
        self.paishu=paishu
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

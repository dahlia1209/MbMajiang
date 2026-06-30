import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let chapterTitles: [String] = [
        "麻雀は手役を作るゲーム",
        "リーチが成立する条件",
        "リーチの成立条件①：テンパイとは？",
        "補足1：面子と雀頭について",
        "補足2：刻子と順子について",
        "補足3：数牌と字牌について",
        "補足4：テンパイの例",
        "リーチの成立条件②：メンゼンとは？",
        "リーチの成立条件③：リーチ宣言とは？",
        "リーチの成立条件④：和了とは？",
        "まとめ"
    ]

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color(red: 0.05, green: 0.18, blue: 0.08).ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("麻雀の遊び方")
                                tocView(proxy: proxy)
                            }
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("麻雀は手役を作るゲーム")
                                paragraph("麻雀は136枚ある麻雀牌から14枚の麻雀牌を使って手役を揃えるゲームです。")
                                paragraph("麻雀の手役は30以上ありますが、その中で最も有名な手役が「リーチ」です。リーチ以外にも手役には「断么九（タンヤオ）」や「平和（ピンフ）」などたくさんありますが、まずは麻雀の基本であるリーチから覚えることを推奨します。リーチは麻雀の手役だけでなく、麻雀の基本的なルールが含まれており、リーチを知ることが麻雀のルールを知ることになるからです。ただ、リーチは基本の役でありながら、条件が複雑なので一つずつ理解する必要があります。")
                                HStack(spacing: 20) {
                                    tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","z1","z1","z1","z2","z2"])
                                    
                                    tileRow( codes: ["s9"])
                                }
                                paragraph("▲リーチの手役が成立する時の手牌14枚の例")
                                HStack(spacing: 20) {
                                    tileRow( codes: ["m2","m3","m4","p3","p4","p5","s4","s5","s6","s7","s7","s8","s8"])
                                    
                                    tileRow( codes: ["s8"])
                                }
                                paragraph("▲断么九（タンヤオ）の手役が成立する時の手牌14枚の例")
                                HStack(spacing: 20) {
                                    tileRow( codes: ["m1","m1","m2","m3","m4","m5","m6","m7","p7","p8","p9","s7","s8"])
                                    
                                    tileRow( codes: ["s9"])
                                }
                                paragraph("▲平和（ピンフ）の手役が成立する時の手牌14枚の例")
                                
                                
                            }
                            .id("麻雀は手役を作るゲーム")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("リーチが成立する条件")
                                paragraph("リーチの手役を作るには手牌（麻雀牌の手札）が「テンパイ」かつ「メンゼン」のときにリーチを宣言し、リーチ宣言後に「和了（ホーラ）」をすると成立します。")
                                paragraph("次の章以降で詳しい説明をしていきます。")
                            }
                            .id("リーチが成立する条件")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("リーチの成立条件①：テンパイとは？")
                                paragraph("まずは「テンパイ」についてですが、テンパイというのは13枚の手牌に1枚を加えて「4面子（メンツ）1雀頭（ジャントウ）」の形になるときの13枚の手牌を指します。")
                                tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","z1","z1","z1","z2","z2"])
                                paragraph("▲テンパイの例①：3面子1雀頭+2枚の形のテンパイ")
                                tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2"])
                                paragraph("▲テンパイの例②：4面子0雀頭+1枚の形のテンパイ")
                            }
                            .id("リーチの成立条件①：テンパイとは？")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("補足1：面子と雀頭について")
                                paragraph("「4面子（メンツ）1雀頭（ジャントウ）」の「面子（メンツ）」というのは同じ牌3枚を組み合わせた「刻子（コーツ）」または連続した数牌3枚を組み合わせた「順子（シュンツ）」を指します。また、「雀頭（ジャントウ）」は同じ牌が2枚の組み合わせです。4面子1雀頭というのは3枚の面子が4つと2枚の雀頭が1つで合計14枚ある形になります。")
                                tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2","z2"])
                                paragraph("▲4面子1雀頭の例①：４面子は3つの順子と1つの刻子で構成")
                                tileRow( codes: ["m1","m1","m1","p4","p4","p4","s9","s9","s9","z5","z5","z5","z6","z6"])
                                paragraph("▲4面子1雀頭の例②：４面子は全て刻子で構成")
                            }
                            .id("補足1：面子と雀頭について")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("補足2：刻子と順子について")
                                paragraph("「刻子（コーツ）」と「順子（シュンツ）」についてもう少し詳しく説明します。")
                                paragraph("「刻子（コーツ）」は同じ牌が3枚の組み合わせです。")
                                HStack(spacing: 20) {
                                    tileRow( codes: ["m1","m1","m1"])
                                    tileRow( codes: ["p4","p4","p4"])
                                    tileRow( codes: ["s7","s7","s7"])
                                    tileRow( codes: ["z1","z1","z1"])
                                }
                                paragraph("▲「刻子（コーツ）」の例。萬子の1の刻子、筒子の4の刻子、索子の7の刻子、字牌の東の刻子")
                                paragraph("「順子（シュンツ）」は連続した「数牌（スウパイ）」が3枚の組み合わせです。麻雀牌は「数牌（スウパイ）」と「字牌（ジハイ）」に分けられますが、順子は「数牌（スウパイ）」で作る必要があります。「数牌（スウパイ）」と「字牌（ジハイ）」は次の章で説明します。")
                                HStack(spacing: 20) {
                                    tileRow( codes: ["m1","m2","m3"])
                                    tileRow( codes: ["p4","p5","p6"])
                                    tileRow( codes: ["s7","s8","s9"])
                                }
                                paragraph("▲「順子（シュンツ）」の例。萬子の123の順子、筒子の456の順子、索子の789の順子")
                            }
                            .id("補足2：刻子と順子について")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("補足3：数牌と字牌について")
                                paragraph("麻雀牌は136枚あるということでしたが、136枚の内訳は34種類の麻雀牌がそれぞれ4枚あって、34×4で合計136枚あります。34種類の麻雀牌はさらに「数牌（スウパイ）」と「字牌（ジハイ）」に分けられます。")
                                paragraph("「数牌（スウパイ）」には「萬子（マンズ）」「筒子（ピンズ）」「索子（ソーズ）」の3種類あり、それぞれ9枚（萬子の1~9、筒子の1~9、索子の1~9）あるので27種類存在します。トランプのダイヤ、クラブ、スペードのようなマークが3種類あるイメージです。")
                                tileRow( codes: ["m1","m2","m3","m4","m5","m6","m7","m8","m9"])
                                paragraph("▲「萬子（マンズ）」の1から9")
                                tileRow( codes: ["p1","p2","p3","p4","p5","p6","p7","p8","p9"])
                                paragraph("▲「筒子（ピンズ）」の1から9")
                                tileRow( codes: ["s1","s2","s3","s4","s5","s6","s7","s8","s9"])
                                paragraph("▲「索子（ソーズ）」の1から9")
                                paragraph("一方、「字牌（ジハイ）」は「東（トン）」「南（ナン）」「西（シャ）」「北（ペー）」「白（ハク）」「發（ハツ）」「中（チュン）」の7種類あります。")
                                tileRow( codes: ["z1","z2","z3","z4","z5","z6","z7"])
                                paragraph("▲「字牌（ジハイ）」の「東（トン）」「南（ナン）」「西（シャ）」「北（ペー）」「白（ハク）」「發（ハツ）」「中（チュン）」")
                                paragraph("3枚同じ「数牌（スウパイ）」または「字牌（ジハイ）」を集めると「刻子（コーツ）」になります。\n3枚連続した「数牌（スウパイ）」を集めると「順子（シュンツ）」になります。\n字牌で順子は作ることはできません。字牌は刻子のみ作ることができます。")
                                
                            }
                            .id("補足3：数牌と字牌について")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("補足4：テンパイの例")
                                paragraph("話はテンパイに戻り、テンパイは13枚の手牌に1枚を加えて「4面子（メンツ）1雀頭（ジャントウ）」になるときの13枚の手牌の形です。イメージするために「テンパイ」の例をあげて説明します。")
                                tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","z1","z1","z1","z2","z2"])
                                paragraph("▲テンパイの例①：3面子1雀頭+2枚の形のテンパイ")
                                paragraph("上記手牌は萬子の123で1面子、筒子の456で１面子、字牌の東3枚で１面子、字牌の南2枚で１雀頭で3面子1雀頭+索子の78の形のテンパイです。このテンパイに索子の6または9があると索子78と組み合わせて1面子が完成し、4面子1雀頭が完成します。")
                                paragraph("もう一つ次の「テンパイ」の例を確認しましょう")
                                tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z1","z1","z1","z2"])
                                paragraph("▲テンパイの例②：4面子0雀頭+1枚の形のテンパイ")
                                paragraph("上記手牌は萬子の123で1面子、筒子の456で１面子、索子の789で1面子、字牌の東3枚で 1面子で4面子0雀頭+字牌の南の形のテンパイです。このテンパイでは字牌の南が加わると4面子1雀頭が完成します。")
                                paragraph("まとめるとテンパイは手牌13枚に1枚を加えて4面子1雀頭が完成する時の手牌13枚の形です。")
                            }
                            .id("補足4：テンパイの例")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("リーチの成立条件②：メンゼンとは？")
                                paragraph("テンパイの次に、「メンゼン」についてです。「メンゼン」は「副露（フーロ）」をしていない手牌の状態です。「副露（フーロ）」は手牌の一部をプレイヤーに公開するアクションですが、ここでは副露の説明をいったん省略します。「副露（フーロ）」をしなければメンゼンは成立するということを頭の片隅に留めるだけで問題ないです。")
                                
                                HStack(spacing: 40) {
                                    tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","s9","z2"])
                                    
                                    tileFulouRow( codes: ["z1","z1","z1"])
                                }
                                paragraph("▲東を副露（フーロ）した手牌の例。副露すると横にした牌1枚と通常の牌2枚を公開する。\n　副露するとメンゼンでなくなり、リーチが成立しなくなる。")
                            }
                            .id("リーチの成立条件②：メンゼンとは？")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("リーチの成立条件③：リーチ宣言とは？")
                                paragraph("リーチ宣言は他プレイヤーに自身がリーチであること宣言するアクションです。次の3つの手順でリーチ宣言をすることができます。")
                                paragraph("1.「リーチ」と発声して、自分以外の3人のプレイヤーにリーチを宣言します。\n2.手牌14枚のうち1枚を河（カワ）に捨て、残りの13枚をテンパイの形にします。\n3.1000点棒を卓の中央に置く")
                                paragraph("次の手牌14枚でリーチ宣言するときの手順を説明します。")
                                tileRow( codes: ["m1","m2","m3","m7","m8","m9","p4","p5","p6","s7","s8","z1","z1","z2"])
                                paragraph("上記手牌は字牌の南を除くとテンパイの形になる14枚の手牌です。リーチ宣言する時は「リーチ」と発声して他のプレイヤーにリーチを宣言します。他のプレイヤーというのは、麻雀は4人で対局するゲームなので、自分以外の他３人に対してリーチを宣言する必要があります。")
                                paragraph("リーチ発声後は14枚の手牌から南を「河（カワ）」に捨てます。「河（カワ）」というのは手牌を捨てるエリアで、各プレイヤーに存在するエリアです。南を河に捨てると、残り13枚の手牌がテンパイになります")
                                paragraph("「河（カワ）」に南を捨てた後は1000点棒を取り出して、卓の中央に1000点棒を置きます。点棒というのは細長い棒で麻雀の通貨のような役割です。点棒には100点棒、1000点棒、5000点棒、10000点棒があり、リーチするときは1000点棒を麻雀卓の中央に置きます。これでリーチ宣言をしたことになります。")
                                VStack(alignment: .leading, spacing: 8) {
                                    Image("100")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 20)
                                    paragraph("▲100点棒")
                                    Image("1000")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 20)
                                    paragraph("▲1000点棒")
                                }
                            }
                            .id("リーチの成立条件③：リーチ宣言とは？")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("リーチの成立条件④：和了とは？")
                                paragraph("「和了（ホーラ）」は手牌が4面子1雀頭の形で完成したことを宣言するアクションです。「アガリ」とも呼ばれます。「和了（ホーラ）」をしたプレイヤーが麻雀での勝者となります。")
                                paragraph("「和了（ホーラ）」には「ツモ」と「ロン」の2種類があります。それぞれ手順は次のとおりです。")
                                paragraph("＜ツモの手順＞\n1.牌山（ハイヤマ）から1枚牌を引き、手牌14枚で4面子1雀頭を完成させる。\n2.「ツモ」と発声して他プレイヤーに和了したことを宣言する。")
                                paragraph("＜ロンの手順＞\n1.自身の手牌13枚に、他プレイヤーが手牌から河に捨てた牌1枚を加えた14枚で4面子1雀頭を完成させる。\n2.「ロン」と発声して他プレイヤーに和了したことを宣言する")
                                paragraph("「ツモ」と「ロン」はどちらとも4面子1雀頭を完成させる必要があり、自身の手牌14枚で完成させるとツモになり、他プレイヤーの捨てた牌で完成させるとロンになります。リーチ宣言をした後に和了をするためには、手牌13枚がテンパイなので、4面子1雀頭の完成に必要な1枚を自身で牌山から引いてツモを宣言するか、他プレイヤーが捨てた牌でロンを宣言する必要があります。")
                                paragraph("「和了」をするときの例になります。")
                                tileRow( codes: ["m1","m2","m3","p4","p5","p6","s7","s8","z1","z1","z1","z2","z2"])
                                paragraph("上記手牌では索子の6か9を加えると4面子1雀頭が完成するので、和了するには索子の6か9を自身で牌山から引いて「ツモ」をするか、他プレイヤーが索子の6か9を河に捨てたときに「ロン」をします。")
                                paragraph("和了をするとようやくリーチの手役が完成し、麻雀での勝利となります。和了後は手役に応じて点数の計算をします。手役は30以上存在し、条件を満たしていれば手役は複合します。たとえばリーチとタンヤオ、リーチとピンフ、あるいはリーチ・ピンフ・タンヤオの複合なども存在します。また、手役には難易度が存在し、難易度が高い手役ほど点数が高くなります。リーチは最も難易度が低く、最も出現率が高い手役の一つです。一方、最も難易度が高い手役は役満とも呼ばれており、まれにお目にかかれるようなレアな手役です。どの手役を目指すのかはプレイヤーによって好みが分かれますが、リーチは最も基本的な手役の1つですので、まずはリーチの手役を作ることを推奨いたします。")
                                
                            }
                            .id("リーチの成立条件④：和了とは？")
                            .padding(.bottom, 48)

                            VStack(alignment: .leading, spacing: 24) {
                                chapterGeneralHeader("まとめ")
                                paragraph("ここまでのおさらいをすると、麻雀は136枚ある麻雀牌から14枚の麻雀牌を使って手役を揃えるゲームです。手役は30以上あって、その中でもリーチは最も基本的な手役です。リーチは手牌がテンパイかつメンゼンのときにリーチを宣言し、リーチ宣言後に和了（ホーラ）をすると成立します。最初は手牌がテンパイなのか、リーチ宣言できるのか、リーチ宣言後はいつ和了ができるのか、それぞれ判断するのが難しいですが、何回も練習することでできるようになりますので一つ一つ理解して地道に身につけていきましょう。")
                            }
                            .id("まとめ")
                            .padding(.bottom, 48)
                        }
                        .padding(.horizontal, 48)
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                closeButton
            }
        }
    }

    private func tocView(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(chapterTitles.enumerated()), id: \.offset) { index, title in
                Button(action: {
                    withAnimation { proxy.scrollTo(title, anchor: .top) }
                }) {
                    Text("\(index + 1).  \(title)")
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.93, green: 0.90, blue: 0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func chapterGeneralHeader(_ chapter: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chapter)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 0.97, green: 0.93, blue: 0.83), Color(red: 0.82, green: 0.68, blue: 0.25)],
                    startPoint: .top, endPoint: .bottom))
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.82, green: 0.68, blue: 0.25), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
    }
    
    // MARK: - Chapter Contents

    private func tileRow(codes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ForEach(Array(codes.enumerated()), id: \.offset) { _, code in
                    PaiView(code)
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private func tileFulouRow(codes: [String]) -> some View {
        HStack(alignment: .bottom,spacing: 10) {
            ForEach(Array(codes.enumerated()), id: \.offset) { index, code in
                if index == 0 {
                    PaiView(pai: {
                        var p = Pai(code)
                        p.revealed = true
                        p.rotated = true
                        return p
                    }())
                    .scaleEffect(1.5)
                } else {
                    PaiView(code)
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    
    // MARK: - Text & Layout Helpers
    
    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(Color(red: 0.93, green: 0.90, blue: 0.82))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.97, green: 0.93, blue: 0.83))
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.08, green: 0.28, blue: 0.12).opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 0.82, green: 0.68, blue: 0.25).opacity(0.7), lineWidth: 1.5))
                }
                .padding(16)
            }
            Spacer()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HowToPlayView()
}

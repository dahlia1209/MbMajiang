import SwiftUI

struct RoundCutInView: View {
    let roundImageNames: [String]
    let honbaImageNames: [String]
    let onFinished: () -> Void

    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(roundImageNames, id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                }
            }
            if !honbaImageNames.isEmpty {
                HStack(spacing: 0) {
                    ForEach(honbaImageNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    }
                }
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { opacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.4)) { opacity = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { onFinished() }
        }
    }
}

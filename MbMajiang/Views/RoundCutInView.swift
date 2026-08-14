import SwiftUI

struct RoundCutInView: View {
    let roundText: String
    let honbaText: String
    let onFinished: () -> Void

    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 4) {
            OshidashiText(text: roundText, size: 64)
            if !honbaText.isEmpty {
                OshidashiText(text: honbaText, size: 44)
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

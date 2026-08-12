import SwiftUI

struct PingjuCutInView: View {
    let onFinished: () -> Void

    @State private var opacity: Double = 0.0

    var body: some View {
        Image("original/pingju")
            .resizable()
            .scaledToFit()
            .frame(height: 120)
            .opacity(opacity)
            .onAppear {
                SoundManager.shared.play("pingju")
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    onFinished()
                }
            }
    }
}

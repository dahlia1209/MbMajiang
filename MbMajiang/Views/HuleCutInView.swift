import SwiftUI

struct HuleCutInView: View {
    let text: String
    let onFinished: () -> Void

    @State private var opacity: Double = 1.0

    var body: some View {
        OshidashiText(text: text, size: 90)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 0.3)) { opacity = 0 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { onFinished() }
            }
    }
}

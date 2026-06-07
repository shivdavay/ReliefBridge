import SwiftUI

/// Animated gradient title treatment used across the non-map experiences.
struct GlowText: View {
    let text: String
    let font: Font
    var glowColor: Color = Theme.Colors.aqua

    @State private var animateGradient = false

    var body: some View {
        ZStack {
            Text(text)
                .font(font)
                .foregroundColor(Color.white.opacity(0.12))

            LinearGradient(
                colors: [
                    Theme.Colors.gold,
                    Color.white.opacity(0.95),
                    Theme.Colors.aqua,
                    Theme.Colors.electricBlue
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .scaleEffect(1.65)
            .rotationEffect(.degrees(animateGradient ? 8 : -8))
            .offset(x: animateGradient ? 36 : -36)
            .mask(
                Text(text)
                    .font(font)
            )

            Text(text)
                .font(font)
                .foregroundColor(.white.opacity(0.07))
                .blur(radius: 12)
        }
        .shadow(color: glowColor.opacity(0.32), radius: 18, x: 0, y: 0)
        .fixedSize(horizontal: false, vertical: true)
        .drawingGroup()
        .onAppear {
            guard !animateGradient else { return }
            withAnimation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

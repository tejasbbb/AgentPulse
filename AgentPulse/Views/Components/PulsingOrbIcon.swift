import SwiftUI

struct PulsingOrbIcon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let badgeCount: Int

    @State private var animate = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xE8A84C), Color(hex: 0xC4782E)],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 1,
                        endRadius: 10
                    )
                )
                .frame(width: 14, height: 14)
                .scaleEffect(reduceMotion ? 1 : (animate ? 1.09 : 1.0))
                .shadow(color: Color(hex: 0xE8A84C).opacity(0.45), radius: animate ? 6 : 4)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animate)
                .onAppear { animate = true }

            if badgeCount > 0 {
                Text("\(min(badgeCount, 9))")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 11, height: 11)
                    .background(Color(hex: 0xE07A5F))
                    .clipShape(Circle())
                    .offset(x: 4, y: -3)
            }
        }
    }
}

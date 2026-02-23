import SwiftUI

struct OrbitalRingView: View {
    let agent: UnifiedAgent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: max(0.02, min(agent.progress, 1)))
                        .stroke(agent.accent.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)

                    Text("\(Int(agent.progress * 100))")
                        .font(.custom("JetBrains Mono", size: 10).weight(.semibold))
                        .foregroundColor(Color(hex: 0xF5F0E8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.custom("DM Sans", size: 12).weight(.semibold))
                        .foregroundColor(Color(hex: 0xF5F0E8))
                        .lineLimit(1)

                    Text(agent.model)
                        .font(.custom("JetBrains Mono", size: 9))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            Text(agent.currentTask ?? "Idle")
                .font(.custom("DM Sans", size: 11))
                .foregroundColor(Color.white.opacity(0.6))
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0x2C2A27))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

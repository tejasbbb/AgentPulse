import SwiftUI

struct OrbitalRingView: View {
    let agent: UnifiedAgent

    private var progressColor: Color { agent.accent.color }

    private var glowColor: Color {
        switch agent.accent {
        case .amber: return Color(hex: 0xE8A84C, alpha: 0.15)
        case .mint: return Color(hex: 0x7ECBA1, alpha: 0.12)
        case .coral: return Color(hex: 0xE07A5F, alpha: 0.12)
        case .slateBlue: return Color(hex: 0x8B9FC7, alpha: 0.12)
        }
    }

    private var sourceBadgeColor: Color {
        agent.source == .codex ? Color(hex: 0x8B9FC7) : Color(hex: 0xE8A84C)
    }

    private var sourceBadgeBg: Color {
        agent.source == .codex
            ? Color(hex: 0x8B9FC7, alpha: 0.12)
            : Color(hex: 0xE8A84C, alpha: 0.08)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Orbital ring
            ZStack {
                Circle()
                    .stroke(Color(hex: 0xFFF5E6, alpha: 0.06), lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: max(0.02, min(agent.progress, 1)))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)
                    .shadow(color: glowColor, radius: 4)

                Text("\(Int(agent.progress * 100))%")
                    .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            // Info stack
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(agent.name)
                        .font(.custom("DM Sans", size: 12).weight(.medium))
                        .foregroundColor(Color(hex: 0xF5F0E8))
                        .lineLimit(1)
                        .tracking(-0.2)

                    Text(agent.source == .codex ? "CODEX" : "CLAUDE")
                        .font(.custom("DM Sans", size: 8).weight(.semibold))
                        .foregroundColor(sourceBadgeColor)
                        .tracking(0.5)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(sourceBadgeBg)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .padding(.bottom, 2)

                Text(agent.currentTask ?? "Idle")
                    .font(.custom("DM Sans", size: 10))
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineLimit(2)
                    .lineSpacing(1.35)
                    .padding(.top, 3)

                Text(agent.model)
                    .font(.custom("JetBrains Mono", size: 9).weight(.light))
                    .foregroundColor(Color.white.opacity(0.15))
                    .lineLimit(1)
                    .tracking(0.3)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0x2C2A27))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xFFF5E6, alpha: 0.06), lineWidth: 1)
        )
    }
}

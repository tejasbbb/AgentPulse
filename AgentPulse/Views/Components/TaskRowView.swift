import SwiftUI

struct TaskRowView: View {
    let task: UnifiedTask
    var isLast: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinAngle: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                statusIcon

                VStack(alignment: .leading, spacing: 1) {
                    Text(task.subject)
                        .font(.custom("DM Sans", size: 12).weight(.regular))
                        .foregroundColor(task.status == .completed ? Color.white.opacity(0.3) : Color(hex: 0xF5F0E8))
                        .lineLimit(1)
                        .tracking(-0.1)

                    if let owner = task.owner {
                        Text(owner)
                            .font(.custom("JetBrains Mono", size: 9).weight(.light))
                            .foregroundColor(Color.white.opacity(0.15))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 7)

            if !isLast {
                Rectangle()
                    .fill(Color(hex: 0xFFF5E6, alpha: 0.03))
                    .frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .inProgress:
            ZStack {
                Circle()
                    .stroke(Color(hex: 0xE8A84C), lineWidth: 2)
                    .frame(width: 18, height: 18)

                Circle()
                    .fill(Color(hex: 0xE8A84C))
                    .frame(width: 4, height: 4)
            }
            .rotationEffect(.degrees(spinAngle))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            }

        case .pending:
            Circle()
                .strokeBorder(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: 18, height: 18)

        case .completed:
            ZStack {
                Circle()
                    .fill(Color(hex: 0x7ECBA1, alpha: 0.12))
                    .frame(width: 18, height: 18)

                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color(hex: 0x7ECBA1))
            }
        }
    }
}

import SwiftUI

struct SegmentedProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tasks: [UnifiedTask]

    var body: some View {
        HStack(spacing: 4) {
            if tasks.isEmpty {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 8)
            } else {
                ForEach(tasks, id: \.id) { task in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: task.status))
                        .frame(height: 8)
                        .opacity(task.status == .inProgress && !reduceMotion ? 0.85 : 1)
                }
            }
        }
    }

    private func color(for status: TaskStatus) -> Color {
        switch status {
        case .completed:
            return Color(hex: 0x7ECBA1)
        case .inProgress:
            return Color(hex: 0xE8A84C)
        case .pending:
            return Color.white.opacity(0.25)
        }
    }
}

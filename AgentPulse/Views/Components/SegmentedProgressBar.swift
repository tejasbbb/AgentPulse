import SwiftUI

struct SegmentedProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tasks: [UnifiedTask]

    @State private var runningOpacity: Double = 0.9

    var body: some View {
        HStack(spacing: 3) {
            if tasks.isEmpty {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: 0xFFF5E6, alpha: 0.06))
                    .frame(height: 4)
            } else {
                ForEach(tasks, id: \.id) { task in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: task.status))
                        .frame(height: 4)
                        .opacity(opacity(for: task.status))
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                runningOpacity = 0.4
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
            return Color(hex: 0xFFF5E6, alpha: 0.06)
        }
    }

    private func opacity(for status: TaskStatus) -> Double {
        switch status {
        case .completed: return 0.7
        case .inProgress: return runningOpacity
        case .pending: return 1
        }
    }
}

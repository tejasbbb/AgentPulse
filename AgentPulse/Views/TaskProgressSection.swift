import SwiftUI

struct TaskProgressSection: View {
    @EnvironmentObject var vm: AgentPulseViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var runningDotOpacity: Double = 1.0

    private var completedCount: Int {
        vm.tasks.filter { $0.status == .completed }.count
    }

    private var runningCount: Int {
        vm.tasks.filter { $0.status == .inProgress }.count
    }

    private var pendingCount: Int {
        vm.tasks.filter { $0.status == .pending }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with fraction and count dots
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TASKS")
                        .font(.custom("DM Sans", size: 10).weight(.medium))
                        .tracking(1.2)
                        .foregroundColor(Color.white.opacity(0.3))

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(completedCount)")
                            .font(.custom("Instrument Serif", size: 28))
                            .foregroundColor(Color(hex: 0xF5F0E8))
                            .tracking(-1)

                        Text("/\(max(vm.tasks.count, 1))")
                            .font(.custom("Instrument Serif", size: 16))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }

                Spacer()

                // Count indicators
                HStack(spacing: 12) {
                    countIndicator(
                        count: runningCount,
                        dotColor: Color(hex: 0xE8A84C),
                        textColor: Color(hex: 0xE8A84C),
                        pulsing: true
                    )
                    countIndicator(
                        count: pendingCount,
                        dotColor: Color.white.opacity(0.3),
                        textColor: Color.white.opacity(0.3),
                        pulsing: false
                    )
                    countIndicator(
                        count: completedCount,
                        dotColor: Color(hex: 0x7ECBA1),
                        textColor: Color(hex: 0x7ECBA1),
                        pulsing: false
                    )
                }
            }

            SegmentedProgressBar(tasks: vm.tasks)

            if vm.tasks.isEmpty {
                Text("No active tasks")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    let sortedTasks = vm.sortedTasks.prefix(5)
                    ForEach(Array(sortedTasks.enumerated()), id: \.element.id) { index, task in
                        TaskRowView(task: task, isLast: index == sortedTasks.count - 1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private func countIndicator(count: Int, dotColor: Color, textColor: Color, pulsing: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
                .shadow(color: pulsing ? Color(hex: 0xE8A84C, alpha: 0.15) : .clear, radius: pulsing ? 3 : 0)
                .opacity(pulsing ? runningDotOpacity : 1)
                .onAppear {
                    guard pulsing, !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        runningDotOpacity = 0.3
                    }
                }

            Text("\(count)")
                .font(.custom("DM Sans", size: 10).weight(.medium))
                .foregroundColor(textColor)
        }
    }
}

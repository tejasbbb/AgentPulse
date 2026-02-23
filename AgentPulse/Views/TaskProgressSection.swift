import SwiftUI

struct TaskProgressSection: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TASKS")
                    .font(.custom("DM Sans", size: 10).weight(.semibold))
                    .tracking(1.0)
                    .foregroundColor(Color.white.opacity(0.35))

                Spacer()

                let completed = vm.tasks.filter { $0.status == .completed }.count
                Text("\(completed)/\(max(vm.tasks.count, 1))")
                    .font(.custom("JetBrains Mono", size: 11).weight(.semibold))
                    .foregroundColor(Color(hex: 0xF5F0E8))
            }

            SegmentedProgressBar(tasks: vm.tasks)

            if vm.tasks.isEmpty {
                Text("No active tasks")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.sortedTasks.prefix(5)) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}

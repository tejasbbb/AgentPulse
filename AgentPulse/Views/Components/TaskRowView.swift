import SwiftUI

struct TaskRowView: View {
    let task: UnifiedTask

    var body: some View {
        HStack(spacing: 10) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(task.subject)
                    .font(.custom("DM Sans", size: 12).weight(.medium))
                    .foregroundColor(task.status == .completed ? Color.white.opacity(0.45) : Color(hex: 0xF5F0E8))
                    .lineLimit(1)

                if let owner = task.owner {
                    Text(owner)
                        .font(.custom("JetBrains Mono", size: 9))
                        .foregroundColor(Color.white.opacity(0.3))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 7)
    }

    private var statusIcon: some View {
        Group {
            switch task.status {
            case .inProgress:
                Circle().fill(Color(hex: 0xE8A84C)).frame(width: 8, height: 8)
            case .pending:
                Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5).frame(width: 8, height: 8)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: 0x7ECBA1))
            }
        }
    }
}

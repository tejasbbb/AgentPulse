import SwiftUI

struct FileActivitySection: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FILE ACTIVITY")
                .font(.custom("DM Sans", size: 10).weight(.medium))
                .tracking(1.2)
                .foregroundColor(Color.white.opacity(0.3))

            if vm.fileActivities.isEmpty {
                Text("No recent file changes")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 1) {
                    ForEach(vm.fileActivities.prefix(5)) { file in
                        FileRowView(file: file)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

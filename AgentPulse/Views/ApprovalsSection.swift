import SwiftUI

struct ApprovalsSection: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("AWAITING APPROVAL")
                    .font(.custom("DM Sans", size: 10).weight(.semibold))
                    .tracking(1.0)
                    .foregroundColor(Color(hex: 0xE07A5F))

                Text("\(vm.pendingApprovals.count)")
                    .font(.custom("JetBrains Mono", size: 10).weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: 0xE07A5F))
                    .clipShape(Capsule())

                Spacer()
            }

            ForEach(vm.pendingApprovals) { request in
                ApprovalCardView(request: request)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}

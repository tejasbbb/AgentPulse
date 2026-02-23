import SwiftUI

struct ApprovalsSection: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("AWAITING APPROVAL")
                    .font(.custom("DM Sans", size: 10).weight(.semibold))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: 0xE07A5F))

                Text("\(vm.pendingApprovals.count)")
                    .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(width: 18, height: 18)
                    .background(Color(hex: 0xE07A5F))
                    .clipShape(Circle())

                Spacer()
            }

            ForEach(vm.pendingApprovals) { request in
                ApprovalCardView(request: request)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

import SwiftUI

struct OrbitalAgentsSection: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AGENTS")
                .font(.custom("DM Sans", size: 10).weight(.semibold))
                .tracking(1.0)
                .foregroundColor(Color.white.opacity(0.35))

            if vm.agents.isEmpty {
                Text("No active agents")
                    .font(.custom("DM Sans", size: 12))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.vertical, 6)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(vm.agents.prefix(4)) { agent in
                        OrbitalRingView(agent: agent)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}

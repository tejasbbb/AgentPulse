import SwiftUI

struct StatsBarView: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    var body: some View {
        HStack(spacing: 0) {
            stat(value: "\(vm.stats.activeAgents)", label: "ACTIVE", color: Color(hex: 0xE8A84C))
            divider
            stat(value: "\(vm.stats.totalMessages)", label: "MESSAGES", color: Color(hex: 0xF5F0E8))
            divider
            stat(value: "\(vm.stats.totalToolCalls)", label: "TOOL CALLS", color: Color(hex: 0xF5F0E8))
            divider
            stat(value: successText, label: "SUCCESS", color: Color(hex: 0x7ECBA1))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.15))
    }

    private var successText: String {
        if vm.stats.successRate <= 0 {
            return "--"
        }
        return "\(Int(vm.stats.successRate * 100))%"
    }

    private func stat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("Instrument Serif", size: 24))
                .foregroundColor(color)
                .lineSpacing(1)
                .tracking(-0.5)

            Text(label)
                .font(.custom("DM Sans", size: 9).weight(.regular))
                .tracking(0.8)
                .foregroundColor(Color.white.opacity(0.3))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: 0xFFF5E6, alpha: 0.06))
            .frame(width: 1, height: 28)
    }
}

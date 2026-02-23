import SwiftUI

struct StatsBarView: View {
    @EnvironmentObject var vm: AgentPulseViewModel

    var body: some View {
        HStack(spacing: 0) {
            stat(value: "\(vm.stats.activeAgents)", label: "ACTIVE", color: Color(hex: 0xE8A84C))
            divider
            stat(value: "\(vm.stats.totalMessages)", label: "MESSAGES", color: Color(hex: 0xF5F0E8))
            divider
            stat(value: "\(vm.stats.totalToolCalls)", label: "TOOLS", color: Color(hex: 0xF5F0E8))
            divider
            stat(value: successText, label: "SUCCESS", color: Color(hex: 0x7ECBA1))
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.18))
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
                .font(.custom("Instrument Serif", size: 21))
                .foregroundColor(color)

            Text(label)
                .font(.custom("DM Sans", size: 9).weight(.medium))
                .tracking(0.8)
                .foregroundColor(Color.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 24)
    }
}

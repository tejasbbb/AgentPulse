import SwiftUI

@main
struct AgentPulseApp: App {
    @StateObject private var viewModel = AgentPulseViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView()
                .environmentObject(viewModel)
                .frame(width: 400)
        } label: {
            HStack(spacing: 4) {
                PulsingOrbIcon(badgeCount: viewModel.pendingApprovalCount)
                    .frame(width: 14, height: 14)
                Text("AP")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.primary)
        }
        .menuBarExtraStyle(.window)
    }
}

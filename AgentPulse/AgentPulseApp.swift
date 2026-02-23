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
            PulsingOrbIcon(badgeCount: viewModel.pendingApprovalCount)
                .frame(width: 18, height: 18)
        }
        .menuBarExtraStyle(.window)
    }
}

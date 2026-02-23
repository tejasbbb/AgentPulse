import SwiftUI

struct MenuBarDropdownView: View {
    @EnvironmentObject var vm: AgentPulseViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var liveDotOpacity: Double = 1.0

    private var elapsedText: String {
        if ProcessInfo.processInfo.environment["AGENTPULSE_SNAPSHOT_STATE"] != nil {
            return "3 sec ago"
        }
        let sec = max(0, Int(Date().timeIntervalSince(vm.lastRefreshDate)))
        if sec < 60 { return "\(sec) sec ago" }
        if sec < 3600 { return "\(sec / 60) min ago" }
        return "\(sec / 3600)h ago"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().overlay(Color(hex: 0xFFF5E6, alpha: 0.06))

            ScrollView {
                VStack(spacing: 0) {
                    if vm.isFirstLaunch {
                        firstLaunchBanner
                    }

                    if vm.showRestartNotice {
                        restartNoticeBanner
                    }

                    if !vm.pendingApprovals.isEmpty {
                        ApprovalsSection()

                        sectionDivider
                    }

                    OrbitalAgentsSection()

                    sectionDivider

                    TaskProgressSection()

                    sectionDivider

                    FileActivitySection()
                }
            }
            .frame(maxHeight: 560)
            .background(Color(hex: 0x242220))

            Divider().overlay(Color(hex: 0xFFF5E6, alpha: 0.06))
            StatsBarView()

            Divider().overlay(Color(hex: 0xFFF5E6, alpha: 0.06))
            footer
        }
        .frame(width: 400)
        .background(Color(hex: 0x242220))
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(hex: 0xFFF5E6, alpha: 0.06))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("AgentPulse")
                .font(.custom("Instrument Serif", size: 22))
                .foregroundColor(Color(hex: 0xF5F0E8))
                .tracking(-0.3)

            HStack(spacing: 5) {
                Circle()
                    .fill(Color(hex: 0xE8A84C))
                    .frame(width: 5, height: 5)
                    .opacity(liveDotOpacity)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            liveDotOpacity = 0.3
                        }
                    }

                Text("LIVE")
                    .font(.custom("DM Sans", size: 10).weight(.medium))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: 0xE8A84C))
            }

            Spacer()

            Text(elapsedText)
                .font(.custom("JetBrains Mono", size: 10).weight(.light))
                .foregroundColor(Color.white.opacity(0.3))
                .tracking(0.5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(Color(hex: 0x242220))
    }

    private var firstLaunchBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome to AgentPulse")
                .font(.custom("DM Sans", size: 13).weight(.semibold))
                .foregroundColor(Color(hex: 0xF5F0E8))

            Text("Install the Claude PreToolUse hook to enable approval cards.")
                .font(.custom("DM Sans", size: 12))
                .foregroundColor(Color.white.opacity(0.7))

            Button(action: vm.installHook) {
                Text("Install Hook")
                    .font(.custom("DM Sans", size: 12).weight(.semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xE8A84C))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if let error = vm.installError {
                Text(error)
                    .font(.custom("DM Sans", size: 11))
                    .foregroundColor(Color(hex: 0xE07A5F))
            }
        }
        .padding(14)
        .background(Color(hex: 0x2C2A27))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var restartNoticeBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(hex: 0xE8A84C))
                .frame(width: 8, height: 8)
                .padding(.top, 4)

            Text("Restart active Claude Code sessions to enable the approval flow.")
                .font(.custom("DM Sans", size: 12))
                .foregroundColor(Color.white.opacity(0.8))

            Spacer()

            Button(action: vm.dismissRestartNotice) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            .buttonStyle(.plain)
            .focusable()
        }
        .padding(12)
        .background(Color(hex: 0x2C2A27))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var footer: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.custom("DM Sans", size: 11).weight(.regular))
            .foregroundColor(Color.white.opacity(0.15))
            .focusable()

            Spacer()

            Text("v1.0.0")
                .font(.custom("JetBrains Mono", size: 9).weight(.light))
                .foregroundColor(Color.white.opacity(0.15))
                .tracking(0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(hex: 0x242220))
    }
}

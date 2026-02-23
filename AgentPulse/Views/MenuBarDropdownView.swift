import SwiftUI

struct MenuBarDropdownView: View {
    @EnvironmentObject var vm: AgentPulseViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fixedSnapshotClock: String {
        if ProcessInfo.processInfo.environment["AGENTPULSE_SNAPSHOT_STATE"] != nil {
            return "12:00:00"
        }
        return Self.clockFormatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().overlay(Color.white.opacity(0.08))

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
                    }

                    OrbitalAgentsSection()
                    TaskProgressSection()
                    FileActivitySection()
                }
            }
            .frame(maxHeight: 560)
            .background(Color(hex: 0x242220))

            Divider().overlay(Color.white.opacity(0.08))
            StatsBarView()

            Divider().overlay(Color.white.opacity(0.08))
            footer
        }
        .frame(width: 400)
        .background(Color(hex: 0x242220))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("AgentPulse")
                .font(.custom("Instrument Serif", size: 24))
                .foregroundColor(Color(hex: 0xF5F0E8))

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: 0xE8A84C))
                    .frame(width: 6, height: 6)
                    .opacity(reduceMotion ? 1 : 0.8)
                Text("LIVE")
                    .font(.custom("DM Sans", size: 10).weight(.semibold))
                    .tracking(1.0)
                    .foregroundColor(Color(hex: 0xE8A84C))
            }

            Spacer()

            Text(fixedSnapshotClock)
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
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
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.custom("DM Sans", size: 12).weight(.medium))
            .foregroundColor(Color.white.opacity(0.5))
            .focusable()
            .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(hex: 0x242220))
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

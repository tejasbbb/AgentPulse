import SwiftUI

struct ApprovalCardView: View {
    @EnvironmentObject var vm: AgentPulseViewModel
    let request: ApprovalRequest

    @State private var denyHover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: agent name + source badge + elapsed
            HStack(spacing: 8) {
                Text(request.source.capitalized)
                    .font(.custom("DM Sans", size: 11).weight(.medium))
                    .foregroundColor(Color(hex: 0xF5F0E8))

                Text(request.source.uppercased())
                    .font(.custom("DM Sans", size: 8).weight(.semibold))
                    .foregroundColor(sourceColor)
                    .tracking(0.5)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(sourceBgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Spacer()

                Text("\(request.elapsedSeconds)s ago")
                    .font(.custom("JetBrains Mono", size: 9).weight(.light))
                    .foregroundColor(Color.white.opacity(0.15))
                    .tracking(0.3)
            }

            // Action type
            Text(request.displayType)
                .font(.custom("DM Sans", size: 9).weight(.medium))
                .foregroundColor(Color(hex: 0xE07A5F))
                .tracking(0.5)
                .textCase(.uppercase)

            // Detail box
            Text(request.displayDetail)
                .font(.custom("JetBrains Mono", size: 11).weight(.regular))
                .foregroundColor(Color.white.opacity(0.6))
                .lineSpacing(1.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: 0xFFF5E6, alpha: 0.03), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Action buttons — Deny first, then Approve, right-aligned
            HStack(spacing: 8) {
                Spacer()

                Button(action: { vm.deny(request) }) {
                    HStack(spacing: 0) {
                        Text("Deny")
                            .font(.custom("DM Sans", size: 11).weight(.medium))

                        kbdHint("N")
                    }
                    .foregroundColor(denyHover ? Color(hex: 0xE07A5F) : Color.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(denyHover ? Color(hex: 0xE07A5F, alpha: 0.1) : Color(hex: 0xFFF5E6, alpha: 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(denyHover ? Color(hex: 0xE07A5F, alpha: 0.2) : Color(hex: 0xFFF5E6, alpha: 0.06), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .focusable()
                .onHover { denyHover = $0 }

                Button(action: { vm.approve(request) }) {
                    HStack(spacing: 0) {
                        Text("Approve")
                            .font(.custom("DM Sans", size: 11).weight(.medium))

                        kbdHint("Y")
                    }
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0x7ECBA1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .focusable()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: 0x2C2A27))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xE07A5F, alpha: 0.15), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            // Coral left stripe
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0xE07A5F))
                .frame(width: 3)
                .padding(.vertical, 1)
        }
        .padding(.bottom, 8)
    }

    private var sourceColor: Color {
        request.source.lowercased() == "codex" ? Color(hex: 0x8B9FC7) : Color(hex: 0xE8A84C)
    }

    private var sourceBgColor: Color {
        request.source.lowercased() == "codex"
            ? Color(hex: 0x8B9FC7, alpha: 0.12)
            : Color(hex: 0xE8A84C, alpha: 0.08)
    }

    private func kbdHint(_ key: String) -> some View {
        Text(key)
            .font(.custom("JetBrains Mono", size: 9).weight(.regular))
            .foregroundColor(Color.white.opacity(0.15))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Color(hex: 0xFFF5E6, alpha: 0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(hex: 0xFFF5E6, alpha: 0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .padding(.leading, 6)
    }
}

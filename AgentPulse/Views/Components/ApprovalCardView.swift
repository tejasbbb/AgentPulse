import SwiftUI

struct ApprovalCardView: View {
    @EnvironmentObject var vm: AgentPulseViewModel
    let request: ApprovalRequest

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color(hex: 0xE07A5F))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(request.source.uppercased())
                        .font(.custom("DM Sans", size: 10).weight(.medium))
                        .foregroundColor(Color.white.opacity(0.65))

                    Spacer()

                    Text("\(request.elapsedSeconds)s")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundColor(Color.white.opacity(0.35))
                }

                Text(request.displayType)
                    .font(.custom("DM Sans", size: 13).weight(.semibold))
                    .foregroundColor(Color(hex: 0xF5F0E8))

                Text(request.displayDetail)
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundColor(Color.white.opacity(0.75))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 10) {
                    Button(action: { vm.approve(request) }) {
                        Text("Approve")
                            .font(.custom("DM Sans", size: 12).weight(.semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0x7ECBA1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable()

                    Button(action: { vm.deny(request) }) {
                        Text("Deny")
                            .font(.custom("DM Sans", size: 12).weight(.semibold))
                            .foregroundColor(Color(hex: 0xE07A5F))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable()

                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0x2C2A27))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

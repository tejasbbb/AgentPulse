import SwiftUI

struct FileRowView: View {
    let file: UnifiedFileActivity

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(file.heatLevel.color)
                .frame(width: 4, height: 4)
                .shadow(color: file.heatLevel == .hot ? Color(hex: 0xE8A84C, alpha: 0.15) : .clear, radius: file.heatLevel == .hot ? 3 : 0)

            HStack(spacing: 0) {
                Text(file.directory)
                    .foregroundColor(Color.white.opacity(0.15))
                Text(file.fileName)
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .font(.custom("JetBrains Mono", size: 11).weight(.regular))
            .lineLimit(1)
            .truncationMode(.middle)
            .tracking(-0.2)

            Spacer(minLength: 8)

            Text(file.elapsedText)
                .font(.custom("JetBrains Mono", size: 9).weight(.light))
                .foregroundColor(Color.white.opacity(0.15))
                .tracking(0.3)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

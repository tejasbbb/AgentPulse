import SwiftUI

struct FileRowView: View {
    let file: UnifiedFileActivity

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(file.heatLevel.color)
                .frame(width: 6, height: 6)

            HStack(spacing: 0) {
                Text(file.directory)
                    .foregroundColor(Color.white.opacity(0.28))
                Text(file.fileName)
                    .foregroundColor(Color.white.opacity(0.68))
            }
            .font(.custom("JetBrains Mono", size: 10))
            .lineLimit(1)
            .truncationMode(.middle)

            Spacer(minLength: 8)

            Text(file.elapsedText)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding(.vertical, 6)
    }
}

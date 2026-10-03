import SwiftUI

struct ClassBlockView: View {
    let block: Block
    let width: CGFloat
    let rowHeight: CGFloat
    let gap: CGFloat
    var isLive: Bool = false
    
    var body: some View {
        let entry = block.entry
        let duration = block.end - block.start
        let height = max(CGFloat(duration) * rowHeight - gap * 2, 24)
        let isCompact = height < 46
        
        let primary: Color = isLive ? .white : .black
        let secondary: Color = isLive ? .white.opacity(0.65) : Color(white: 0.5)
        
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if !isCompact {
                Text(entry.classroom)
                    .font(.system(size: 10))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
                
                Text(entry.type)
                    .font(.system(size: 10))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 7)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isLive ? entry.subjectColor : Color.black.opacity(0.04))
        )
        .overlay(alignment: .leading) {
            Capsule()
                .fill(entry.subjectColor.gradient)
                .frame(width: 2.5)
                .padding(.vertical, 6)
                .padding(.leading, 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(isLive ? 0 : 0.18), lineWidth: 0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

import SwiftUI

struct HeaderTitleView: View {
    
    let title: String
    let position: Position
    
    init(title: String = "nil", position: Position = .leading) {
        self.title = title
        self.position = position
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20))
                .textCase(.uppercase)
                .padding(16)
                .padding(.top, 5)
                .padding(.bottom, 14)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: position.alignment)
    }
}

struct SubHeaderTitleView: View {
    
    let title: String
    let position: Position
    
    init(title: String = "nil", position: Position = .leading) {
        self.title = title
        self.position = position
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .textCase(.uppercase)
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: position.alignment)
    }
}

enum Position {
    case leading, center, trailing
    
    var alignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

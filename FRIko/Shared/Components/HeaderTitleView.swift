import SwiftUI

struct HeaderTitleView: View {
    
    let title: String
    let position: HeaderPosition
    
    init(title: String = "nil", position: HeaderPosition = .leading) {
        self.title = title
        self.position = position
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .textCase(.uppercase)
                .padding(16)
                .padding(.top, 5)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: position.alignment)
    }
}

enum HeaderPosition {
    case leading, center, trailing
    
    var alignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

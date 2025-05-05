
import SwiftUI
struct ListItem: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    
    static let preview = [
        ListItem(title: "Row 1", color: .red),
        ListItem(title: "Row 2", color: .blue),
        ListItem(title: "Row 3", color: .green),
        ListItem(title: "Row 4", color: .orange),
        ListItem(title: "Row 5", color: .pink),
    ]
}

struct youtube: View {
    var body: some View {
        ScrollView {
            ForEach(ListItem.preview) { item in
                item.color
                    .frame(height: 300)
                    .overlay {
                        Text(item.title)
                    }
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .scrollTransition{ effect, phase in
                        effect
                            .scaleEffect(phase.isIdentity ? 1 : 0.8)
                            .offset(x: offset(for:phase))
                        
                    }
                
            }
        }
    }
    
    func offset(for phase: ScrollTransitionPhase) -> Double {
        switch phase {
        case .topLeading:
            200
        case .identity:
            0
        case .bottomTrailing:
            -200
        }
    }
}

#Preview {
    youtube()
}

import SwiftUI

struct CardView: View {
    var card: Card
    var width: CGFloat
    var height: CGFloat
    var isSelected: Bool  // Computed attribue must not be @State variable

    var body: some View {
        VStack {
            if card.isDefaultTitle {
                Text("(\(card.title))")
            } else {
                Text(card.title).font(.headline)
            }
            if !card.description.isEmpty  &&  card.title != "" {
                Text(card.description).font(.subheadline)
            }
        }
        .frame(width: self.width, height: self.height)
        .foregroundColor(self.isSelected ? Color.black : Color.white)
        .background(self.isSelected ? Color.mint : Color.gray)
        .cornerRadius(10)
    }
}

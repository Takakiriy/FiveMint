import SwiftUI

struct Card: Identifiable {
    var id = UUID()
    var index: Int
    var calendarItemIdentifier: String
    var title: String
    var isDefaultTitle: Bool
    var description: String
}

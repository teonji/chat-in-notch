import SwiftUI

extension View {
    /// Shows the pointing-hand cursor over a control. Plain and borderless buttons keep the arrow by default.
    func clickable() -> some View { pointerStyle(.link) }
}

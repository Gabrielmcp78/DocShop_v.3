import SwiftUI

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

extension View {
    func glassy() -> some View { self.modifier(GlassBackground()) }
}

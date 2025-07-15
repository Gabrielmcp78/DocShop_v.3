import SwiftUI

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .backgroundStyle(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 0.5)
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.4), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassy() -> some View { self.modifier(GlassBackground()) }
}

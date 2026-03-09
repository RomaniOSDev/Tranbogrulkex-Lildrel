import SwiftUI

extension LinearGradient {
    static var appBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appBackground,
                Color.appSurface.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var appCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface,
                Color.appBackground.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func appCardStyle(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LinearGradient.appCardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.appPrimary.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 12)
    }
}


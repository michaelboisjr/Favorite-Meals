import UIKit
import SwiftUI

// 1. The Modifier logic
struct GlobalBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.background)
            .scrollContentBackground(.hidden)
    }
}

// 2. The convenient extension
extension View {
    func withAppBackground() -> some View {
        self.modifier(GlobalBackgroundModifier())
    }
}

struct ThemeFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.Colors.fields)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .tint(Theme.Colors.primary) // Sets cursor and selection color
    }
}

extension View {
    func styledField() -> some View {
        self.modifier(ThemeFieldStyle())
    }
}

struct GlobalListRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Theme.Colors.fields)
    }
}

// 2. The convenient extension
extension View {
    func withListRow() -> some View {
        self.modifier(GlobalListRowModifier())
    }
}

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width / size.width * size.height)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: canvasSize))
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct ScalableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

import SwiftUI

struct Theme {
    struct Colors {
        static let primary = Color("AppPrimary")
        static let fields = Color("AppFields")
        static let background = Color("AppBackground")
        static let accent = Color("AccentColor")
    }
    
    // Fonts or Spacing could go here too
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
    }
}

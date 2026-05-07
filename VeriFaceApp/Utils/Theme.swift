import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// Primary brand purple — buttons, active states, key accents.
    static let brandPurple = Color(red: 0.45, green: 0.20, blue: 0.85)

    /// Lighter tint for gradient endpoints, hover states.
    static let brandPurpleLight = Color(red: 0.62, green: 0.45, blue: 0.95)

    /// Very light wash for card backgrounds and surface tints.
    static let brandPurpleSurface = Color(red: 0.93, green: 0.90, blue: 1.0)

    /// Darker shade for pressed states, text on light backgrounds.
    static let brandPurpleDark = Color(red: 0.30, green: 0.10, blue: 0.60)

    /// Subtle gradient backdrop for the login screen.
    static let brandBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.97, green: 0.96, blue: 1.0),
            Color(red: 0.93, green: 0.90, blue: 0.98),
            Color(red: 0.96, green: 0.95, blue: 1.0),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Design Tokens

enum DesignTokens {
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
}

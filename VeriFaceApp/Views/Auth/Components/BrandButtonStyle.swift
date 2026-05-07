import SwiftUI

// MARK: - Primary Button Style (gradient fill, press scale, shadow)

struct BrandPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                configuration.label
            }
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .fill(LinearGradient(
                    colors: [.brandPurple, .brandPurpleLight],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
        )
        .shadow(
            color: configuration.isPressed
                ? Color.brandPurple.opacity(0.15)
                : Color.brandPurple.opacity(0.3),
            radius: configuration.isPressed ? 4 : 12,
            x: 0,
            y: configuration.isPressed ? 2 : 4
        )
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .opacity(isLoading ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style (outlined)

struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.brandPurple)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                    .strokeBorder(Color.brandPurple.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                            .fill(Color.brandPurpleSurface.opacity(0.5))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style (text-only, for tertiary actions)

struct BrandGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

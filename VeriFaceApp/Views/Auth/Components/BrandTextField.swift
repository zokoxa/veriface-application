import SwiftUI

struct BrandTextField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var errorMessage: String? = nil

    @State private var isPasswordVisible = false
    @FocusState private var isFocused: Bool

    private var hasText: Bool { !text.isEmpty }
    private var isFloating: Bool { isFocused || hasText }
    private var borderColor: Color {
        if errorMessage != nil { return .red }
        if isFocused { return .brandPurple }
        return Color(.systemGray4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                            .fill(Color(.systemBackground))
                    )
                    .frame(height: 56)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(isFocused ? .brandPurple : .secondary)
                        .frame(width: 24)

                    ZStack(alignment: .leading) {
                        // Floating label
                        Text(label)
                            .font(isFloating ? .caption : .body)
                            .foregroundStyle(
                                errorMessage != nil ? .red :
                                    isFocused ? .brandPurple : .secondary
                            )
                            .offset(y: isFloating ? -12 : 0)
                            .animation(.easeInOut(duration: 0.15), value: isFloating)

                        // Input field
                        if isSecure && !isPasswordVisible {
                            SecureField("", text: $text)
                                .textContentType(textContentType)
                                .focused($isFocused)
                                .offset(y: isFloating ? 6 : 0)
                        } else {
                            TextField("", text: $text)
                                .keyboardType(keyboardType)
                                .autocapitalization(.none)
                                .textContentType(textContentType)
                                .focused($isFocused)
                                .offset(y: isFloating ? 6 : 0)
                        }
                    }

                    if isSecure {
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(.red)
                .padding(.leading, DesignTokens.Spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        .onChange(of: isPasswordVisible) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }
}

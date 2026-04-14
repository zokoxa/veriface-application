import SwiftUI

/// A small card that lets users update the ngrok base URL at runtime
/// without rebuilding the app — useful when the tunnel restarts.
struct NgrokConfigView: View {
    @State private var url: String =
        UserDefaults.standard.string(forKey: Constants.Keys.baseURL)
        ?? "https://shayna-unswabbed-baroquely.ngrok-free.dev"
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Backend URL (ngrok)", systemImage: "network")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack {
                TextField("https://xxxx.ngrok-free.app", text: $url)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .font(.caption)
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
                    UserDefaults.standard.set(trimmed, forKey: Constants.Keys.baseURL)
                    withAnimation { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { saved = false }
                    }
                } label: {
                    Image(systemName: saved ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                        .foregroundStyle(saved ? .green : .blue)
                        .font(.title3)
                }
            }

            Text("Update this when your ngrok tunnel restarts.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

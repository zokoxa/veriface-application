import SwiftUI

struct CheckInView: View {
    let sessionId: Int
    @StateObject private var vm: CheckInViewModel
    @State private var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    init(sessionId: Int) {
        self.sessionId = sessionId
        _vm = StateObject(wrappedValue: CheckInViewModel(sessionId: sessionId))
    }

    var body: some View {
        ZStack {
            // Camera always underneath
            CameraView(capturedImage: $capturedImage)
                .ignoresSafeArea()
                .onChange(of: capturedImage) { _, newImage in
                    guard let img = newImage else { return }
                    Task { await vm.checkin(image: img) }
                }

            // Result overlay
            VStack {
                Spacer()
                resultCard
            }
            .padding(.bottom, 100) // above capture button
        }
        .navigationTitle("Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private var resultCard: some View {
        switch vm.state {
        case .idle:
            EmptyView()

        case .processing:
            HStack(spacing: 12) {
                ProgressView().tint(.white)
                Text("Verifying face…")
                    .foregroundStyle(.white)
                    .font(.subheadline.bold())
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

        case .success(let response):
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                Text(vm.resultSummary)
                    .font(.headline)
                    .foregroundStyle(.white)

                // Per-face results
                ForEach(Array(response.result.keys.sorted()), id: \.self) { key in
                    let result = response.result[key]!
                    if result.success, let data = result.data {
                        Label("\(data.fullName) — \(data.status?.label ?? "")",
                              systemImage: "person.fill.checkmark")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    } else if let err = result.error {
                        Label(err, systemImage: "person.fill.xmark")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.9))
                    }
                }

                Button("Check In Another") {
                    vm.reset()
                    capturedImage = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))

        case .failure(let error):
            VStack(spacing: 10) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    vm.reset()
                    capturedImage = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

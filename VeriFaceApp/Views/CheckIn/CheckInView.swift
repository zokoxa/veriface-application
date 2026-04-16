import SwiftUI

struct CheckInView: View {
    let sessionId: Int
    @StateObject private var vm: CheckInViewModel

    init(sessionId: Int) {
        self.sessionId = sessionId
        _vm = StateObject(wrappedValue: CheckInViewModel(sessionId: sessionId))
    }

    var body: some View {
        ZStack {
            CameraView { image in
                guard !vm.isProcessing else { return }
                vm.submitCheckin(image: image)
            }
                .ignoresSafeArea()

            VStack {
                Spacer()
                toastStack
                    .padding(.bottom, 48)
                    .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private var toastStack: some View {
        VStack(spacing: 10) {
            ForEach(vm.toasts) { toast in
                HStack(spacing: 10) {
                    Image(systemName: toast.systemImage)
                        .foregroundStyle(toast.tint)
                    Text(toast.message)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .allowsHitTesting(false)
    }
}

import SwiftUI

struct LoginView: View {
    @ObservedObject var vm: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Logo / header
                        VStack(spacing: 12) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                            Text("VeriFace")
                                .font(.largeTitle.bold())
                            Text("Check-In App")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 48)

                        // Form card
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Email", systemImage: "envelope")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                TextField("you@example.com", text: $vm.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Password", systemImage: "lock")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                SecureField("Password", text: $vm.password)
                                    .textContentType(.password)
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            if let error = vm.errorMessage {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                Task { await vm.login() }
                            } label: {
                                Group {
                                    if vm.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(vm.isLoading)
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 24)

                        // ngrok URL config
                        NgrokConfigView()
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 48)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

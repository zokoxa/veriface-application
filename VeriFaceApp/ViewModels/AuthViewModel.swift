import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var email = ""
    @Published var password = ""

    init() {
        isLoggedIn = UserDefaults.standard.string(forKey: Constants.Keys.token) != nil
    }

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let body = LoginRequest(email: email, password: password)
            let response: UserWithToken = try await APIClient.shared.post(Constants.Auth.login, body: body)
            UserDefaults.standard.set(response.token, forKey: Constants.Keys.token)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.token)
        isLoggedIn = false
        email = ""
        password = ""
    }
}

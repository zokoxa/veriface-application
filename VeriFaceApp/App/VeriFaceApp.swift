import SwiftUI

@main
struct VeriFaceApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        if authVM.isLoggedIn {
            EventsListView(authVM: authVM)
        } else {
            LoginView(vm: authVM)
        }
    }
}

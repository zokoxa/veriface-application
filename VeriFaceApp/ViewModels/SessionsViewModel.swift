import Foundation

@MainActor
final class SessionsViewModel: ObservableObject {
    @Published var sessions: [SessionOutput] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchSessions(eventId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let body = GetSessionsRequest(eventId: eventId)
            let response: GetSessionsResponse = try await APIClient.shared.post(
                Constants.Session.getSessions, body: body)
            sessions = response.sessions.sorted {
                ($0.sequenceNumber ?? 0) > ($1.sequenceNumber ?? 0)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

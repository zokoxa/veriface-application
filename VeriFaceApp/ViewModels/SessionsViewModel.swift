import Foundation

@MainActor
final class SessionsViewModel: ObservableObject {
    @Published var sessions: [SessionOutput] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCreating = false
    @Published var createError: String?

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

    func createSession(eventId: Int, startTime: Date?, endTime: Date?) async {
        isCreating = true
        createError = nil
        do {
            let fmt = ISO8601DateFormatter()
            let body = CreateSessionRequest(
                eventId: eventId,
                startTime: startTime.map { fmt.string(from: $0) },
                endTime: endTime.map { fmt.string(from: $0) }
            )
            let response: CreateSessionResponse = try await APIClient.shared.post(
                Constants.Session.createSession, body: body)
            sessions.insert(response.session, at: 0)
        } catch {
            createError = error.localizedDescription
        }
        isCreating = false
    }
}

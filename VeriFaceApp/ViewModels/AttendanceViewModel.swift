import Foundation
import Combine

@MainActor
final class AttendanceViewModel: ObservableObject {
    @Published var attendance: [AttendanceWithUser] = []
    @Published var summary: AttendanceSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var updateError: String?
    @Published private(set) var wsConnected = false

    private let wsManager = WebSocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var connectedSessionId: Int?

    init() {
        wsManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$wsConnected)

        wsManager.$latestEvent
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleLiveCheckin(event)
            }
            .store(in: &cancellables)
    }

    func load(sessionId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let body = GetAttendanceRequest(sessionId: sessionId)
            let response: GetAttendanceResponse = try await APIClient.shared.post(
                Constants.Session.getAttendance, body: body)
            attendance = response.attendance
            summary = response.summary
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func connect(sessionId: Int) {
        guard connectedSessionId != sessionId else { return }
        wsManager.connect(sessionId: sessionId)
        connectedSessionId = sessionId
    }

    func disconnect() {
        wsManager.disconnect()
        connectedSessionId = nil
    }

    func updateStatus(userId: Int, sessionId: Int, status: AttendanceStatus) async {
        updateError = nil
        do {
            let body = UpdateAttendanceStatusRequest(userId: userId, sessionId: sessionId, status: status)
            try await APIClient.shared.postWithoutResponse(
                Constants.Session.updateAttendanceStatus, body: body)
            // Refresh attendance list
            await load(sessionId: sessionId)
        } catch {
            updateError = error.localizedDescription
        }
    }

    private func handleLiveCheckin(_ event: WSCheckinData) {
        guard let sessionId = event.sessionId else { return }
        guard sessionId == connectedSessionId else { return }
        Task { await load(sessionId: sessionId) }
    }
}

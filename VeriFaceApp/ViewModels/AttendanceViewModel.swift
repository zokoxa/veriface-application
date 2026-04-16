import Foundation
import Combine

@MainActor
final class AttendanceViewModel: ObservableObject {
    @Published var attendance: [AttendanceWithUser] = []
    @Published var summary: AttendanceSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var updateError: String?

    private let wsManager = WebSocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var connectedSessionId: Int?

    var wsConnected: Bool { wsManager.isConnected }

    init() {
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
        guard let userId = event.userId else { return }
        if let idx = attendance.firstIndex(where: { $0.userId == userId }) {
            // Rebuild updated record
            let old = attendance[idx]
            // We can't mutate the struct in place cleanly — reload from server on next push
            _ = old
        }
        // Re-fetch to get fresh data after any live update
        if let sessionId = event.sessionId {
            Task { await load(sessionId: sessionId) }
        }
    }
}

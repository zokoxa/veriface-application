import Foundation
import UIKit

enum CheckInState {
    case idle
    case processing
    case success(CheckinResponse)
    case failure(String)
}

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var state: CheckInState = .idle
    let sessionId: Int

    init(sessionId: Int) {
        self.sessionId = sessionId
    }

    var isProcessing: Bool {
        if case .processing = state { return true }
        return false
    }

    func checkin(image: UIImage) async {
        guard !isProcessing else { return }
        state = .processing
        do {
            let response = try await APIClient.shared.checkin(sessionId: sessionId, image: image)
            state = .success(response)
        } catch {
            state = .failure(error.localizedDescription)
        }
        // Auto-reset after 3 seconds so scanning continues
        try? await Task.sleep(for: .seconds(3))
        state = .idle
    }

    var resultSummary: String {
        if case .success(let r) = state {
            return "\(r.stats.checkedIn) of \(r.stats.numFace) face(s) checked in."
        }
        return ""
    }
}

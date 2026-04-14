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

    func checkin(image: UIImage) async {
        state = .processing
        do {
            let response = try await APIClient.shared.checkin(sessionId: sessionId, image: image)
            state = .success(response)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }

    var resultSummary: String {
        if case .success(let r) = state {
            return "\(r.stats.checkedIn) of \(r.stats.numFace) face(s) checked in."
        }
        return ""
    }
}

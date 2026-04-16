import Foundation
import UIKit
import SwiftUI

enum CheckInState {
    case idle
    case processing
}

enum CheckInToastKind {
    case alreadyCheckedIn
    case welcome

    var systemImage: String {
        switch self {
        case .alreadyCheckedIn:
            return "clock.fill"
        case .welcome:
            return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .alreadyCheckedIn:
            return .orange
        case .welcome:
            return .green
        }
    }

    var priority: Int {
        switch self {
        case .alreadyCheckedIn:
            return 0
        case .welcome:
            return 1
        }
    }
}

struct CheckInToast: Identifiable {
    let id = UUID()
    let userId: Int?
    let kind: CheckInToastKind
    let message: String
    let systemImage: String
    let tint: Color
}

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var state: CheckInState = .idle
    @Published var toasts: [CheckInToast] = []
    let sessionId: Int

    // Minimum time between API requests regardless of response speed
    private let minRequestInterval: TimeInterval = 0.5
    private var lastRequestTime: Date = .distantPast

    // Per-user cooldown with toast precedence, so welcome wins over duplicate states.
    private let checkinCooldown: TimeInterval = 30
    private let duplicateToastGracePeriod: TimeInterval = 0.75
    private var recentToastKinds: [Int: CheckInToastKind] = [:]
    private var pendingAlreadyCheckedInTasks: [Int: Task<Void, Never>] = [:]

    init(sessionId: Int) {
        self.sessionId = sessionId
    }

    var isProcessing: Bool {
        if case .processing = state { return true }
        return false
    }

    func checkin(image: UIImage) async {
        guard !isProcessing else { return }
        guard Date().timeIntervalSince(lastRequestTime) >= minRequestInterval else { return }

        state = .processing
        lastRequestTime = Date()

        do {
            let response = try await APIClient.shared.checkin(sessionId: sessionId, image: image)
            print("[CheckIn] stats: \(response.stats.checkedIn)/\(response.stats.numFace) faces")
            for (key, r) in response.result {
                print("[CheckIn] face \(key): success=\(r.success) name=\(r.data?.fullName ?? "nil") error=\(r.error ?? "none")")
            }

            for result in response.result.values {
                guard let data = result.data, let userId = data.userId else { continue }
                let name = data.fullName.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
                if data.alreadyCheckedIn == true {
                    let message = name.isEmpty ? "Already checked in!" : "You're already checked-in \(name)!"
                    addToast(message: message, for: userId, kind: .alreadyCheckedIn)
                } else {
                    let message = name.isEmpty ? "Check-in successful!" : "Welcome \(name)!"
                    addToast(message: message, for: userId, kind: .welcome)
                }
            }
        } catch {
            print("[CheckIn] API error: \(error)")
        }
        state = .idle
    }

    private func addToast(message: String, for userId: Int, kind: CheckInToastKind) {
        if kind == .alreadyCheckedIn {
            pendingAlreadyCheckedInTasks[userId]?.cancel()
            pendingAlreadyCheckedInTasks[userId] = Task { @MainActor in
                try? await Task.sleep(for: .seconds(duplicateToastGracePeriod))
                guard !Task.isCancelled else { return }
                pendingAlreadyCheckedInTasks[userId] = nil
                presentToast(message: message, for: userId, kind: kind)
            }
            return
        }

        pendingAlreadyCheckedInTasks[userId]?.cancel()
        pendingAlreadyCheckedInTasks[userId] = nil
        presentToast(message: message, for: userId, kind: kind)
    }

    private func presentToast(message: String, for userId: Int, kind: CheckInToastKind) {
        if let recentKind = recentToastKinds[userId], recentKind.priority > kind.priority {
            return
        }

        if let recentKind = recentToastKinds[userId], recentKind.priority == kind.priority {
            return
        }

        recentToastKinds[userId] = kind
        scheduleToastCooldownReset(for: userId, kind: kind)

        if kind == .welcome {
            withAnimation(.easeOut) {
                toasts.removeAll { $0.userId == userId && $0.kind == .alreadyCheckedIn }
            }
        }

        let toast = CheckInToast(
            userId: userId,
            kind: kind,
            message: message,
            systemImage: kind.systemImage,
            tint: kind.tint
        )
        withAnimation(.spring) { toasts.append(toast) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeOut) { toasts.removeAll { $0.id == toast.id } }
        }
    }

    private func scheduleToastCooldownReset(for userId: Int, kind: CheckInToastKind) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(checkinCooldown))
            guard recentToastKinds[userId] == kind else { return }
            recentToastKinds.removeValue(forKey: userId)
        }
    }
}

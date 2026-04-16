import Foundation
import SwiftUI

enum AttendanceStatus: String, Codable, CaseIterable {
    case present = "present"
    case late = "late"
    case absent = "absent"

    var label: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    var color: Color {
        switch self {
        case .present: return .green
        case .late: return .orange
        case .absent: return .red
        }
    }

    var icon: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .late: return "clock.fill"
        case .absent: return "xmark.circle.fill"
        }
    }
}

struct AttendanceWithUser: Decodable, Identifiable {
    let userId: Int
    let sessionId: Int?
    let status: AttendanceStatus
    let checkInTime: String?
    let firstName: String?
    let lastName: String?
    let email: String?

    // Backend doesn't return an attendance `id` — use userId as the stable identifier
    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
        case status
        case checkInTime = "check_in_time"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }

    var fullName: String {
        let f = firstName ?? ""
        let l = lastName ?? ""
        let name = "\(f) \(l)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Unknown" : name
    }

    var initials: String {
        let f = firstName?.first.map(String.init) ?? ""
        let l = lastName?.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }
}

struct AttendanceSummary: Decodable {
    let total: Int
    let present: Int
    let late: Int
    let absent: Int
}

struct GetAttendanceRequest: Encodable {
    let sessionId: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

struct GetAttendanceResponse: Decodable {
    let success: Bool
    let attendance: [AttendanceWithUser]
    let summary: AttendanceSummary
}

struct UpdateAttendanceStatusRequest: Encodable {
    let userId: Int
    let sessionId: Int
    let status: AttendanceStatus

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
        case status
    }
}

// MARK: - WebSocket check-in push event
struct WSCheckinEvent: Decodable {
    let type: String
    let data: WSCheckinData
}

struct WSCheckinData: Decodable {
    let userId: Int?
    let sessionId: Int?
    let status: AttendanceStatus?
    let checkInTime: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
        case status
        case checkInTime = "check_in_time"
        case firstName = "first_name"
        case lastName = "last_name"
    }

    var fullName: String {
        "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }
}

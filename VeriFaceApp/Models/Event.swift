import Foundation

struct EventWithRole: Decodable, Identifiable {
    let id: Int
    let eventName: String
    let userId: Int
    let startDate: String?
    let endDate: String?
    let location: String?
    let defaultStartTime: String?
    let role: String

    enum CodingKeys: String, CodingKey {
        case id
        case eventName = "event_name"
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case location
        case defaultStartTime = "default_start_time"
        case role
    }

    var roleLabel: String {
        role.prefix(1).uppercased() + role.dropFirst()
    }

    var roleColor: String {
        switch role {
        case "owner": return "purple"
        case "admin": return "blue"
        case "moderator": return "orange"
        default: return "gray"
        }
    }

    var canCheckin: Bool {
        ["owner", "admin", "moderator"].contains(role)
    }
}

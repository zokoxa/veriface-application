import Foundation

struct SessionOutput: Decodable, Identifiable {
    let id: Int
    let eventId: Int
    let startTime: String?
    let endTime: String?
    let sequenceNumber: Int?
    let qrToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case sequenceNumber = "sequence_number"
        case qrToken = "qr_token"
    }

    var displayLabel: String {
        if let seq = sequenceNumber {
            return "Session \(seq)"
        }
        return "Session \(id)"
    }

    var formattedStart: String {
        guard let raw = startTime else { return "No start time" }
        return formatISO(raw)
    }

    var formattedEnd: String {
        guard let raw = endTime else { return "Ongoing" }
        return formatISO(raw)
    }

    private func formatISO(_ raw: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            return df.string(from: date)
        }
        return raw
    }
}

struct GetSessionsRequest: Encodable {
    let eventId: Int

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
    }
}

struct GetSessionsResponse: Decodable {
    let success: Bool
    let sessions: [SessionOutput]
}

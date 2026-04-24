import Foundation
import UIKit

enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noToken: return "Not authenticated. Please log in."
        case .httpError(let code, let msg): return "Server error \(code): \(msg)"
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .networkError(let e): return e.localizedDescription
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private var token: String? {
        UserDefaults.standard.string(forKey: Constants.Keys.token)
    }

    // MARK: - Generic request helpers

    func get<T: Decodable>(_ urlString: String, authenticated: Bool = true) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if authenticated { try addAuth(&req) }
        addNgrokHeader(&req)
        return try await perform(req)
    }

    func post<Body: Encodable, T: Decodable>(_ urlString: String, body: Body, authenticated: Bool = true) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        if authenticated { try addAuth(&req) }
        addNgrokHeader(&req)
        return try await perform(req)
    }

    func postWithoutResponse<Body: Encodable>(_ urlString: String, body: Body, authenticated: Bool = true) async throws {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        if authenticated { try addAuth(&req) }
        addNgrokHeader(&req)
        try await performWithoutResponse(req)
    }

    /// Multipart upload for face check-in
    func checkin(sessionId: Int, image: UIImage) async throws -> CheckinResponse {
        guard let url = URL(string: "\(Constants.Session.checkin)?session_id=\(sessionId)") else {
            throw APIError.invalidURL
        }
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw APIError.networkError(NSError(domain: "img", code: 0,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]))
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        try addAuth(&req)
        addNgrokHeader(&req)
        req.httpBody = makeMultipart(boundary: boundary, jpeg: jpeg)
        return try await perform(req)
    }

    // MARK: - Private

    private func addAuth(_ req: inout URLRequest) throws {
        guard let token else { throw APIError.noToken }
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    // ngrok requires this header to bypass the browser warning page
    private func addNgrokHeader(_ req: inout URLRequest) {
        req.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
    }

    private func perform<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw APIError.httpError(http.statusCode, body)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performWithoutResponse(_ req: URLRequest) async throws {
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw APIError.httpError(http.statusCode, body)
        }
    }

    private func makeMultipart(boundary: String, jpeg: Data) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"upload_image\"; filename=\"frame.jpg\"\(lineBreak)")
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)")
        body.append(jpeg)
        body.append("\(lineBreak)--\(boundary)--\(lineBreak)")
        return body
    }
}

// MARK: - Check-in response types
struct CheckinResponse: Decodable {
    let stats: CheckinStats
    let result: [String: CheckinResult]
}

struct CheckinStats: Decodable {
    let numFace: Int
    let checkedIn: Int

    enum CodingKeys: String, CodingKey {
        case numFace = "num_face"
        case checkedIn = "checked_in"
    }
}

struct CheckinResult: Decodable {
    let success: Bool
    let data: CheckinData?
    let error: String?
}

struct CheckinData: Decodable {
    let userId: Int?
    let status: AttendanceStatus?
    let firstName: String?
    let lastName: String?
    let fullNameValue: String?
    let alreadyCheckedIn: Bool?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case firstName = "first_name"
        case lastName = "last_name"
        case fullNameSnake = "full_name"
        case fullNameCamel = "fullName"
        case name
        case alreadyCheckedIn = "already_checked_in"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        status = try container.decodeIfPresent(AttendanceStatus.self, forKey: .status)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        fullNameValue =
            try container.decodeIfPresent(String.self, forKey: .fullNameSnake) ??
            container.decodeIfPresent(String.self, forKey: .fullNameCamel) ??
            container.decodeIfPresent(String.self, forKey: .name)
        alreadyCheckedIn = try container.decodeIfPresent(Bool.self, forKey: .alreadyCheckedIn)
    }

    var fullName: String {
        let splitName = "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
        if !splitName.isEmpty {
            return splitName
        }
        return fullNameValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

// MARK: - Data helpers
private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) { append(d) }
    }
}

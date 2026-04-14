import Foundation

enum Constants {
    // MARK: - ngrok endpoints (update when tunnel restarts)
    static var baseURL: String {
        UserDefaults.standard.string(forKey: "baseURL")
            ?? "https://shayna-unswabbed-baroquely.ngrok-free.dev"
    }

    static var wsBaseURL: String {
        baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
    }

    enum Auth {
        static var login: String { "\(Constants.baseURL)/auth/login" }
        static var signup: String { "\(Constants.baseURL)/auth/signup" }
    }

    enum Event {
        static var getAllUserEvents: String { "\(Constants.baseURL)/protected/event/getAllUserEvents" }
        static var getManagedEvents: String { "\(Constants.baseURL)/protected/event/getManagedEvents" }
    }

    enum Session {
        static var getSessions: String { "\(Constants.baseURL)/protected/session/getSessions" }
        static var getAttendance: String { "\(Constants.baseURL)/protected/session/getAttendance" }
        static var checkin: String { "\(Constants.baseURL)/protected/session/checkin" }
        static var updateAttendanceStatus: String { "\(Constants.baseURL)/protected/session/updateAttendanceStatus" }
    }

    enum WebSocket {
        static func sessionURL(_ sessionId: Int) -> String {
            "\(Constants.wsBaseURL)/ws/session/\(sessionId)"
        }
    }

    // MARK: - UserDefaults keys
    enum Keys {
        static let token = "authToken"
        static let baseURL = "baseURL"
    }
}

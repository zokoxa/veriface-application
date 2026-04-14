import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct SignupRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case password
    }
}

struct UserWithToken: Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case token
    }
}

struct UserOutput: Decodable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }

    var fullName: String { "\(firstName) \(lastName)" }
}

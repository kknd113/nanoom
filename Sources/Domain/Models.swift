import Foundation

struct GroupMember: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var photoData: Data? = nil
    var initial: String { String(displayName.prefix(1)).uppercased() }
}

struct PrayerUpdate: Identifiable, Codable, Equatable {
    let id: String
    let body: String
    let createdAt: Date
}

struct Prayer: Identifiable, Codable, Equatable {
    let id: String
    let authorID: String
    var body: String
    let createdAt: Date
    var updates: [PrayerUpdate]
    var prayedBy: Set<String>
}

struct PrayerGroup: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var members: [GroupMember]
    var prayers: [Prayer]
    var ownerID: String? = nil
}

enum InvitationLink {
    static func url(code: String) -> URL { URL(string: "https://nanoom-kknd113.web.app/join#\(code)")! }
    static func validCode(_ value: String) -> String? {
        value.range(of: "^[a-fA-F0-9]{32}$", options: .regularExpression) != nil ? value.lowercased() : nil
    }
    static func code(from url: URL) -> String? {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.user == nil, parts.password == nil, parts.port == nil else { return nil }
        if parts.scheme?.lowercased() == "https",
           ["nanoom-kknd113.web.app", "nanoom-kknd113.firebaseapp.com"].contains(parts.host?.lowercased() ?? ""),
           ["/join", "/join/"].contains(parts.path), parts.query == nil {
            return validCode(parts.fragment ?? "")
        }
        if parts.scheme?.lowercased() == "nanoom", parts.host == "join",
           parts.path.isEmpty, parts.fragment == nil,
           let items = parts.queryItems, items.count == 1, items[0].name == "code" {
            return validCode(items[0].value ?? "")
        }
        return nil
    }
    static func code(fromInput input: String) -> String? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return validCode(value) ?? URL(string: value).flatMap { code(from: $0) }
    }
}

struct GroupInvitation {
    let groupID: String
    let groupName: String
    let expiresAt: Date
}

struct AppUser: Identifiable, Equatable {
    let id: String
    var displayName: String
}

enum ComposerRoute: Identifiable {
    case prayer
    case update(String)
    case edit(String)

    var id: String {
        switch self {
        case .prayer: return "new-prayer"
        case .update(let id): return "update-\(id)"
        case .edit(let id): return "edit-\(id)"
        }
    }
}

enum WithError: LocalizedError {
    case noGroup, notAuthor, emptyBody, missingConfiguration, membershipRequired
    var errorDescription: String? {
        switch self {
        case .noGroup: return "Your group couldn’t be found. Please try again."
        case .notAuthor: return "You can only change your own prayers."
        case .emptyBody: return "Add a few words before sharing."
        case .missingConfiguration: return "Firebase isn’t configured. Follow SETUP.md to connect your project."
        case .membershipRequired: return "Your account is ready. A group invitation is needed to continue."
        }
    }
}

import Foundation

struct GroupMember: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
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

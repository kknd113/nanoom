import Foundation

@MainActor
final class DemoPrayerRepository: PrayerRepository {
    static let userID = "demo-chris"
    private let defaults: UserDefaults
    private let storageKey = "with.demo.group.v1"
    private var group: PrayerGroup

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(PrayerGroup.self, from: data) {
            group = saved
        } else {
            group = Self.sampleGroup()
        }
    }

    func loadGroup(userID: String) async throws -> PrayerGroup { group }

    func setProfilePhoto(groupID: String, userID: String, data: Data?) async throws {
        guard userID == Self.userID, let index = group.members.firstIndex(where: { $0.id == userID }) else { throw WithError.notAuthor }
        group.members[index].photoData = data
        persist()
    }

    func createPrayer(groupID: String, authorID: String, body: String) async throws {
        let text = try validated(body)
        group.prayers.insert(Prayer(id: UUID().uuidString, authorID: authorID, body: text,
                                   createdAt: .now, updates: [], prayedBy: []), at: 0)
        persist()
    }

    func updatePrayer(groupID: String, prayerID: String, authorID: String, body: String) async throws {
        let index = try ownedIndex(prayerID, authorID: authorID)
        group.prayers[index].body = try validated(body)
        persist()
    }

    func deletePrayer(groupID: String, prayerID: String, authorID: String) async throws {
        let index = try ownedIndex(prayerID, authorID: authorID)
        group.prayers.remove(at: index)
        persist()
    }

    func addUpdate(groupID: String, prayerID: String, authorID: String, body: String) async throws {
        let index = try ownedIndex(prayerID, authorID: authorID)
        let update = PrayerUpdate(id: UUID().uuidString, body: try validated(body), createdAt: .now)
        group.prayers[index].updates.append(update)
        persist()
    }

    func setPrayed(groupID: String, prayerID: String, userID: String, prayed: Bool) async throws {
        guard let index = group.prayers.firstIndex(where: { $0.id == prayerID }) else { throw WithError.noGroup }
        guard group.prayers[index].authorID != userID else { return }
        if prayed { group.prayers[index].prayedBy.insert(userID) }
        else { group.prayers[index].prayedBy.remove(userID) }
        persist()
    }

    private func validated(_ body: String) throws -> String {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 2_000 else { throw WithError.emptyBody }
        return text
    }

    private func ownedIndex(_ id: String, authorID: String) throws -> Int {
        guard let index = group.prayers.firstIndex(where: { $0.id == id }) else { throw WithError.noGroup }
        guard group.prayers[index].authorID == authorID else { throw WithError.notAuthor }
        return index
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(group) { defaults.set(data, forKey: storageKey) }
    }

    private static func sampleGroup() -> PrayerGroup {
        let now = Date.now
        let members = [GroupMember(id: "anna", displayName: "Anna"),
                       GroupMember(id: "daniel", displayName: "Daniel"),
                       GroupMember(id: "sarah", displayName: "Sarah"),
                       GroupMember(id: "james", displayName: "James"),
                       GroupMember(id: "esther", displayName: "Esther"),
                       GroupMember(id: userID, displayName: "Chris")]
        let bodies = [
            "Tomorrow is my first day at a new job. Pray for a peaceful heart, and the courage to be myself.",
            "Dad has more tests this week. I’m trying to stay hopeful, but the waiting feels heavy.",
            "I’ve felt a little far from God lately. I’d love prayer for a quiet, honest way back.",
            "Nothing big. Just hoping to be more patient with my kids this week.",
            "Grateful for this little group. Praying we keep making room for one another."
        ]
        let prayers = zip(members.prefix(5), bodies).enumerated().map { index, pair in
            Prayer(id: "sample-\(pair.0.id)", authorID: pair.0.id, body: pair.1,
                   createdAt: now.addingTimeInterval(-Double(index + 1) * 7_200),
                   updates: index == 1 ? [PrayerUpdate(id: "daniel-update", body: "We had a good conversation with his doctor today. Thank you for remembering us.", createdAt: now.addingTimeInterval(-1_800))] : [],
                   prayedBy: [])
        }
        return PrayerGroup(id: "grace-demo", name: "Grace Group", members: members, prayers: prayers)
    }
}

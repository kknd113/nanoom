import Foundation

@MainActor
protocol PrayerRepository {
    func loadGroup(userID: String) async throws -> PrayerGroup
    func setProfilePhoto(groupID: String, userID: String, data: Data?) async throws
    func createPrayer(groupID: String, authorID: String, body: String) async throws
    func updatePrayer(groupID: String, prayerID: String, authorID: String, body: String) async throws
    func deletePrayer(groupID: String, prayerID: String, authorID: String) async throws
    func addUpdate(groupID: String, prayerID: String, authorID: String, body: String) async throws
    func setPrayed(groupID: String, prayerID: String, userID: String, prayed: Bool) async throws
}

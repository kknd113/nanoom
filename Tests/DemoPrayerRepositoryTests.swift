import XCTest
@testable import With

@MainActor
final class DemoPrayerRepositoryTests: XCTestCase {
    func testUpdatesAppendWithoutReplacingEarlierUpdates() async throws {
        let suite = "with.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = DemoPrayerRepository(defaults: defaults)
        try await repository.createPrayer(groupID: "grace-demo", authorID: DemoPrayerRepository.userID, body: "Pray for peace.")
        let group = try await repository.loadGroup(userID: DemoPrayerRepository.userID)
        let prayer = try XCTUnwrap(group.prayers.first)
        try await repository.addUpdate(groupID: group.id, prayerID: prayer.id, authorID: prayer.authorID, body: "Still waiting.")
        try await repository.addUpdate(groupID: group.id, prayerID: prayer.id, authorID: prayer.authorID, body: "A little progress.")
        let reloaded = DemoPrayerRepository(defaults: defaults)
        let saved = try await reloaded.loadGroup(userID: DemoPrayerRepository.userID)
        XCTAssertEqual(saved.prayers.first?.updates.map(\.body), ["Still waiting.", "A little progress."])
    }

    func testAnotherMemberCannotEditSomeoneElsesPrayer() async throws {
        let suite = "with.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = DemoPrayerRepository(defaults: defaults)
        do {
            try await repository.updatePrayer(groupID: "grace-demo", prayerID: "sample-anna", authorID: DemoPrayerRepository.userID, body: "Changed")
            XCTFail("Another member must not be able to edit this prayer")
        } catch WithError.notAuthor {} catch { XCTFail("Unexpected error: \(error)") }
    }

    func testRepeatedReactionDoesNotCreateDuplicatePeople() async throws {
        let suite = "with.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = DemoPrayerRepository(defaults: defaults)
        for _ in 0..<2 {
            try await repository.setPrayed(groupID: "grace-demo", prayerID: "sample-anna", userID: DemoPrayerRepository.userID, prayed: true)
        }
        let group = try await repository.loadGroup(userID: DemoPrayerRepository.userID)
        XCTAssertEqual(group.prayers.first { $0.id == "sample-anna" }?.prayedBy.count, 1)
    }
}

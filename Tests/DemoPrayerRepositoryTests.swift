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

@MainActor
final class InvitationAndPhotoTests: XCTestCase {
    func testInvitationLinksRoundTripAndRejectUntrustedInputs() {
        let code = "0123456789abcdef0123456789abcdef"
        XCTAssertEqual(InvitationLink.code(from: InvitationLink.url(code: code)), code)
        XCTAssertEqual(InvitationLink.code(from: URL(string: "nanoom://join?code=\(code)")!), code)
        XCTAssertEqual(InvitationLink.code(fromInput: "  \(InvitationLink.url(code: code))  "), code)
        for input in ["https://evil.example/join#\(code)", "http://nanoom-kknd113.web.app/join#\(code)",
                      "https://nanoom-kknd113.web.app/other#\(code)", "nanoom://join?code=\(code)&code=\(code)",
                      "nanoom://join?code=short", "nanoom://other?code=\(code)",
                      "https://nanoom-kknd113.web.app/join?tracking=1#\(code)"] {
            XCTAssertNil(InvitationLink.code(from: URL(string: input)!), input)
        }
    }

    func testOwnPhotoPersistsAndCanBeRemoved() async throws {
        let suite = "nanoom.photo.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let data = Data([1, 2, 3])
        let repository = DemoPrayerRepository(defaults: defaults)
        try await repository.setProfilePhoto(groupID: "grace-demo", userID: DemoPrayerRepository.userID, data: data)
        let reloaded = DemoPrayerRepository(defaults: defaults)
        let saved = try await reloaded.loadGroup(userID: DemoPrayerRepository.userID)
        XCTAssertEqual(saved.members.first { $0.id == DemoPrayerRepository.userID }?.photoData, data)
        try await reloaded.setProfilePhoto(groupID: "grace-demo", userID: DemoPrayerRepository.userID, data: nil)
        let removed = try await reloaded.loadGroup(userID: DemoPrayerRepository.userID)
        XCTAssertNil(removed.members.first { $0.id == DemoPrayerRepository.userID }?.photoData)
    }

    func testPhotoCannotChangeAnotherMember() async throws {
        let repository = DemoPrayerRepository(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        do {
            try await repository.setProfilePhoto(groupID: "grace-demo", userID: "anna", data: Data([1]))
            XCTFail("Another member photo must not be writable")
        } catch WithError.notAuthor {} catch { XCTFail("Unexpected error: \(error)") }
    }
}

@MainActor
final class InvitationPendingStateTests: XCTestCase {
    func testInvitationSurvivesLoginAndAppModelRecreation() {
        let key = "nanoom.pendingInvitation"
        let previous = UserDefaults.standard.object(forKey: key)
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let code = "0123456789abcdef0123456789abcdef"
        let model = AppModel(repository: DemoPrayerRepository(), isDemo: false)
        model.receiveInvitation(InvitationLink.url(code: code))
        let restored = AppModel(repository: DemoPrayerRepository(), isDemo: false)
        XCTAssertEqual(restored.pendingInviteCode, code)
        restored.clearInvitation()
        XCTAssertNil(AppModel(repository: DemoPrayerRepository(), isDemo: false).pendingInviteCode)
    }
}

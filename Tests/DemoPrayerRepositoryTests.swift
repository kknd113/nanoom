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
    func testIncomingInvitationWaitsForPrayerUpdateAndEditComposers() async throws {
        let key = "nanoom.pendingInvitation"
        let previous = UserDefaults.standard.object(forKey: key)
        let suite = "nanoom.invitation-writing.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer {
            defaults.removePersistentDomain(forName: suite)
            if let previous { UserDefaults.standard.set(previous, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let repository = DemoPrayerRepository(defaults: defaults)
        let model = AppModel(repository: repository, isDemo: false)
        model.user = AppUser(id: DemoPrayerRepository.userID, displayName: "Synthetic writer")
        model.group = try await repository.loadGroup(userID: DemoPrayerRepository.userID)
        let originalGroupID = model.group?.id
        let code = "0123456789abcdef0123456789abcdef"

        for route in [ComposerRoute.prayer, .update("sample-chris"), .edit("sample-chris")] {
            model.composer = route
            model.receiveInvitation(InvitationLink.url(code: code))
            XCTAssertEqual(model.composer?.id, route.id, "Receiving a link must keep the writer's sheet alive")
            XCTAssertEqual(model.group?.id, originalGroupID, "Writing must stay in the original circle")
            XCTAssertEqual(model.pendingInviteCode, code)
            XCTAssertFalse(model.shouldPresentInvitation)

            model.composer = nil
            XCTAssertTrue(model.shouldPresentInvitation, "Show the queued invitation after writing ends")
        }
    }

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

@MainActor
private final class SuspendedGroupRepository: PrayerRepository {
    var requests: [CheckedContinuation<PrayerGroup, Error>] = []
    func loadGroup(userID: String) async throws -> PrayerGroup {
        try await withCheckedThrowingContinuation { requests.append($0) }
    }
    func setProfilePhoto(groupID: String, userID: String, data: Data?) async throws { throw WithError.noGroup }
    func createPrayer(groupID: String, authorID: String, body: String) async throws { throw WithError.noGroup }
    func updatePrayer(groupID: String, prayerID: String, authorID: String, body: String) async throws { throw WithError.noGroup }
    func deletePrayer(groupID: String, prayerID: String, authorID: String) async throws { throw WithError.noGroup }
    func addUpdate(groupID: String, prayerID: String, authorID: String, body: String) async throws { throw WithError.noGroup }
    func setPrayed(groupID: String, prayerID: String, userID: String, prayed: Bool) async throws { throw WithError.noGroup }
}

@MainActor
final class SessionRefreshTests: XCTestCase {
    private func waitForRequests(_ count: Int, in repository: SuspendedGroupRepository) async {
        for _ in 0..<100 {
            if repository.requests.count >= count { return }
            await Task.yield()
        }
    }
    func testInFlightRefreshCannotRestoreGroupAfterSignOut() async throws {
        let repository = SuspendedGroupRepository()
        let model = AppModel(repository: repository, isDemo: true)
        model.user = AppUser(id: "old-user", displayName: "Old")
        let request = Task { await model.refresh() }
        await waitForRequests(1, in: repository)
        let continuation = try XCTUnwrap(repository.requests.first)
        model.signOut()
        continuation.resume(returning: PrayerGroup(id: "private-old-group", name: "Private", members: [], prayers: []))
        await request.value
        XCTAssertNil(model.user)
        XCTAssertNil(model.group)
        XCTAssertFalse(model.isLoading)
    }
    func testSlowerRefreshCannotReplaceNewerCircle() async throws {
        let repository = SuspendedGroupRepository()
        let model = AppModel(repository: repository, isDemo: true)
        model.user = AppUser(id: "user", displayName: "Person")
        let old = Task { await model.refresh() }
        await waitForRequests(1, in: repository)
        let new = Task { await model.refresh() }
        await waitForRequests(2, in: repository)
        XCTAssertEqual(repository.requests.count, 2)
        guard repository.requests.count == 2 else { return }
        repository.requests[1].resume(returning: PrayerGroup(id: "new", name: "New circle", members: [], prayers: []))
        await new.value
        repository.requests[0].resume(returning: PrayerGroup(id: "old", name: "Old circle", members: [], prayers: []))
        await old.value
        XCTAssertEqual(model.group?.id, "new")
        XCTAssertFalse(model.isLoading)
    }
}

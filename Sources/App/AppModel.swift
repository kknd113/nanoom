import Foundation
import Observation
#if FIREBASE_ENABLED
import FirebaseAuth
import FirebaseCore
#endif

@MainActor @Observable
final class AppModel {
    private let repository: any PrayerRepository
    @ObservationIgnored private var refreshGeneration = 0
    var user: AppUser?
    var group: PrayerGroup?
    var selectedMemberID = "anna"
    var path: [String] = []
    var composer: ComposerRoute?
    var errorMessage: String?
    var isLoading = false
    var hapticTrigger = 0
    var isDemo: Bool
    var inviteCode: String?
    var pendingInviteCode: String?
    var makingInvitation = false

    init(repository: any PrayerRepository, isDemo: Bool) {
        self.repository = repository
        self.isDemo = isDemo
        pendingInviteCode = isDemo ? nil : UserDefaults.standard.string(forKey: "nanoom.pendingInvitation")
    }

    func receiveInvitation(_ url: URL) {
        guard let code = InvitationLink.code(from: url) else { errorMessage = "This invitation link isn’t valid."; return }
        // Keep the current circle and its in-memory draft until the writer finishes.
        pendingInviteCode = code
        UserDefaults.standard.set(code, forKey: "nanoom.pendingInvitation")
    }

    func clearInvitation() {
        pendingInviteCode = nil
        UserDefaults.standard.removeObject(forKey: "nanoom.pendingInvitation")
    }

    var shouldPresentInvitation: Bool {
        user != nil && pendingInviteCode != nil && !isDemo && composer == nil
    }

    @discardableResult
    func saveProfilePhoto(_ data: Data?) async -> Bool {
        guard let group, let user else { return false }
        do {
            try await repository.setProfilePhoto(groupID: group.id, userID: user.id, data: data)
            guard self.user?.id == user.id, self.group?.id == group.id else { return false }
            await refresh()
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func startDemo() async {
        user = AppUser(id: DemoPrayerRepository.userID, displayName: "Chris")
        await refresh()
    }

    func signedIn(id: String, name: String) async {
        if user?.id != id {
            group = nil; path = []; inviteCode = nil
        }
        user = AppUser(id: id, displayName: name)
        #if FIREBASE_ENABLED
        do { try await (repository as? FirebasePrayerRepository)?.prepareSession(userID: id) }
        catch {
            guard user?.id == id else { return }
            errorMessage = error.localizedDescription
            return
        }
        guard user?.id == id else { return }
        #endif
        await refresh()
    }

    func restoreSession() async {
        #if FIREBASE_ENABLED
        guard !isDemo, FirebaseApp.app() != nil, let current = Auth.auth().currentUser else { return }
        await signedIn(id: current.uid, name: current.displayName ?? "Friend")
        #endif
    }

    func signOut() {
        #if FIREBASE_ENABLED
        do { try Auth.auth().signOut() } catch { errorMessage = error.localizedDescription; return }
        #endif
        user = nil; group = nil; path = []; inviteCode = nil; composer = nil
        refreshGeneration += 1
        isLoading = false
    }

    #if FIREBASE_ENABLED
    func enterGroup(name: String, code: String) async {
        guard let user, let live = repository as? FirebasePrayerRepository else { return }
        isLoading = true
        do {
            if code.isEmpty { try await live.createGroup(name: name, user: user) }
            else { try await live.joinGroup(code: code, user: user) }
            guard self.user?.id == user.id else { return }
            path = []; inviteCode = nil
            if pendingInviteCode == InvitationLink.code(fromInput: code) { clearInvitation() }
            errorMessage = nil
            await refresh()
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func makeInvitation() async {
        guard let group, let live = repository as? FirebasePrayerRepository else { return }
        guard !makingInvitation else { return }
        makingInvitation = true
        defer { makingInvitation = false }
        let userID = user?.id
        do {
            let code = try await live.createInvitation(groupID: group.id)
            guard self.group?.id == group.id, user?.id == userID else { return }
            inviteCode = code
        }
        catch { errorMessage = error.localizedDescription }
    }
    #endif

    func refresh() async {
        guard let user else { return }
        refreshGeneration += 1
        let generation = refreshGeneration
        isLoading = true
        defer { if generation == refreshGeneration { isLoading = false } }
        do {
            let loaded = try await repository.loadGroup(userID: user.id)
            guard self.user?.id == user.id, generation == refreshGeneration else { return }
            group = loaded
            if !others.contains(where: { $0.id == selectedMemberID }) {
                selectedMemberID = others.first?.id ?? ""
            }
        } catch {
            guard self.user?.id == user.id, generation == refreshGeneration else { return }
            if case WithError.membershipRequired = error { group = nil }
            else { errorMessage = error.localizedDescription }
        }
    }

    var others: [GroupMember] { group?.members.filter { $0.id != user?.id } ?? [] }
    var selectedMember: GroupMember? { others.first { $0.id == selectedMemberID } }
    var selectedPrayers: [Prayer] { prayers(for: selectedMemberID) }
    var myPrayers: [Prayer] { prayers(for: user?.id ?? "") }

    func prayers(for id: String) -> [Prayer] {
        group?.prayers.filter { $0.authorID == id }.sorted { $0.createdAt > $1.createdAt } ?? []
    }
    func prayer(id: String) -> Prayer? { group?.prayers.first { $0.id == id } }
    func author(of prayer: Prayer) -> GroupMember? { group?.members.first { $0.id == prayer.authorID } }

    @discardableResult
    func save(body: String, route: ComposerRoute) async -> Bool {
        guard let group, let user else { return false }
        do {
            switch route {
            case .prayer: try await repository.createPrayer(groupID: group.id, authorID: user.id, body: body)
            case .update(let id): try await repository.addUpdate(groupID: group.id, prayerID: id, authorID: user.id, body: body)
            case .edit(let id): try await repository.updatePrayer(groupID: group.id, prayerID: id, authorID: user.id, body: body)
            }
            await refresh()
            hapticTrigger += 1
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func togglePrayer(_ prayer: Prayer) async {
        guard let user, let group else { return }
        do {
            try await repository.setPrayed(groupID: group.id, prayerID: prayer.id, userID: user.id,
                                            prayed: !prayer.prayedBy.contains(user.id))
            await refresh()
            hapticTrigger += 1
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ prayer: Prayer) async {
        guard let user, let group else { return }
        do {
            try await repository.deletePrayer(groupID: group.id, prayerID: prayer.id, authorID: user.id)
            path.removeAll { $0 == prayer.id }
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }
}

import Foundation
import Observation

@MainActor @Observable
final class AppModel {
    private let repository: any PrayerRepository
    var user: AppUser?
    var group: PrayerGroup?
    var selectedMemberID = "anna"
    var path: [String] = []
    var composer: ComposerRoute?
    var errorMessage: String?
    var isLoading = false
    var hapticTrigger = 0
    var isDemo: Bool

    init(repository: any PrayerRepository, isDemo: Bool) {
        self.repository = repository
        self.isDemo = isDemo
    }

    func startDemo() async {
        user = AppUser(id: DemoPrayerRepository.userID, displayName: "Chris")
        await refresh()
    }

    func signedIn(id: String, name: String) async {
        user = AppUser(id: id, displayName: name)
        await refresh()
    }

    func refresh() async {
        guard let user else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            group = try await repository.loadGroup(userID: user.id)
            if !others.contains(where: { $0.id == selectedMemberID }) {
                selectedMemberID = others.first?.id ?? ""
            }
        } catch { errorMessage = error.localizedDescription }
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

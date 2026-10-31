#if FIREBASE_ENABLED
import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Spark-plan adapter. Group membership is checked by Firestore rules in atomic batches.
@MainActor
final class FirebasePrayerRepository: PrayerRepository {
    private static var sessionUserID: String?
    private static var sessionGeneration = 0
    private static var activeLoads = 0
    private static var preparingSession = false
    private var db: Firestore { get throws { try database() } }

    /// A different account must start with a fresh client and an empty private cache.
    func prepareSession(userID: String) async throws {
        while Self.preparingSession { try await Task.sleep(for: .milliseconds(20)) }
        Self.preparingSession = true
        defer { Self.preparingSession = false }
        guard Auth.auth().currentUser?.uid == userID else { throw CancellationError() }
        if let previous = Self.sessionUserID, previous != userID {
            // Let readers release their captured client before replacing it.
            while Self.activeLoads > 0 { try await Task.sleep(for: .milliseconds(20)) }
            guard Auth.auth().currentUser?.uid == userID else { throw CancellationError() }
            Self.sessionGeneration += 1
            try await database().terminate()
            let fresh = Firestore.firestore()
            let settings = FirestoreSettings()
            settings.cacheSettings = MemoryCacheSettings()
            fresh.settings = settings
        }
        Self.sessionUserID = userID
    }

    func createGroup(name: String, user: AppUser) async throws {
        guard !name.isEmpty, name.count <= 60 else { throw GroupError.invalidName }
        let db = try db
        let group = db.collection("groups").document()
        let batch = db.batch()
        batch.setData(["name": name, "ownerID": user.id, "createdAt": FieldValue.serverTimestamp()], forDocument: group)
        batch.setData(["displayName": user.displayName, "inviteID": "", "joinedAt": FieldValue.serverTimestamp()], forDocument: group.collection("members").document(user.id))
        batch.setData(["joinedAt": FieldValue.serverTimestamp()], forDocument: db.collection("users").document(user.id).collection("groupMemberships").document(group.documentID))
        try await batch.commit()
        UserDefaults.standard.set(group.documentID, forKey: "nanoom.activeGroup.\(user.id)")
    }

    func joinGroup(code: String, user: AppUser) async throws {
        let generation = Self.sessionGeneration
        guard let token = InvitationLink.code(fromInput: code) else { throw GroupError.invalidInvitation }
        let db = try db
        let invitation = try await previewInvitation(code: token)
        guard generation == Self.sessionGeneration, Auth.auth().currentUser?.uid == user.id else { throw CancellationError() }
        let groupID = invitation.groupID
        let existing = try await db.collection("users").document(user.id).collection("groupMemberships").document(groupID).getDocument()
        guard generation == Self.sessionGeneration, Auth.auth().currentUser?.uid == user.id else { throw CancellationError() }
        if existing.exists {
            UserDefaults.standard.set(groupID, forKey: "nanoom.activeGroup.\(user.id)")
            return
        }
        let batch = db.batch()
        let member = db.collection("groups").document(groupID).collection("members").document(user.id)
        batch.setData(["displayName": user.displayName, "inviteID": token, "joinedAt": FieldValue.serverTimestamp()], forDocument: member)
        batch.setData(["joinedAt": FieldValue.serverTimestamp()], forDocument: db.collection("users").document(user.id).collection("groupMemberships").document(groupID))
        try await batch.commit()
        UserDefaults.standard.set(groupID, forKey: "nanoom.activeGroup.\(user.id)")
    }

    func createInvitation(groupID: String) async throws -> String {
        let generation = Self.sessionGeneration
        let db = try db
        guard let userID = Auth.auth().currentUser?.uid else { throw GroupError.invalidInvitation }
        let group = try await db.collection("groups").document(groupID).getDocument()
        guard generation == Self.sessionGeneration, Auth.auth().currentUser?.uid == userID else { throw CancellationError() }
        guard let groupName = group.data()?["name"] as? String else { throw WithError.noGroup }
        let code = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        try await db.collection("invitations").document(code).setData([
            "groupID": groupID, "groupName": groupName, "ownerID": userID, "createdAt": FieldValue.serverTimestamp(),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(7 * 24 * 60 * 60))
        ])
        return code
    }

    func revokeInvitation(code: String) async throws {
        try await db.collection("invitations").document(code).delete()
    }

    func previewInvitation(code: String) async throws -> GroupInvitation {
        guard let token = InvitationLink.validCode(code) else { throw GroupError.invalidInvitation }
        let snapshot = try await db.collection("invitations").document(token).getDocument()
        guard let data = snapshot.data(), let groupID = data["groupID"] as? String,
              let expires = data["expiresAt"] as? Timestamp, expires.dateValue() > Date() else { throw GroupError.invalidInvitation }
        return GroupInvitation(groupID: groupID, groupName: data["groupName"] as? String ?? "Your prayer circle", expiresAt: expires.dateValue())
    }

    func setProfilePhoto(groupID: String, userID: String, data: Data?) async throws {
        let reference = try db.collection("groups").document(groupID).collection("memberPhotos").document(userID)
        if let data {
            guard !data.isEmpty, data.count <= 65_536 else { throw GroupError.invalidPhoto }
            try await reference.setData(["image": data, "updatedAt": FieldValue.serverTimestamp()])
        } else { try await reference.delete() }
    }

    enum GroupError: LocalizedError {
        case invalidName, invalidInvitation, invalidPhoto
        var errorDescription: String? {
            switch self {
            case .invalidPhoto: return "This photo couldn’t be saved. Try another image."
            case .invalidName: return "Choose a group name between 1 and 60 characters."
            case .invalidInvitation: return "This invitation is invalid or has expired. Ask your group leader for a new one."
            }
        }
    }
    private func database() throws -> Firestore {
        guard FirebaseApp.app() != nil else { throw WithError.missingConfiguration }
        return Firestore.firestore()
    }

    func loadGroup(userID: String) async throws -> PrayerGroup {
        Self.activeLoads += 1
        defer { Self.activeLoads -= 1 }
        let db = try database()
        let memberships = db.collection("users").document(userID).collection("groupMemberships")
        let groupID: String
        if let preferred = UserDefaults.standard.string(forKey: "nanoom.activeGroup.\(userID)"),
           try await memberships.document(preferred).getDocument().exists {
            groupID = preferred
        } else {
            guard let first = try await memberships.limit(to: 1).getDocuments().documents.first else { throw WithError.membershipRequired }
            groupID = first.documentID
        }
        let reference = db.collection("groups").document(groupID)
        let groupDocument = try await reference.getDocument()
        guard let name = groupDocument.data()?["name"] as? String else { throw WithError.noGroup }
        let memberDocuments = try await reference.collection("members").getDocuments()
        let photos = try await reference.collection("memberPhotos").getDocuments()
        let photoData = Dictionary(uniqueKeysWithValues: photos.documents.compactMap { doc -> (String, Data)? in
            guard let image = doc.data()["image"] as? Data else { return nil }
            return (doc.documentID, image)
        })
        let members = memberDocuments.documents.compactMap { doc -> GroupMember? in
            guard let name = doc.data()["displayName"] as? String else { return nil }
            return GroupMember(id: doc.documentID, displayName: name, photoData: photoData[doc.documentID])
        }.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        let prayerDocuments = try await reference.collection("prayers").order(by: "createdAt", descending: true).limit(to: 100).getDocuments()
        var prayers: [Prayer] = []
        for document in prayerDocuments.documents {
            let data = document.data()
            if data["deleted"] as? Bool == true { continue }
            guard let authorID = data["authorID"] as? String, let body = data["body"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else { continue }
            let updateDocuments = try await document.reference.collection("updates").order(by: "createdAt").getDocuments()
            let updates = updateDocuments.documents.compactMap { doc -> PrayerUpdate? in
                guard let body = doc.data()["body"] as? String, let date = doc.data()["createdAt"] as? Timestamp else { return nil }
                return PrayerUpdate(id: doc.documentID, body: body, createdAt: date.dateValue())
            }
            let reactionDocuments = try await document.reference.collection("reactions").getDocuments()
            prayers.append(Prayer(id: document.documentID, authorID: authorID, body: body,
                                  createdAt: timestamp.dateValue(), updates: updates,
                                  prayedBy: Set(reactionDocuments.documents.map(\.documentID))))
        }
        return PrayerGroup(id: groupID, name: name, members: members, prayers: prayers, ownerID: groupDocument.data()?["ownerID"] as? String)
    }

    func createPrayer(groupID: String, authorID: String, body: String) async throws {
        let db = try database()
        _ = try await db.collection("groups").document(groupID).collection("prayers").addDocument(data: [
            "authorID": authorID, "body": body, "createdAt": FieldValue.serverTimestamp(), "deleted": false
        ])
    }

    func updatePrayer(groupID: String, prayerID: String, authorID: String, body: String) async throws {
        let db = try database()
        try await db.collection("groups").document(groupID).collection("prayers").document(prayerID).updateData(["body": body])
    }

    func deletePrayer(groupID: String, prayerID: String, authorID: String) async throws {
        // Hide the entire thread and erase its main text; rules also close access to children.
        try await db.collection("groups").document(groupID).collection("prayers").document(prayerID)
            .updateData(["body": "", "deleted": true])
    }

    func addUpdate(groupID: String, prayerID: String, authorID: String, body: String) async throws {
        let db = try database()
        _ = try await db.collection("groups").document(groupID).collection("prayers").document(prayerID)
            .collection("updates").addDocument(data: ["authorID": authorID, "body": body, "createdAt": FieldValue.serverTimestamp()])
    }

    func setPrayed(groupID: String, prayerID: String, userID: String, prayed: Bool) async throws {
        let db = try database()
        let reference = db.collection("groups").document(groupID).collection("prayers").document(prayerID)
            .collection("reactions").document(userID)
        if prayed { try await reference.setData(["createdAt": FieldValue.serverTimestamp()]) }
        else { try await reference.delete() }
    }

}
#endif

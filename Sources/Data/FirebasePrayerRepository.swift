#if FIREBASE_ENABLED
import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Spark-plan adapter. Group membership is checked by Firestore rules in atomic batches.
@MainActor
final class FirebasePrayerRepository: PrayerRepository {
    private var db: Firestore { get throws { try database() } }

    func createGroup(name: String, user: AppUser) async throws {
        guard !name.isEmpty, name.count <= 60 else { throw GroupError.invalidName }
        let db = try db
        let group = db.collection("groups").document()
        let batch = db.batch()
        batch.setData(["name": name, "ownerID": user.id, "createdAt": FieldValue.serverTimestamp()], forDocument: group)
        batch.setData(["displayName": user.displayName, "inviteID": "", "joinedAt": FieldValue.serverTimestamp()], forDocument: group.collection("members").document(user.id))
        batch.setData(["joinedAt": FieldValue.serverTimestamp()], forDocument: db.collection("users").document(user.id).collection("groupMemberships").document(group.documentID))
        try await batch.commit()
    }

    func joinGroup(code: String, user: AppUser) async throws {
        guard code.count == 32, code.allSatisfy({ $0.isHexDigit }) else { throw GroupError.invalidInvitation }
        let db = try db
        let invitation = try await db.collection("invitations").document(code.lowercased()).getDocument()
        guard let data = invitation.data(), let groupID = data["groupID"] as? String,
              let expires = data["expiresAt"] as? Timestamp, expires.dateValue() > Date() else { throw GroupError.invalidInvitation }
        let batch = db.batch()
        let member = db.collection("groups").document(groupID).collection("members").document(user.id)
        batch.setData(["displayName": user.displayName, "inviteID": code.lowercased(), "joinedAt": FieldValue.serverTimestamp()], forDocument: member)
        batch.setData(["joinedAt": FieldValue.serverTimestamp()], forDocument: db.collection("users").document(user.id).collection("groupMemberships").document(groupID))
        try await batch.commit()
    }

    func createInvitation(groupID: String) async throws -> String {
        let db = try db
        guard let userID = Auth.auth().currentUser?.uid else { throw GroupError.invalidInvitation }
        let code = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        try await db.collection("invitations").document(code).setData([
            "groupID": groupID, "ownerID": userID, "createdAt": FieldValue.serverTimestamp(),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(7 * 24 * 60 * 60))
        ])
        return code
    }

    func revokeInvitation(code: String) async throws {
        try await db.collection("invitations").document(code).delete()
    }

    enum GroupError: LocalizedError {
        case invalidName, invalidInvitation
        var errorDescription: String? {
            switch self {
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
        let db = try database()
        let memberships = try await db.collection("users").document(userID).collection("groupMemberships").limit(to: 1).getDocuments()
        guard let membership = memberships.documents.first else { throw WithError.membershipRequired }
        let reference = db.collection("groups").document(membership.documentID)
        let groupDocument = try await reference.getDocument()
        guard let name = groupDocument.data()?["name"] as? String else { throw WithError.noGroup }
        let memberDocuments = try await reference.collection("members").getDocuments()
        let members = memberDocuments.documents.compactMap { doc -> GroupMember? in
            guard let name = doc.data()["displayName"] as? String else { return nil }
            return GroupMember(id: doc.documentID, displayName: name)
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
        return PrayerGroup(id: membership.documentID, name: name, members: members, prayers: prayers)
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

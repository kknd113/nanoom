#if FIREBASE_ENABLED
import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Live adapter scaffold. Invitations, account deletion, and realtime listeners remain integration work.
@MainActor
final class FirebasePrayerRepository: PrayerRepository {
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
            "authorID": authorID, "body": body, "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func updatePrayer(groupID: String, prayerID: String, authorID: String, body: String) async throws {
        let db = try database()
        try await db.collection("groups").document(groupID).collection("prayers").document(prayerID).updateData(["body": body])
    }

    func deletePrayer(groupID: String, prayerID: String, authorID: String) async throws {
        // Deleting only the parent leaves subcollections behind. Require a server-side recursive delete.
        throw LiveIntegrationError.serverDeletionRequired
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

    enum LiveIntegrationError: LocalizedError {
        case serverDeletionRequired
        var errorDescription: String? { "Live deletion needs the server cleanup endpoint. Use the demo scheme until that integration is complete." }
    }
}
#endif

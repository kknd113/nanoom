import SwiftUI
#if FIREBASE_ENABLED
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
#endif

@main
struct WithApp: App {
    @State private var model: AppModel

    init() {
        #if FIREBASE_ENABLED
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            let settings = FirestoreSettings()
            settings.cacheSettings = MemoryCacheSettings()
            Firestore.firestore().settings = settings
        }
        _model = State(initialValue: AppModel(repository: FirebasePrayerRepository(), isDemo: false))
        #else
        _model = State(initialValue: AppModel(repository: DemoPrayerRepository(), isDemo: true))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            appContent.environment(model)
                .tint(.withAccent)
                .sensoryFeedback(.success, trigger: model.hapticTrigger)
        }
    }
    @ViewBuilder
    private var appContent: some View {
        #if DEBUG && !FIREBASE_ENABLED && targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--preview-circle-invitation") {
            NavigationStack {
                CircleInvitationView(
                    invitation: arguments.contains("--preview-invite-error") || arguments.contains("--preview-invite-loading") ? nil :
                        GroupInvitation(groupID: "synthetic-preview", groupName: "Grace Community Wednesday Evening Prayer Circle", expiresAt: .now.addingTimeInterval(604800)),
                    loading: arguments.contains("--preview-invite-loading"), joining: false, issue: nil,
                    join: {}, retry: {}, cancel: {})
            }
        } else { RootView() }
        #else
        RootView()
        #endif
    }

}

struct RootView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        @Bindable var model = model
        Group {
            if model.shouldPresentInvitation {
                #if FIREBASE_ENABLED
                InvitationJoinView(code: model.pendingInviteCode!)
                #endif
            } else if model.user != nil && model.group != nil {
                NavigationStack(path: $model.path) {
                    CircleHomeView()
                        .navigationDestination(for: String.self) { id in
                            if id == "__mine" { MyPrayersView() }
                            else { PrayerDetailView(prayerID: id) }
                        }
                }
            } else if model.user != nil {
                #if FIREBASE_ENABLED
                GroupEntryView()
                #endif
            } else {
                WelcomeView()
            }
        }
        .background(Color.withPaper.ignoresSafeArea())
        .onOpenURL { model.receiveInvitation($0) }
        .task {
            #if DEBUG && FIREBASE_ENABLED && targetEnvironment(simulator)
            if await NativeFlowVerification.runIfRequested(model: model) { return }
            if await NativeAuthVerification.runIfRequested() { return }
            #endif
            await model.restoreSession()
        }
        .sheet(item: $model.composer) { route in PrayerComposerView(route: route).environment(model) }
        .alert("Something needs attention", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .overlay { if model.isLoading { ProgressView().padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18)) } }
    }
}

#if DEBUG && FIREBASE_ENABLED && targetEnvironment(simulator)
/// Explicitly requested integration fixture. Run only on an otherwise signed-out simulator.
@MainActor
private enum NativeFlowVerification {
    private static var started = false
    private static let manifestURL = URL.documentsDirectory.appendingPathComponent("nanoom-qa-manifest.json")
    private struct Manifest: Codable {
        var ownerID: String
        var userIDs: [String]
        var groupID: String?
        var invitationID: String?
    }
    private enum Failure: Error { case assertion(String), occupiedSimulator }

    static func runIfRequested(model: AppModel) async -> Bool {
        let args = ProcessInfo.processInfo.arguments
        let verify = args.contains("--verify-native-flow")
        let clean = args.contains("--cleanup-native-flow")
        guard verify || clean else { return false }
        guard !started else { return true }
        started = true
        guard FirebaseApp.app() != nil else {
            NSLog("NANOOM_FLOW BLOCKED: missing Firebase configuration")
            return true
        }
        let auth = Auth.auth()
        if clean {
            do {
                let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
                guard let user = auth.currentUser, manifest.userIDs.contains(user.uid),
                      (user.email?.hasPrefix("nanoom-flow-owner-") == true || user.email?.hasPrefix("nanoom-flow-member-") == true),
                      user.email?.hasSuffix("@example.com") == true else { throw Failure.occupiedSimulator }
                do { try await user.delete() }
                catch { NSLog("NANOOM_FLOW cleanup: synthetic account deletion needs trusted manifest review") }
                try auth.signOut()
                for uid in manifest.userIDs { UserDefaults.standard.removeObject(forKey: "nanoom.activeGroup.\(uid)") }
                model.clearInvitation()
                model.user = nil; model.group = nil; model.path = []; model.composer = nil
                NSLog("NANOOM_FLOW PASS: synthetic session cleared; manifest retained for trusted cleanup")
            } catch { NSLog("NANOOM_FLOW FAIL: cleanup refused or failed: %@", String(describing: error)) }
            return true
        }
        guard auth.currentUser == nil else {
            NSLog("NANOOM_FLOW BLOCKED: an account is already signed in; no account modified")
            return true
        }
        guard !FileManager.default.fileExists(atPath: manifestURL.path) else {
            NSLog("NANOOM_FLOW BLOCKED: review the previous cleanup manifest before a new run")
            return true
        }
        let run = UUID().uuidString.lowercased()
        let password = UUID().uuidString + "Aa1!"
        let ownerEmail = "nanoom-flow-owner-\(run)@example.com"
        let memberEmail = "nanoom-flow-member-\(run)@example.com"
        var manifest = Manifest(ownerID: "", userIDs: [])
        var createdEmails: [String] = []
        func record() throws { try JSONEncoder().encode(manifest).write(to: manifestURL, options: .atomic) }
        func check(_ condition: Bool, _ name: String) throws {
            guard condition else { throw Failure.assertion(name) }
            NSLog("NANOOM_FLOW PASS: %@", name)
        }
        do {
            let repository = FirebasePrayerRepository()
            let owner = try await auth.createUser(withEmail: ownerEmail, password: password).user
            createdEmails.append(ownerEmail)
            manifest.ownerID = owner.uid; manifest.userIDs.append(owner.uid); try record()
            let ownerProfile = auth.currentUser!.createProfileChangeRequest()
            ownerProfile.displayName = "QA Owner"; try await ownerProfile.commitChanges()
            try await repository.createGroup(name: "Nanoom QA \(run.prefix(8))", user: AppUser(id: owner.uid, displayName: "QA Owner"))
            await model.signedIn(id: owner.uid, name: "QA Owner")
            guard let groupID = model.group?.id else { throw Failure.assertion("group creation") }
            manifest.groupID = groupID; try record()
            try check(model.group?.ownerID == owner.uid, "native signup and group creation")
            try check(await model.save(body: "Synthetic QA prayer.", route: .prayer), "create prayer")
            guard let prayerID = model.myPrayers.first?.id else { throw Failure.assertion("prayer load") }
            try check(await model.save(body: "Synthetic QA prayer, edited.", route: .edit(prayerID)), "edit prayer")
            try check(await model.save(body: "Synthetic update one.", route: .update(prayerID)), "append first update")
            try check(await model.save(body: "Synthetic update two.", route: .update(prayerID)), "append second update")
            try check(model.prayer(id: prayerID)?.updates.map(\.body) == ["Synthetic update one.", "Synthetic update two."], "updates preserve history")
            let invitation = try await repository.createInvitation(groupID: groupID)
            manifest.invitationID = invitation; try record()
            let link = InvitationLink.url(code: invitation)
            try check(InvitationLink.code(from: link) == invitation, "share link round trip")
            try auth.signOut()
            let member = try await auth.createUser(withEmail: memberEmail, password: password).user
            createdEmails.append(memberEmail); manifest.userIDs.append(member.uid); try record()
            await model.signedIn(id: member.uid, name: "QA Member")
            model.receiveInvitation(link)
            try check(model.shouldPresentInvitation, "invitation remains after authentication")
            let preview = try await repository.previewInvitation(code: invitation)
            try check(preview.groupID == groupID, "recipient previews correct circle")
            await model.enterGroup(name: "", code: invitation)
            try check(model.group?.id == groupID && model.pendingInviteCode == nil && model.errorMessage == nil, "recipient joins and clears pending invitation")
            try check(model.group?.members.count == 2, "both accounts visible")
            guard let shared = model.prayer(id: prayerID) else { throw Failure.assertion("member prayer read") }
            try check(shared.body == "Synthetic QA prayer, edited." && shared.updates.count == 2, "member reads edited prayer and updates")
            await model.togglePrayer(shared)
            try check(model.prayer(id: prayerID)?.prayedBy.contains(member.uid) == true && model.errorMessage == nil, "I prayed persists")
            guard let reacted = model.prayer(id: prayerID) else { throw Failure.assertion("reaction load") }
            await model.togglePrayer(reacted)
            try check(model.prayer(id: prayerID)?.prayedBy.contains(member.uid) == false, "acknowledgment undo persists")
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
            let image = renderer.image { context in UIColor.systemBlue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 32, height: 32)) }
            guard let photo = image.jpegData(compressionQuality: 0.7) else { throw Failure.assertion("photo fixture") }
            try check(await model.saveProfilePhoto(photo), "profile photo saves")
            try check(model.group?.members.first { $0.id == member.uid }?.photoData == photo, "profile photo reloads")
            try check(await model.saveProfilePhoto(nil), "profile photo removes")
            try check(model.group?.members.first { $0.id == member.uid }?.photoData == nil, "initials fallback after removal")
            try await auth.currentUser!.delete()
            UserDefaults.standard.removeObject(forKey: "nanoom.activeGroup.\(member.uid)")
            _ = try await auth.signIn(withEmail: ownerEmail, password: password)
            await model.signedIn(id: owner.uid, name: "QA Owner")
            try check(model.group?.id == groupID && model.prayer(id: prayerID)?.updates.count == 2, "owner sign-in restores shared circle")
            model.path = ["__mine", prayerID]
            NSLog("NANOOM_FLOW READY: native SDK flow passed; synthetic owner detail ready for UI review")
        } catch {
            NSLog("NANOOM_FLOW FAIL: %@", String(describing: error))
            model.clearInvitation()
            for email in createdEmails.reversed() {
                do {
                    _ = try await auth.signIn(withEmail: email, password: password)
                    try await auth.currentUser?.delete()
                } catch { NSLog("NANOOM_FLOW cleanup: account already removed or cleanup requires review") }
            }
            model.user = nil; model.group = nil
        }
        return true
    }
}

/// Opt-in native integration check. Never signs out or deletes a normal user account.
@MainActor
private enum NativeAuthVerification {
    static func runIfRequested() async -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        let create = arguments.contains("--verify-native-auth-create")
        let restore = arguments.contains("--verify-native-auth-restore-and-clean")
        guard create || restore else { return false }
        do {
            guard FirebaseApp.app() != nil else { throw WithError.missingConfiguration }
            let auth = Auth.auth()
            if create {
                guard auth.currentUser == nil else {
                    NSLog("NANOOM_AUTH_CHECK BLOCKED: an account is already signed in")
                    return true
                }
                let email = "nanoom-native-check-\(UUID().uuidString.lowercased())@example.com"
                let password = UUID().uuidString + "Aa1!"
                let created = try await auth.createUser(withEmail: email, password: password)
                let uid = created.user.uid
                try auth.signOut()
                let signedIn = try await auth.signIn(withEmail: email, password: password)
                guard signedIn.user.uid == uid else { throw WithError.missingConfiguration }
                NSLog("NANOOM_AUTH_CHECK PASS: native signup, sign-out and sign-in; ready for relaunch")
            } else {
                guard let restored = auth.currentUser,
                      restored.email?.hasPrefix("nanoom-native-check-") == true,
                      restored.email?.hasSuffix("@example.com") == true else {
                    NSLog("NANOOM_AUTH_CHECK FAIL: synthetic session was not restored; no account modified")
                    return true
                }
                try await restored.delete()
                NSLog("NANOOM_AUTH_CHECK PASS: session restored after relaunch; synthetic account deleted")
            }
        } catch {
            let issue = error as NSError
            NSLog("NANOOM_AUTH_CHECK FAIL: \(issue.domain) \(issue.code)")
        }
        return true
    }
}
#endif

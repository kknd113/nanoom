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
            RootView().environment(model)
                .tint(.withAccent)
                .sensoryFeedback(.success, trigger: model.hapticTrigger)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        @Bindable var model = model
        Group {
            if model.user != nil && model.pendingInviteCode != nil && !model.isDemo {
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

import SwiftUI
#if FIREBASE_ENABLED
import FirebaseCore
#endif

@main
struct WithApp: App {
    @State private var model: AppModel

    init() {
        #if FIREBASE_ENABLED
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
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
            if model.user != nil && model.group != nil {
                NavigationStack(path: $model.path) {
                    CircleHomeView()
                        .navigationDestination(for: String.self) { id in
                            if id == "__mine" { MyPrayersView() }
                            else { PrayerDetailView(prayerID: id) }
                        }
                }
            } else if model.user != nil {
                ContentUnavailableView {
                    Label("Your circle is next", systemImage: "person.2.circle")
                } description: {
                    Text("Your account is ready. Ask your group leader for an invitation. Live invite redemption is the next integration step.")
                } actions: {
                    Button("Try again") { Task { await model.refresh() } }
                    Button("Back", role: .cancel) { model.user = nil }
                }
            } else {
                WelcomeView()
            }
        }
        .background(Color.withPaper.ignoresSafeArea())
        .sheet(item: $model.composer) { route in PrayerComposerView(route: route).environment(model) }
        .alert("Something needs attention", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .overlay { if model.isLoading { ProgressView().padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18)) } }
    }
}

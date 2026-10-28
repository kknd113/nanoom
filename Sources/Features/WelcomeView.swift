import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    #if FIREBASE_ENABLED
    @State private var appleSignIn = AppleSignInCoordinator()
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            WithWordmark()
            Spacer()
            Image(systemName: "heart.circle").font(.system(size: 68, weight: .ultraLight))
                .foregroundStyle(Color.withAccent).accessibilityHidden(true)
            Text("A little closer.\nEven between\nSundays.")
                .font(.system(.largeTitle, design: .rounded).weight(.medium)).tracking(-1)
            Text("A quiet place to share what’s on your heart and pray for one another.")
                .foregroundStyle(.secondary)
            Spacer()
            if model.isDemo {
                Label("Local demo · Sample group", systemImage: "iphone")
                    .font(.caption).foregroundStyle(.secondary)
                Button { Task { await model.startDemo() } } label: {
                    Label("Explore Grace Group", systemImage: "arrow.right")
                }.buttonStyle(PrimaryButtonStyle())
                Text("Changes stay on this device. No account or network needed.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                #if FIREBASE_ENABLED
                SignInWithAppleButton(.continue) { request in
                    appleSignIn.prepare(request)
                } onCompletion: { result in
                    Task {
                        do {
                            let user = try await appleSignIn.complete(result)
                            await model.signedIn(id: user.id, name: user.displayName)
                        } catch { model.errorMessage = error.localizedDescription }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54).clipShape(RoundedRectangle(cornerRadius: 18))
                Text("Only your chosen display name is shared with your group.")
                    .font(.caption).foregroundStyle(.secondary)
                #endif
            }
        }
        .padding(30).padding(.vertical, 20)
        .background(Color.withPaper.ignoresSafeArea())
    }
}

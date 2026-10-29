import SwiftUI
import AuthenticationServices
#if FIREBASE_ENABLED
import FirebaseAuth
import FirebaseCore
#endif

struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    #if FIREBASE_ENABLED
    @State private var showAccount = false
    #endif

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    WithWordmark()
                    Spacer(minLength: 36)
                    NanoomSymbol()
                    Text("A little closer.\nEven between\nSundays.")
                        .font(.system(.largeTitle, design: .rounded).weight(.medium)).tracking(-1)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("A quiet place to share what’s on your heart and pray for one another.")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 36)
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
                        if model.pendingInviteCode != nil {
                            Label("Your invitation is ready. Sign in to join.", systemImage: "person.2")
                                .font(.subheadline).foregroundStyle(Color.withAccent)
                            Button("Dismiss invitation") { model.clearInvitation() }.font(.caption)
                        }
                        Button { showAccount = true } label: {
                            Label("Continue with email", systemImage: "envelope")
                        }.buttonStyle(PrimaryButtonStyle())
                        .sheet(isPresented: $showAccount) {
                            NavigationStack { EmailAccountView() }.environment(model)
                        }
                        Text("A private account. A little space for your people.")
                            .font(.caption).foregroundStyle(.secondary)
                        #endif
                    }
                }
                .frame(minHeight: max(0, geometry.size.height - 100), alignment: .leading)
                .padding(30).padding(.vertical, 20)
            }
        }
        .background(Color.withPaper.ignoresSafeArea())
    }
}

#if FIREBASE_ENABLED
struct EmailAccountView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var creating = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                Picker("Account", selection: $creating) {
                    Text("Create account").tag(true)
                    Text("Sign in").tag(false)
                }.pickerStyle(.segmented)
                if creating { TextField("Your name", text: $name).textContentType(.nickname) }
                TextField("Email", text: $email).textContentType(.emailAddress)
                    .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                SecureField("Password", text: $password).textContentType(creating ? .newPassword : .password)
            } footer: {
                Text("Your group sees your name. Your email stays private. Use at least 8 characters for your password.")
            }
            if let message { Section { Text(message).foregroundStyle(.secondary) } }
            Section {
                Button(creating ? "Create my account" : "Sign in") { Task { await submit() } }
                    .disabled(busy || email.isEmpty || password.count < 8 || (creating && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                if !creating {
                    Button("Forgot password?") { Task { await resetPassword() } }.disabled(busy || email.isEmpty)
                }
            }
        }
        .navigationTitle(creating ? "A place for you" : "Welcome back")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(busy) } }
        .overlay { if busy { ProgressView() } }
    }

    private func submit() async {
        guard FirebaseApp.app() != nil else { message = WithError.missingConfiguration.localizedDescription; return }
        busy = true; message = nil
        defer { busy = false }
        do {
            let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result: AuthDataResult
            if creating {
                result = try await Auth.auth().createUser(withEmail: address, password: password)
                let change = result.user.createProfileChangeRequest()
                change.displayName = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
                try await change.commitChanges()
            } else {
                result = try await Auth.auth().signIn(withEmail: address, password: password)
            }
            await model.signedIn(id: result.user.uid, name: result.user.displayName ?? "Friend")
            dismiss()
        } catch {
            if (error as NSError).code == AuthErrorCode.emailAlreadyInUse.rawValue {
                message = "An account already exists with this email. Choose Sign in to continue."
            } else { message = error.localizedDescription }
        }
    }

    private func resetPassword() async {
        guard FirebaseApp.app() != nil else { return }
        busy = true
        defer { busy = false }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines))
            message = "If an account exists, a reset email will arrive shortly."
        } catch { message = error.localizedDescription }
    }
}

struct GroupEntryView: View {
    @Environment(AppModel.self) private var model
    @State private var joining = false
    @State private var name = ""
    @State private var code = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Life is better held together.").font(.title2)
                    Picker("Your circle", selection: $joining) {
                        Text("Create a group").tag(false)
                        Text("Join a group").tag(true)
                    }.pickerStyle(.segmented)
                    if joining {
                        TextField("Invitation link or code", text: $code).textInputAutocapitalization(.never).autocorrectionDisabled()
                    } else { TextField("Group name", text: $name) }
                } footer: { Text("Only people with your invitation can join your private circle.") }
                Section {
                    Button(joining ? "Join your group" : "Create your circle") {
                        Task { await model.enterGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines), code: joining ? code.trimmingCharacters(in: .whitespacesAndNewlines) : "") }
                    }.disabled(model.isLoading || (joining ? code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                }
            }
            .navigationTitle("Your people")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Sign out") { model.signOut() } } }
        }
    }
}
#endif

/// Shared presentation lets invitation states be reviewed without live accounts or tokens.
struct CircleInvitationView: View {
    let invitation: GroupInvitation?
    let loading: Bool
    let joining: Bool
    let issue: String?
    let join: () -> Void
    let retry: () -> Void
    let cancel: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    NanoomSymbol(size: 64)
                    if let invitation {
                        VStack(spacing: 12) {
                            Text("A place for you.").font(.system(.title2, design: .rounded).weight(.medium))
                            Text(invitation.groupName).font(.system(.largeTitle, design: .rounded).weight(.semibold))
                                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        }
                        Text("Share life. Hold one another in prayer.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Label("Only your circle sees your prayers.", systemImage: "lock.fill")
                            .font(.footnote).foregroundStyle(Color.withAccent)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(action: join) {
                            HStack(spacing: 10) {
                                if joining { ProgressView().tint(.withPaper) }
                                Text(joining ? "Joining…" : "Join this circle")
                            }
                        }.buttonStyle(PrimaryButtonStyle()).disabled(joining)
                        Text("Invitation expires \(invitation.expiresAt.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if loading {
                        ProgressView("Opening your invitation…")
                    } else {
                        Text("This invitation couldn’t be opened.")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        Text(issue ?? "Check your connection and try again. If it still won’t open, ask your group leader for a fresh link.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Try again", action: retry).buttonStyle(PrimaryButtonStyle())
                    }
                    Button("Not now", action: cancel).frame(minHeight: 44).disabled(joining)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: max(0, geometry.size.height - 60))
                .padding(30)
            }
        }
        .background(Color.withPaper.ignoresSafeArea())
        .navigationTitle("You’re invited")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if FIREBASE_ENABLED
struct InvitationJoinView: View {
    @Environment(AppModel.self) private var model
    let code: String
    @State private var invitation: GroupInvitation?
    @State private var issue: String?
    @State private var loading = true
    @State private var loadID = UUID()
    var body: some View {
        NavigationStack {
            CircleInvitationView(invitation: invitation, loading: loading, joining: model.isLoading, issue: issue,
                join: { Task { await model.enterGroup(name: "", code: code) } },
                retry: { Task { await load() } }, cancel: { model.clearInvitation() })
        }
        .task(id: code) { await load() }
        .onDisappear { loadID = UUID() }
    }
    private func load() async {
        let requestID = UUID()
        loadID = requestID
        let requestedCode = code
        loading = true; issue = nil; invitation = nil
        do {
            let preview = try await FirebasePrayerRepository().previewInvitation(code: requestedCode)
            guard !Task.isCancelled, loadID == requestID else { return }
            invitation = preview
            loading = false
        } catch {
            guard !Task.isCancelled, loadID == requestID else { return }
            issue = "Check your connection and try again. If it still won’t open, ask your group leader for a fresh link."
            loading = false
        }
    }
}
#endif

import SwiftUI

struct CircleHomeView: View {
    @Environment(AppModel.self) private var model
    @State private var settings = false

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    WithWordmark()
                    Spacer()
                    Button { settings = true } label: {
                        Text(model.group?.name ?? "Your group").font(.caption).foregroundStyle(.secondary)
                            .padding(.vertical, 14)
                    }.accessibilityLabel("Group settings")
                }
                Text("Your people.\nHeld in prayer.")
                    .font(.system(.largeTitle, design: .rounded).weight(.medium)).tracking(-1)
                    .padding(.top, 14)
                Text("A little space to be here for one another.").font(.subheadline).foregroundStyle(.secondary)
                PrayerCircleView().padding(.top, 12)
                if let member = model.selectedMember {
                    selectedPrayerCard(member)
                } else {
                    ContentUnavailableView("Your circle starts here", systemImage: "person.2", description: Text("Invite someone to begin sharing prayer."))
                }
            }
            .padding(.horizontal, 26).padding(.bottom, 20)
        }
        .background(Color.withPaper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                Button { model.composer = .prayer } label: { Label("Share a prayer", systemImage: "plus") }
                    .buttonStyle(PrimaryButtonStyle())
                HStack {
                    Text(model.isDemo ? "Local demo · Sample group" : "Just your small group").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button { model.path.append("__mine") } label: {
                        Label("My prayers", systemImage: "arrow.up.right").font(.caption)
                            .frame(minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, 26).padding(.top, 12)
            .background(.regularMaterial)
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await model.refresh() }
        .sheet(isPresented: $settings) {
            NavigationStack { GroupSettingsView() }.environment(model)
        }
    }

    @ViewBuilder
    private func selectedPrayerCard(_ member: GroupMember) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("On \(member.displayName)’s heart").font(.caption)
                Spacer()
                if model.selectedPrayers.first?.updates.isEmpty == false {
                    Label("An update", systemImage: "wind").font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let prayer = model.selectedPrayers.first {
                Text(prayer.body).font(.body).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                Button { model.path.append(prayer.id) } label: {
                    HStack { Text("Pray with \(member.displayName)"); Spacer(); Image(systemName: "arrow.right") }
                        .font(.subheadline).frame(minHeight: 44)
                }
                if model.selectedPrayers.count > 1 {
                    Menu("More prayers from \(member.displayName)") {
                        ForEach(model.selectedPrayers.dropFirst()) { prayer in
                            Button(String(prayer.body.prefix(70))) { model.path.append(prayer.id) }
                        }
                    }.font(.caption).frame(minHeight: 44)
                }
            } else {
                Text("There’s room for their story here, whenever they’re ready.").foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color.withPaper, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.withInk.opacity(0.09), lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: model.selectedMemberID)
    }
}

struct PrayerCircleView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize || model.others.count > 8 {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 20) {
                ForEach(model.others) { member in memberButton(member) }
            }.padding(.vertical, 25)
        } else {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: 141)
                let radiusX = min(geometry.size.width / 2 - 38, 108)
                ZStack {
                    Ellipse().stroke(Color.withInk.opacity(0.08), lineWidth: 1)
                        .frame(width: radiusX * 2, height: 196).position(center)
                    Ellipse().fill(RadialGradient(colors: [.withSoft, .withPaper.opacity(0)], center: .center,
                                                 startRadius: 2, endRadius: 130))
                        .frame(width: 260, height: 230).position(center)
                    VStack(spacing: 4) {
                        Text(model.group?.name ?? "Your circle").font(.system(.title3, design: .rounded).weight(.medium))
                        Text("Life, held together.").font(.caption2).foregroundStyle(.secondary)
                    }.frame(maxWidth: 132).position(center)
                    ForEach(Array(model.others.enumerated()), id: \.element.id) { index, member in
                        let angle = -Double.pi / 2 + Double(index) * 2 * .pi / Double(max(model.others.count, 1))
                        memberButton(member)
                            .position(x: center.x + CGFloat(cos(angle)) * radiusX,
                                      y: center.y + CGFloat(sin(angle)) * 103)
                    }
                }
            }.frame(height: 287)
        }
    }

    private func memberButton(_ member: GroupMember) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                model.selectedMemberID = member.id
            }
        } label: {
            VStack(spacing: 8) {
                MemberAvatar(member: member, selected: model.selectedMemberID == member.id)
                    .scaleEffect(model.selectedMemberID == member.id ? 1.06 : 1)
                Text(member.displayName).font(.caption).lineLimit(1)
            }.frame(width: 74).frame(minHeight: 78)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Read \(member.displayName)’s prayers")
        .accessibilityAddTraits(model.selectedMemberID == member.id ? .isSelected : [])
    }
}

struct GroupSettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            Section("Your circle") {
                ForEach(model.group?.members ?? []) { member in
                    HStack { MemberAvatar(member: member, size: 36); Text(member.displayName) }
                }
            }
            if model.isDemo {
                Section { Text("This is a local demo. Invitations, account management, and live notifications are not connected.").font(.footnote) }
            } else {
                #if FIREBASE_ENABLED
                Section("Invite your people") {
                    Button("Create invitation") { Task { await model.makeInvitation() } }
                    if let code = model.inviteCode {
                        Text(code).font(.caption.monospaced()).textSelection(.enabled)
                        ShareLink("Share invitation code", item: "Join my Nanoom prayer circle. Open Nanoom, choose Join a group, and enter this code: \(code)\nValid for 7 days.")
                        Button("Revoke invitation", role: .destructive) {
                            Task {
                                do { try await FirebasePrayerRepository().revokeInvitation(code: code); model.inviteCode = nil }
                                catch { model.errorMessage = error.localizedDescription }
                            }
                        }
                    }
                    Text("Only the group creator can issue invitations. Codes expire after 7 days.").font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("Sign out", role: .destructive) { dismiss(); model.signOut() }
                }
                #endif
            }
        }
        .navigationTitle(model.group?.name ?? "Your circle")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}

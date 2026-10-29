import SwiftUI

struct PrayerDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    let prayerID: String
    @State private var deleteConfirmation = false
    @State private var reacting = false

    var body: some View {
        if let prayer = model.prayer(id: prayerID), let author = model.author(of: prayer) {
            let mine = prayer.authorID == model.user?.id
            let prayed = prayer.prayedBy.contains(model.user?.id ?? "")
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 14) {
                        MemberAvatar(member: author, size: 54)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(mine ? "Your prayer" : author.displayName)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                            Text(prayer.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.tertiary).accessibilityLabel("Shared only with your group")
                    }
                    Text(prayer.body).font(.title3).lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                    if !prayer.updates.isEmpty {
                        VStack(alignment: .leading, spacing: 18) {
                            Label("A little further along", systemImage: "leaf")
                                .font(.system(.headline, design: .rounded)).foregroundStyle(Color.withInk)
                            ForEach(prayer.updates.sorted { $0.createdAt < $1.createdAt }) { update in
                                HStack(alignment: .top, spacing: 13) {
                                    Circle().fill(Color.withAccent.opacity(0.55)).frame(width: 7, height: 7).padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(update.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                                        Text(update.body).lineSpacing(5).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                                    }
                                }
                            }
                        }.padding(22).frame(maxWidth: .infinity, alignment: .leading).prayerCardSurface()
                    }
                    let names = prayer.prayedBy.compactMap { id in model.group?.members.first { $0.id == id }?.displayName }
                    if !names.isEmpty {
                        Label("\(names.sorted().joined(separator: ", ")) prayed with \(mine ? "you" : author.displayName).", systemImage: "heart.fill")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 28)
            }
            .background(Color.withPaper.ignoresSafeArea())
            .navigationTitle(mine ? "On your heart" : "With \(author.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                if mine {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Add an update", systemImage: "plus.bubble") { model.composer = .update(prayer.id) }
                            Button("Edit prayer", systemImage: "pencil") { model.composer = .edit(prayer.id) }
                            Button("Delete prayer", systemImage: "trash", role: .destructive) { deleteConfirmation = true }
                        } label: { Image(systemName: "ellipsis") }
                        .accessibilityLabel("Prayer actions")
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 9) {
                    if mine {
                        Button { model.composer = .update(prayer.id) } label: {
                            Label(typeSize.isAccessibilitySize ? "Add update" : "Share an update", systemImage: "plus.bubble")
                        }.buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button {
                            reacting = true
                            Task { await model.togglePrayer(prayer); reacting = false }
                        } label: {
                            if reacting { ProgressView().tint(.withPaper) }
                            else {
                                Label(typeSize.isAccessibilitySize ? (prayed ? "Prayed" : "I prayed") :
                                        (prayed ? "Prayed with \(author.displayName)" : "I prayed for \(author.displayName)"),
                                      systemImage: prayed ? "checkmark" : "heart")
                            }
                        }.buttonStyle(PrimaryButtonStyle()).disabled(reacting)
                        .accessibilityLabel(reacting ? "Saving your acknowledgment" : prayed ? "Prayed with \(author.displayName)" : "I prayed for \(author.displayName)")
                        .accessibilityHint(prayed ? "Double-tap to undo your acknowledgment." : "Marks this prayer as prayed by you.")
                    }
                    Text(typeSize.isAccessibilitySize ? (mine ? "Share how things are." : prayed ? "Tap to undo." : "Take your time.") :
                            (mine ? "There’s room for the next part, too." : prayed ? "Tap again to undo your acknowledgment." : "Take your time. Be here with them."))
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding(12).floatingActionSurface()
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 8)
            }
            .confirmationDialog("Remove this prayer and its updates from your circle?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                Button("Delete prayer", role: .destructive) { Task { await model.delete(prayer) } }
            }
        } else {
            ContentUnavailableView("This prayer is no longer here", systemImage: "book.closed")
                .toolbar(.visible, for: .navigationBar)
        }
    }
}

struct MyPrayersView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        Group {
            if model.myPrayers.isEmpty {
                ContentUnavailableView {
                    Label("Room for your story", systemImage: "heart.text.clipboard")
                } description: {
                    Text("A small worry. A big hope. You can share it here.")
                } actions: {
                    Button("Share your first prayer") { model.composer = .prayer }
                        .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                }
            } else {
                List(model.myPrayers) { prayer in
                    NavigationLink { PrayerDetailView(prayerID: prayer.id) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(prayer.body).font(.body).lineSpacing(3).lineLimit(3)
                            HStack(spacing: 12) {
                                Text(prayer.createdAt, style: .date)
                                if !prayer.updates.isEmpty { Label("Updated", systemImage: "leaf") }
                            }.font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 10)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                }.listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
        .background(Color.withPaper.ignoresSafeArea())
        .navigationTitle("My prayers")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button { model.composer = .prayer } label: { Image(systemName: "square.and.pencil") }
                .accessibilityLabel("Share a prayer")
        } }
    }
}

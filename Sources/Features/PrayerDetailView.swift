import SwiftUI

struct PrayerDetailView: View {
    @Environment(AppModel.self) private var model
    let prayerID: String
    @State private var deleteConfirmation = false
    @State private var reacting = false

    var body: some View {
        if let prayer = model.prayer(id: prayerID), let author = model.author(of: prayer) {
            let mine = prayer.authorID == model.user?.id
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 16) {
                        MemberAvatar(member: author, size: 76).padding(.top, 34)
                        Text(mine ? "What you’re carrying" : "A moment for \(author.displayName).")
                            .font(.system(.title2, design: .rounded).weight(.medium))
                        Text(prayer.createdAt, style: .relative).font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity)
                    Text(prayer.body).font(.system(.title2, design: .default)).lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 12)
                    if !prayer.updates.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("THE STORY CONTINUES").font(.caption2).tracking(1.5).foregroundStyle(.secondary)
                            ForEach(prayer.updates.sorted { $0.createdAt < $1.createdAt }) { update in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(update.createdAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                                    Text(update.body).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .overlay(alignment: .leading) { Rectangle().fill(Color.withAccent.opacity(0.3)).frame(width: 2) }
                    }
                    let names = prayer.prayedBy.compactMap { id in model.group?.members.first { $0.id == id }?.displayName }
                    if !names.isEmpty {
                        Text("\(names.sorted().joined(separator: ", ")) prayed with you.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 32)
            }
            .background(Color.withPaper.ignoresSafeArea())
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if mine {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Edit prayer", systemImage: "pencil") { model.composer = .edit(prayer.id) }
                            Button("Delete prayer", systemImage: "trash", role: .destructive) { deleteConfirmation = true }
                        } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if mine {
                        Button { model.composer = .update(prayer.id) } label: {
                            Label("Share a little update", systemImage: "plus")
                        }.buttonStyle(PrimaryButtonStyle())
                    } else {
                        let prayed = prayer.prayedBy.contains(model.user?.id ?? "")
                        Button {
                            reacting = true
                            Task { await model.togglePrayer(prayer); reacting = false }
                        } label: {
                            Label(prayed ? "You prayed for \(author.displayName)" : "I prayed for \(author.displayName)",
                                  systemImage: prayed ? "checkmark" : "heart")
                        }.buttonStyle(PrimaryButtonStyle()).disabled(reacting)
                    }
                    Text("Take a moment. You’re here together.").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 26).padding(.top, 14).padding(.bottom, 8).background(.regularMaterial)
            }
            .confirmationDialog("Remove this prayer and its updates from your circle?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
                Button("Delete prayer", role: .destructive) { Task { await model.delete(prayer) } }
            }
        } else {
            ContentUnavailableView("This prayer is no longer here", systemImage: "book.closed")
        }
    }
}

struct MyPrayersView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Group {
            if model.myPrayers.isEmpty {
                ContentUnavailableView {
                    Label("There’s room for your story", systemImage: "heart.text.clipboard")
                } description: {
                    Text("A small worry. A big hope. You can share it here.")
                } actions: {
                    Button("Share your first prayer") { dismiss(); model.composer = .prayer }
                }
            } else {
                List(model.myPrayers) { prayer in
                    NavigationLink { PrayerDetailView(prayerID: prayer.id) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(prayer.body).lineLimit(3)
                            Text(prayer.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("My prayers")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}

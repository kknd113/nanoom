import SwiftUI

struct PrayerComposerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    let route: ComposerRoute
    @State private var text = ""
    @State private var saving = false

    private var draftKey: String { "with.draft.\(model.user?.id ?? "anonymous").\(route.id)" }
    private var isUpdate: Bool { if case .update = route { return true }; return false }
    private var isEdit: Bool { if case .edit = route { return true }; return false }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(isUpdate ? "How have\nthings been?" : isEdit ? "A little\nchange of words." : "What’s on\nyour heart?")
                    .font(.system(.largeTitle, design: .rounded).weight(.medium)).tracking(-1)
                Text(isUpdate ? "Still waiting is part of the story, too." : "Big or small, you can share it here.")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .font(.title3).lineSpacing(6).focused($focused)
                    .scrollContentBackground(.hidden).frame(minHeight: 180)
                    .accessibilityLabel(isUpdate ? "Your update" : "Your prayer")
                HStack {
                    Label("Only your small group", systemImage: "lock").font(.caption)
                    Spacer()
                    Text("\(text.count)/2000").font(.caption2)
                        .foregroundStyle(text.count > 2_000 ? Color.red : Color.secondary)
                }.foregroundStyle(.secondary)
            }
            .padding(26).background(Color.withPaper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Sharing…" : isEdit ? "Save" : "Share") {
                        saving = true
                        Task {
                            if await model.save(body: trimmed, route: route) {
                                UserDefaults.standard.removeObject(forKey: draftKey)
                                dismiss()
                            }
                            saving = false
                        }
                    }.disabled(trimmed.isEmpty || text.count > 2_000 || saving)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(saving)
        .onAppear {
            if model.isDemo, let draft = UserDefaults.standard.string(forKey: draftKey) { text = draft }
            else if case .edit(let id) = route { text = model.prayer(id: id)?.body ?? "" }
            focused = true
        }
        .onChange(of: text) { _, value in
            if model.isDemo { UserDefaults.standard.set(value, forKey: draftKey) }
        }
    }
}

import SwiftUI

struct PrayerComposerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var editorHeight: CGFloat = 180
    let route: ComposerRoute
    @State private var text = ""
    @State private var initialText = ""
    @State private var saving = false
    @State private var discardConfirmation = false

    private var draftKey: String { "with.draft.\(model.user?.id ?? "anonymous").\(route.id)" }
    private var isUpdate: Bool { if case .update = route { return true }; return false }
    private var isEdit: Bool { if case .edit = route { return true }; return false }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasChanges: Bool { text != initialText }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 7) {
                                Image(systemName: "lock.fill").font(.caption2)
                                Text(model.group?.name ?? "Your small group").font(.caption.weight(.medium))
                            }.foregroundStyle(Color.withAccent).padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.withSoft, in: Capsule())
                            VStack(alignment: .leading, spacing: 7) {
                                Text(isUpdate ? "How have things been?" : isEdit ? "Make it feel like you." : "What’s on your heart?")
                                    .font(.system(.title2, design: .rounded).weight(.semibold)).tracking(-0.4)
                                Text(isUpdate ? "Still waiting is part of the story, too." : "Small prayers belong here, too.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            ZStack(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text(isUpdate ? "A change, a little hope, or how things are…" : "A worry, a hope, a thank-you…")
                                        .font(.title3).foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 5)
                                        .allowsHitTesting(false).accessibilityHidden(true)
                                }
                                TextEditor(text: $text).font(.title3).lineSpacing(6).focused($focused)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: max(editorHeight, geometry.size.height - 245))
                                    .accessibilityLabel(isUpdate ? "Your update" : "Your prayer")
                            }.id("composerEditor")
                            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())
                            layout {
                                Text("Only your circle can see this.").font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !typeSize.isAccessibilitySize { Spacer() }
                                Text("\(text.count)/2000").font(.caption.monospacedDigit())
                                    .foregroundStyle(text.count > 2_000 ? Color.red : Color.secondary)
                            }.foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: focused) { _, editing in
                        if editing { scroll.scrollTo("composerEditor", anchor: .top) }
                    }
                    .onChange(of: geometry.size.height) { _, _ in
                        if focused { scroll.scrollTo("composerEditor", anchor: .top) }
                    }
                }
            }
            .background(Color.withPaper.ignoresSafeArea())
            .navigationTitle(isUpdate ? "Add update" : isEdit ? "Edit prayer" : "New prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { discardConfirmation = true }
                        else { dismiss() }
                    }.disabled(saving)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button { focused = false } label: { Image(systemName: "keyboard.chevron.compact.down") }
                        .accessibilityLabel("Hide keyboard")
                }
            }
            .confirmationDialog("Discard your changes?", isPresented: $discardConfirmation, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) {
                    if model.isDemo { UserDefaults.standard.removeObject(forKey: draftKey) }
                    dismiss()
                }
                Button("Keep writing", role: .cancel) {}
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(saving || hasChanges)
        .onAppear {
            if case .edit(let id) = route { initialText = model.prayer(id: id)?.body ?? "" }
            if model.isDemo, let draft = UserDefaults.standard.string(forKey: draftKey) { text = draft }
            else { text = initialText }
            focused = true
        }
        .onChange(of: text) { _, value in
            if model.isDemo { UserDefaults.standard.set(value, forKey: draftKey) }
        }
    }
}

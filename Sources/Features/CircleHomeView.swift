import SwiftUI
import PhotosUI
import ImageIO

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
            Section("You") {
                NavigationLink { ProfilePhotoSettingsView() } label: {
                    HStack {
                        if let me = model.group?.members.first(where: { $0.id == model.user?.id }) { MemberAvatar(member: me, size: 44) }
                        VStack(alignment: .leading) {
                            Text(model.user?.displayName ?? "Your profile")
                            Text("Profile photo").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Your circle") {
                ForEach(model.group?.members ?? []) { member in
                    HStack { MemberAvatar(member: member, size: 36); Text(member.displayName) }
                }
            }
            if model.isDemo {
                Section { Text("This is a local demo. Invitations, account management, and live notifications are not connected.").font(.footnote) }
            } else {
                #if FIREBASE_ENABLED
                if model.group?.ownerID == model.user?.id {
                Section("Invite your people") {
                    Button(model.makingInvitation ? "Creating link…" : "Create invite link") { Task { await model.makeInvitation() } }.disabled(model.makingInvitation)
                    if let code = model.inviteCode {

                        ShareLink("Share invite link", item: InvitationLink.url(code: code), subject: Text("Join my Nanoom circle"), message: Text("A little space to share life and pray together."))
                        Button("Revoke invitation", role: .destructive) {
                            Task {
                                do { try await FirebasePrayerRepository().revokeInvitation(code: code); model.inviteCode = nil }
                                catch { model.errorMessage = error.localizedDescription }
                            }
                        }
                    }
                    Text("Only the group creator can issue invitations. Codes expire after 7 days.").font(.footnote).foregroundStyle(.secondary)
                }
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

struct ProfilePhotoSettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: PhotosPickerItem?
    @State private var cropImage: UIImage?
    @State private var loading = false
    @State private var removing = false
    @State private var issue: String?
    private var me: GroupMember? { model.group?.members.first { $0.id == model.user?.id } }

    var body: some View {
        Form {
            Section {
                HStack { Spacer(); if let me { MemberAvatar(member: me, size: 104) }; Spacer() }.padding(.vertical, 24)
                PhotosPicker(selection: $selection, matching: .images) {
                    Label(me?.photoData == nil ? "Choose a photo" : "Change photo", systemImage: "photo")
                }.disabled(loading)
                if me?.photoData != nil {
                    Button("Remove photo", role: .destructive) { removing = true }.disabled(loading)
                }
            } footer: { Text("Optional. Your photo is visible only to this circle. You can change or remove it anytime.") }
            if loading { Section { ProgressView("Preparing your photo…") } }
            if let issue { Section { Text(issue).foregroundStyle(.secondary) } }
        }
        .navigationTitle("Your photo")
        .onChange(of: selection) { _, item in
            guard let item else { return }
            Task {
                loading = true; issue = nil
                defer { loading = false; selection = nil }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let source = CGImageSourceCreateWithData(data as CFData, nil),
                          let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceThumbnailMaxPixelSize: 1024
                          ] as CFDictionary) else { issue = "This photo couldn’t be opened. Try another image."; return }
                    cropImage = UIImage(cgImage: thumbnail)
                } catch { issue = "This photo couldn’t be opened. Try another image." }
            }
        }
        .sheet(isPresented: Binding(get: { cropImage != nil }, set: { if !$0 { cropImage = nil } })) {
            if let cropImage {
                NavigationStack {
                    AvatarCropView(image: cropImage) { data in await model.saveProfilePhoto(data) }
                }
            }
        }
        .confirmationDialog("Remove your profile photo?", isPresented: $removing, titleVisibility: .visible) {
            Button("Remove photo", role: .destructive) {
                Task { loading = true; _ = await model.saveProfilePhoto(nil); loading = false }
            }
        }
    }
}

struct AvatarCropView: View {
    let image: UIImage
    let save: (Data) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1
    @State private var offset = CGSize.zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag = CGSize.zero
    @State private var saving = false
    @State private var issue: String?

    private func bounded(_ offset: CGSize, zoom: CGFloat, side: CGFloat) -> CGSize {
        let base = side / min(image.size.width, image.size.height)
        let x = max(0, (image.size.width * base * zoom - side) / 2)
        let y = max(0, (image.size.height * base * zoom - side) / 2)
        return CGSize(width: min(x, max(-x, offset.width)), height: min(y, max(-y, offset.height)))
    }
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width - 48, 340)
            let scale = min(4, max(1, zoom * pinch))
            let position = bounded(CGSize(width: offset.width + drag.width, height: offset.height + drag.height), zoom: scale, side: side)
            let base = side / min(image.size.width, image.size.height)
            ScrollView {
            VStack(spacing: 24) {
                Spacer()
                ZStack {
                    Image(uiImage: image).resizable()
                        .frame(width: image.size.width * base * scale, height: image.size.height * base * scale)
                        .offset(position)
                }.frame(width: side, height: side).clipped().clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                .contentShape(Circle())
                .gesture(DragGesture().updating($drag) { value, state, _ in state = value.translation }
                    .onEnded { value in offset = bounded(CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height), zoom: zoom, side: side) })
                .simultaneousGesture(MagnificationGesture().updating($pinch) { value, state, _ in state = value }
                    .onEnded { value in zoom = min(4, max(1, zoom * value)); offset = bounded(offset, zoom: zoom, side: side) })
                .accessibilityLabel("Photo preview")
                .accessibilityAction(named: Text("Move photo left")) { movePhoto(x: -20, y: 0, side: side) }
                .accessibilityAction(named: Text("Move photo right")) { movePhoto(x: 20, y: 0, side: side) }
                .accessibilityAction(named: Text("Move photo up")) { movePhoto(x: 0, y: -20, side: side) }
                .accessibilityAction(named: Text("Move photo down")) { movePhoto(x: 0, y: 20, side: side) }
                Text("Drag to position. Pinch to zoom.").font(.subheadline).foregroundStyle(.secondary)
                Slider(value: $zoom, in: 1...4).accessibilityLabel("Photo zoom").padding(.horizontal, 36)
                    .onChange(of: zoom) { _, value in offset = bounded(offset, zoom: value, side: side) }
                Button("Reset position") { zoom = 1; offset = .zero }.disabled(saving)
                    .frame(minHeight: 44)
                if let issue { Text(issue).font(.caption).foregroundStyle(.secondary) }
                Button {
                    Task {
                        saving = true
                        defer { saving = false }
                        guard let data = render(side: side) else { issue = "Try a different photo."; return }
                        if await save(data) { dismiss() }
                        else { issue = "Your photo couldn’t be saved. Please try again." }
                    }
                } label: { if saving { ProgressView() } else { Text("Use photo") } }
                    .buttonStyle(PrimaryButtonStyle()).disabled(saving)
                Spacer()
            }.padding(24).frame(maxWidth: .infinity)
            }
        }
        .background(Color.withPaper.ignoresSafeArea())
        .navigationTitle("Make it yours")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) } }
        .interactiveDismissDisabled(saving)
    }
    private func movePhoto(x: CGFloat, y: CGFloat, side: CGFloat) {
        offset = bounded(CGSize(width: offset.width + x, height: offset.height + y), zoom: zoom, side: side)
    }
    private func render(side: CGFloat) -> Data? {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format)
        let position = bounded(offset, zoom: zoom, side: side)
        let factor = 256 / min(image.size.width, image.size.height) * zoom
        let width = image.size.width * factor, height = image.size.height * factor
        let avatar = renderer.image { _ in
            UIColor.white.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: 256, height: 256))
            image.draw(in: CGRect(x: (256-width)/2 + position.width * 256/side,
                                  y: (256-height)/2 + position.height * 256/side, width: width, height: height))
        }
        for quality in [0.8, 0.6, 0.4] {
            if let data = avatar.jpegData(compressionQuality: quality), data.count <= 65_536 { return data }
        }
        return nil
    }
}

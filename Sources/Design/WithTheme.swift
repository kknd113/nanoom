import SwiftUI
import UIKit

extension Color {
    static let withInk = Color("WithInk")
    static let withPaper = Color("WithPaper")
    static let withAccent = Color("WithAccent")
    static let withSoft = Color("WithSoft")
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.withInk, in: RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(Color.withPaper)
            .opacity(!enabled ? 0.45 : configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct MemberAvatar: View {
    let member: GroupMember
    var size: CGFloat = 50
    var selected = false
    var body: some View {
        Group {
            if let data = member.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else { Text(member.initial) }
        }
            .font(.system(size: size * 0.34, weight: .medium, design: .rounded))
            .foregroundStyle(Color.withAccent)
            .frame(width: size, height: size)
            .background(Color.withSoft, in: Circle())
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.withPaper, lineWidth: 5))
            .overlay(Circle().stroke(selected ? Color.withAccent : Color.withInk.opacity(0.12), lineWidth: selected ? 2 : 1))
            .accessibilityHidden(true)
    }
}

struct WithWordmark: View {
    var body: some View {
        Text("nanoom").font(.system(size: 27, weight: .medium, design: .rounded)).tracking(-1)
            .foregroundStyle(Color.withInk).accessibilityLabel("Nanoom")
    }
}

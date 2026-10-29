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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.withInk, in: Capsule())
            .foregroundStyle(Color.withPaper)
            .opacity(!enabled ? 0.45 : configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
    }
}

/// Glass belongs to floating controls; prayer content keeps a stable reading surface.
struct FloatingActionSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 30))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.withInk.opacity(0.12)))
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.withInk.opacity(0.08)))
        }
    }
}

extension View {
    func floatingActionSurface() -> some View { modifier(FloatingActionSurface()) }
    func prayerCardSurface() -> some View {
        background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.withInk.opacity(0.07)))
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
        HStack(spacing: 9) {
            Image("NanoomMark").resizable().scaledToFit()
                .foregroundStyle(Color.withAccent).frame(width: 25, height: 25)
            Image("NanoomWordmark").resizable().scaledToFit()
                .foregroundStyle(Color.withInk).frame(width: 132, height: 22)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nanoom")
    }
}

struct NanoomSymbol: View {
    var size: CGFloat = 88
    var body: some View {
        Image("NanoomMark").resizable().scaledToFit()
            .foregroundStyle(Color.withAccent)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

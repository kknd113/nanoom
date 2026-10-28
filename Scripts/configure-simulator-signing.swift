import Foundation

// Simulator-only local signing. Physical devices continue to use the selected Xcode team.
let url = URL(fileURLWithPath: "WithLive.xcodeproj/project.pbxproj")
var project = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: Any]
var objects = project["objects"] as! [String: [String: Any]]
for (id, var object) in objects where object["isa"] as? String == "XCBuildConfiguration" {
    guard var settings = object["buildSettings"] as? [String: Any],
          settings["PRODUCT_BUNDLE_IDENTIFIER"] as? String == "com.kknd113.nanoom" else { continue }
    settings["CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]"] = "YES"
    settings["CODE_SIGN_IDENTITY[sdk=iphonesimulator*]"] = "-"
    settings["CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]"] = "Configuration/WithSimulator.entitlements"
    settings["INFOPLIST_FILE"] = "Configuration/WithLive-Info.plist"
    if object["name"] as? String == "Debug" {
        settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) FIREBASE_ENABLED DEBUG"
    }
    object["buildSettings"] = settings
    objects[id] = object
}
project["objects"] = objects
try PropertyListSerialization.data(fromPropertyList: project, format: .xml, options: 0).write(to: url)
print("Configured simulator-only signing and app-scoped Keychain access.")

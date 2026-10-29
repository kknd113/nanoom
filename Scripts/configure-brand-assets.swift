import Foundation

// Configure native Xcode asset compilation without parsing or replacing project text.
for name in ["With", "WithLive"] {
    let url = URL(fileURLWithPath: "\(name).xcodeproj/project.pbxproj")
    var project = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as! [String: Any]
    var objects = project["objects"] as! [String: [String: Any]]
    for (id, var object) in objects where object["isa"] as? String == "XCBuildConfiguration" {
        guard var settings = object["buildSettings"] as? [String: Any],
              settings["PRODUCT_MODULE_NAME"] as? String == "With" else { continue }
        settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
        object["buildSettings"] = settings
        objects[id] = object
    }
    project["objects"] = objects
    try PropertyListSerialization.data(fromPropertyList: project, format: .xml, options: 0).write(to: url)
    print("Configured Nanoom AppIcon in \(name).xcodeproj")
}

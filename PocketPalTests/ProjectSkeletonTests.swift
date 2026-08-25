import Foundation
import XCTest
@testable import PocketPal

final class ProjectSkeletonTests: XCTestCase {
    func testProjectConfigurationUsesExpectedIdentifiers() throws {
        XCTAssertEqual(ProjectConfiguration.widgetKind, "PocketPalWidget")
        XCTAssertEqual(ProjectConfiguration.urlScheme, "pocketpal")
        XCTAssertEqual(ProjectConfiguration.appGroupIdentifier, "group.com.example.pocketpal")

        let appEntitlements = try propertyList(
            at: "PocketPal/Configuration/PocketPal.entitlements"
        )
        let widgetEntitlements = try propertyList(
            at: "PocketPal/Configuration/PocketPalWidget.entitlements"
        )
        let entitlementKey = "com.apple.security.application-groups"
        let expectedGroups = [ProjectConfiguration.appGroupIdentifier]

        XCTAssertEqual(appEntitlements[entitlementKey] as? [String], expectedGroups)
        XCTAssertEqual(widgetEntitlements[entitlementKey] as? [String], expectedGroups)

        let appInfo = try propertyList(at: "PocketPal/Configuration/Info.plist")
        let urlTypes = try XCTUnwrap(appInfo["CFBundleURLTypes"] as? [[String: Any]])
        let configuredSchemes = urlTypes.flatMap { urlType in
            urlType["CFBundleURLSchemes"] as? [String] ?? []
        }
        XCTAssertTrue(configuredSchemes.contains(ProjectConfiguration.urlScheme))

        let projectSpec = try textFile(at: "project.yml")
            .replacingOccurrences(of: "\r\n", with: "\n")
        XCTAssertTrue(
            projectSpec.contains(
                "      - path: PocketPal/Resources\n        buildPhase: resources"
            )
        )
        XCTAssertFalse(projectSpec.contains("\n    resources:\n"))
    }

    private func propertyList(at relativePath: String) throws -> [String: Any] {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: projectRoot.appendingPathComponent(relativePath))
        var format = PropertyListSerialization.PropertyListFormat.xml
        let object = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        )
        return try XCTUnwrap(object as? [String: Any])
    }

    private func textFile(at relativePath: String) throws -> String {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: projectRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

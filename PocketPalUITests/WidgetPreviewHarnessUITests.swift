import XCTest

@MainActor
final class WidgetPreviewHarnessUITests: XCTestCase {
    private let families = ["small", "medium", "large"]

    func testRequiredStateAndFamilyScreenshotMatrix() throws {
        continueAfterFailure = false
        let scenarios = ["unadopted", "happy", "hungry", "sleeping", "failure"]

        for scenario in scenarios {
            for family in families {
                let app = launch(family: family, scenario: scenario)
                try assertAndCapture(
                    app,
                    name: "widget-\(scenario)-\(family)",
                    expectedValue: "\(family),\(scenario)"
                )
                app.terminate()
            }
        }
    }

    func testPrivacyStateInDarkModeAcrossFamilies() throws {
        continueAfterFailure = false
        for family in families {
            let app = launch(
                family: family,
                scenario: "privacy",
                extraArguments: ["--pocketpal-ui-test-dark-mode"]
            )
            let protectedState = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "宠物状态已保护"))
                .firstMatch
            XCTAssertTrue(protectedState.waitForExistence(timeout: 10))
            try assertAndCapture(
                app,
                name: "widget-privacy-dark-\(family)",
                expectedValue: "\(family),privacy"
            )
            app.terminate()
        }
    }

    func testMaximumAccessibilityTextSizeAcrossFamilies() throws {
        continueAfterFailure = false
        for family in families {
            let app = launch(
                family: family,
                scenario: "happy",
                extraArguments: [
                    "-UIPreferredContentSizeCategoryName",
                    "UICTContentSizeCategoryAccessibilityXXXL"
                ]
            )
            try assertHappyCoreContent(in: app, family: family)
            try assertAndCapture(
                app,
                name: "widget-accessibility-\(family)",
                expectedValue: "\(family),happy"
            )
            app.terminate()
        }
    }

    func testMaximumAccessibilityEmptyAndErrorStatesAcrossFamilies() throws {
        continueAfterFailure = false
        for scenario in ["unadopted", "failure"] {
            for family in families {
                let app = launch(
                    family: family,
                    scenario: scenario,
                    extraArguments: [
                        "-UIPreferredContentSizeCategoryName",
                        "UICTContentSizeCategoryAccessibilityXXXL"
                    ]
                )
                let expectedLabel = scenario == "unadopted"
                    ? "先去领养"
                    : "暂时读不到宠物"
                let stateElement = app.descendants(matching: .any)
                    .matching(NSPredicate(format: "label CONTAINS %@", expectedLabel))
                    .firstMatch
                XCTAssertTrue(stateElement.waitForExistence(timeout: 10))
                let card = app.descendants(matching: .any)["widget-preview-card"]
                XCTAssertTrue(card.waitForExistence(timeout: 10))
                XCTAssertFalse(stateElement.frame.isEmpty)
                XCTAssertTrue(card.frame.contains(stateElement.frame))
                try assertAndCapture(
                    app,
                    name: "widget-accessibility-\(scenario)-\(family)",
                    expectedValue: "\(family),\(scenario)"
                )
                app.terminate()
            }
        }
    }

    private func launch(
        family: String,
        scenario: String,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["POCKETPAL_TEST_DATA_DIRECTORY"] =
            "WidgetPreview-\(family)-\(scenario)"
        app.launchEnvironment["POCKETPAL_TEST_RESET_DATA"] = "1"
        app.launchArguments += [
            "--pocketpal-widget-preview",
            "--pocketpal-widget-family=\(family)",
            "--pocketpal-widget-state=\(scenario)"
        ]
        app.launchArguments += extraArguments
        app.launch()
        return app
    }

    private func assertAndCapture(
        _ app: XCUIApplication,
        name: String,
        expectedValue: String
    ) throws {
        let screen = app.otherElements["widget-preview-screen"]
        XCTAssertTrue(screen.waitForExistence(timeout: 10))
        let card = app.descendants(matching: .any)["widget-preview-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertEqual(card.value as? String, expectedValue)
        XCTAssertTrue(app.staticTexts["widget-preview-title"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertHappyCoreContent(
        in app: XCUIApplication,
        family: String
    ) throws {
        let card = app.descendants(matching: .any)["widget-preview-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let petHeader = family == "large"
            ? "奶糖，正在闲逛，正在家里慢悠悠巡视"
            : "奶糖，正在闲逛"
        var labels = [
            petHeader,
            "心情，88",
            "饥饿，26",
            "亲密度，42",
            "金币，18"
        ]
        if family == "small" {
            labels.append("建议操作，抚摸，现在可用")
        } else {
            labels += ["喂食，现在可用", "抚摸，现在可用", "玩耍，现在可用"]
        }

        for label in labels {
            let element = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", label))
                .firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 10), "Missing \(label)")
            XCTAssertFalse(element.frame.isEmpty, "Empty frame for \(label)")
            XCTAssertTrue(card.frame.contains(element.frame), "\(label) is outside the widget card")
        }
    }
}

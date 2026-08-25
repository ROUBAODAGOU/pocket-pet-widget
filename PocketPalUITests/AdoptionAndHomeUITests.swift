import XCTest

@MainActor
final class AdoptionAndHomeUITests: XCTestCase {
    private var dataToken = ""

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        dataToken = "PocketPalUITests-\(UUID().uuidString)"
    }

    override func tearDown() {
        let cleanupApp = makeApp(resetData: true)
        cleanupApp.launch()
        _ = cleanupApp.staticTexts["adoption-title"].waitForExistence(timeout: 5)
        cleanupApp.terminate()
        super.tearDown()
    }

    func testAdoptionValidationInteractionsAndRelaunchPersistence() throws {
        let app = makeApp(resetData: true)
        app.launch()

        XCTAssertTrue(app.staticTexts["adoption-title"].waitForExistence(timeout: 10))
        try capture("adoption-light", in: app)

        app.buttons["adoption-confirm-button"].tap()
        assertLabelContains("adoption-error", text: "请输入", in: app)

        let nameField = app.textFields["adoption-name-field"]
        nameField.tap()
        nameField.typeText(String(repeating: "猫", count: 13))
        app.buttons["adoption-confirm-button"].tap()
        assertLabelContains("adoption-error", text: "最多只能有 12", in: app)

        app.terminate()
        app.launchEnvironment["POCKETPAL_TEST_RESET_DATA"] = "0"
        app.launch()
        adopt(name: "奶糖", in: app)

        assertLabel("status-mood", equals: "心情，80", in: app)
        assertLabel("status-hunger", equals: "饥饿，20", in: app)
        assertLabel("status-intimacy", equals: "亲密度，0", in: app)
        assertLabel("status-coins", equals: "金币，10", in: app)
        assertLabelContains("interaction-feed", text: "饼干 × 5", in: app)
        try capture("home-light", in: app)

        tapInteraction("interaction-feed", in: app)
        assertLabel("status-hunger", equals: "饥饿，0", in: app)
        tapInteraction("interaction-pet", in: app)
        tapInteraction("interaction-play", in: app)
        assertLabel("status-mood", equals: "心情，100", in: app)
        assertLabel("status-hunger", equals: "饥饿，5", in: app)
        assertLabel("status-intimacy", equals: "亲密度，6", in: app)
        assertLabel("status-coins", equals: "金币，12", in: app)
        XCTAssertFalse(app.buttons["interaction-pet"].isEnabled)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["home-pet-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["home-pet-name"].label, "奶糖")
        XCTAssertFalse(app.staticTexts["adoption-title"].exists)
        assertLabel("status-mood", equals: "心情，100", in: app)
        assertLabel("status-hunger", equals: "饥饿，5", in: app)
        assertLabel("status-intimacy", equals: "亲密度，6", in: app)
        assertLabel("status-coins", equals: "金币，12", in: app)
        assertLabelContains("interaction-feed", text: "饼干 × 4", in: app)
    }

    func testDarkModeHomeScreenshots() throws {
        let app = makeApp(
            resetData: true,
            extraArguments: ["-AppleInterfaceStyle", "Dark"]
        )
        app.launch()
        adopt(name: "奶糖", in: app)

        try capture("home-dark-top", in: app)
        scrollToVisible(app.buttons["interaction-feed"], in: app)
        try capture("home-dark-actions", in: app)
    }

    func testAccessibilityTextSizeScreenshots() throws {
        let app = makeApp(
            resetData: true,
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL"
            ]
        )
        app.launch()
        adopt(name: "奶糖", in: app)

        let homeScreen = app.scrollViews["home-screen"]
        XCTAssertTrue(homeScreen.waitForExistence(timeout: 10))
        XCTAssertEqual(homeScreen.value as? String, "最大辅助字号")

        try capture("home-accessibility-top", in: app)
        scrollToVisible(app.buttons["interaction-feed"], in: app)
        XCTAssertTrue(app.buttons["interaction-feed"].isHittable)
        try capture("home-accessibility-actions", in: app)
    }

    private func makeApp(
        resetData: Bool,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["POCKETPAL_TEST_DATA_DIRECTORY"] = dataToken
        app.launchEnvironment["POCKETPAL_TEST_RESET_DATA"] = resetData ? "1" : "0"
        app.launchArguments += extraArguments
        return app
    }

    private func adopt(name: String, in app: XCUIApplication) {
        let field = app.textFields["adoption-name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        app.buttons["adoption-confirm-button"].tap()
        XCTAssertTrue(app.staticTexts["home-pet-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["home-pet-name"].label, name)
    }

    private func tapInteraction(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        scrollToVisible(button, in: app)
        XCTAssertTrue(button.isEnabled)
        button.tap()
    }

    private func scrollToVisible(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        for _ in 0..<6 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func assertLabel(
        _ identifier: String,
        equals expected: String,
        in app: XCUIApplication
    ) {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private func assertLabelContains(
        _ identifier: String,
        text: String,
        in app: XCUIApplication
    ) {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private func capture(_ name: String, in app: XCUIApplication) throws {
        XCTAssertEqual(app.state, .runningForeground)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

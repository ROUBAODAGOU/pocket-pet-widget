import XCTest

@MainActor
final class DeepLinkUITests: XCTestCase {
    func testAdoptDeepLinkOpensAdoptionEntry() throws {
        continueAfterFailure = false
        let app = makeApp(dataToken: makeDataToken(), resetData: true)

        app.open(try routeURL("adopt"))

        assertRoute("adopt", request: "adopt", in: app)
        XCTAssertTrue(app.staticTexts["adoption-title"].waitForExistence(timeout: 10))
        try capture("deeplink-adopt", in: app)
    }

    func testHomeBackpackGrowthAndInvalidDeepLinks() throws {
        continueAfterFailure = false
        let app = makeApp(dataToken: makeDataToken(), resetData: true)
        app.launch()
        adopt(name: "奶糖", in: app)
        app.terminate()
        app.launchEnvironment["POCKETPAL_TEST_RESET_DATA"] = "0"

        let destinations = [
            ("backpack", "backpack", "backpack", "backpack-route-entry", "deeplink-backpack"),
            ("home", "home", "home", "home-screen", "deeplink-home"),
            ("growth", "growth", "growth", "growth-route-entry", "deeplink-growth"),
            ("not-a-route", "home", "invalid", "home-screen", "deeplink-invalid-fallback")
        ]

        for (urlRoute, expectedRoute, request, identifier, screenshotName) in destinations {
            app.open(try routeURL(urlRoute))
            assertRoute(expectedRoute, request: request, in: app)
            let destination = app.descendants(matching: .any)[identifier]
            XCTAssertTrue(destination.waitForExistence(timeout: 10), urlRoute)
            try capture(screenshotName, in: app)
        }
    }

    private func makeApp(dataToken: String, resetData: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["POCKETPAL_TEST_DATA_DIRECTORY"] = dataToken
        app.launchEnvironment["POCKETPAL_TEST_RESET_DATA"] = resetData ? "1" : "0"
        return app
    }

    private func makeDataToken() -> String {
        "DeepLinkUITests-\(UUID().uuidString)"
    }

    private func routeURL(_ route: String) throws -> URL {
        try XCTUnwrap(URL(string: "pocketpal://\(route)"))
    }

    private func assertRoute(
        _ route: String,
        request: String,
        in app: XCUIApplication
    ) {
        let routeRoot = app.descendants(matching: .any)[
            "root-route-\(route)-request-\(request)"
        ]
        XCTAssertTrue(routeRoot.waitForExistence(timeout: 10), route)
    }

    private func adopt(name: String, in app: XCUIApplication) {
        let field = app.textFields["adoption-name-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        app.buttons["adoption-keyboard-dismiss-button"].tap()
        app.buttons["adoption-confirm-button"].tap()
        XCTAssertTrue(app.staticTexts["home-pet-name"].waitForExistence(timeout: 10))
    }

    private func capture(_ name: String, in app: XCUIApplication) throws {
        XCTAssertEqual(app.state, .runningForeground)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

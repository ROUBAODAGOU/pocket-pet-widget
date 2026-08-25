import XCTest

@MainActor
final class ProjectSkeletonUITests: XCTestCase {
    func testAppLaunchesProjectStatusScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["project-status-title"].waitForExistence(timeout: 10))
    }
}

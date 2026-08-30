import Foundation
import XCTest
@testable import PocketPal

final class AppRouteTests: XCTestCase {
    func testEveryRouteRoundTripsThroughCanonicalURL() throws {
        for route in AppRoute.allCases {
            XCTAssertEqual(AppRoute(url: route.url), route)
        }
    }

    func testParserRejectsWrongSchemeExtraPathAndUnrecognizedRoute() throws {
        let invalidURLs = [
            "https://home",
            "pocketpal://home/extra",
            "pocketpal://unknown",
            "pocketpal://growth?source=test",
            "pocketpal://backpack#snacks",
            "pocketpal://user@home",
            "pocketpal://home:443"
        ]

        for value in invalidURLs {
            XCTAssertNil(AppRoute(url: try XCTUnwrap(URL(string: value))), value)
        }
    }
}

@MainActor
final class AppRouterTests: XCTestCase {
    func testValidURLNavigatesAndInvalidURLFallsBackHome() throws {
        let router = AppRouter(route: .growth)

        XCTAssertTrue(router.handle(try XCTUnwrap(URL(string: "pocketpal://backpack"))))
        XCTAssertEqual(router.route, .backpack)
        XCTAssertEqual(router.lastHandledRequest, .route(.backpack))

        XCTAssertFalse(router.handle(try XCTUnwrap(URL(string: "pocketpal://invalid"))))
        XCTAssertEqual(router.route, .home)
        XCTAssertEqual(router.lastHandledRequest, .invalid)
    }
}

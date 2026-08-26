import Foundation
import XCTest
@testable import PocketPal

final class WidgetViewContractTests: XCTestCase {
    func testWidgetDeclaresAllRequiredFamiliesAndDedicatedViews() throws {
        let widget = try source("PocketPal/Widget/PocketPalWidget.swift")
        XCTAssertTrue(
            widget.contains(
                ".supportedFamilies([.systemSmall, .systemMedium, .systemLarge])"
            )
        )

        let root = try source("PocketPal/Widget/Views/WidgetRootView.swift")
        for viewName in [
            "SmallPetWidgetView",
            "MediumPetWidgetView",
            "LargePetWidgetView"
        ] {
            XCTAssertTrue(root.contains(viewName))
        }
    }

    func testEveryFamilyRendersPetActionAndAllCoreMetrics() throws {
        let small = try source("PocketPal/Widget/Views/SmallPetWidgetView.swift")
        let medium = try source("PocketPal/Widget/Views/MediumPetWidgetView.swift")
        let large = try source("PocketPal/Widget/Views/LargePetWidgetView.swift")

        for familySource in [small, medium, large] {
            XCTAssertTrue(familySource.contains("PetAvatarView"))
            XCTAssertTrue(familySource.contains("snapshot.action"))
            XCTAssertTrue(familySource.contains(".accessibilityElement(children: .contain)"))
            XCTAssertFalse(familySource.contains("accessibilitySummary"))
        }
        XCTAssertTrue(small.contains("WidgetStatusKind.allCases"))
        XCTAssertTrue(medium.contains("WidgetStatusKind.allCases"))
        XCTAssertTrue(large.contains("WidgetStatusKind.allCases.filter"))
        XCTAssertTrue(large.contains("snapshot.coins"))
    }

    func testRootCoversPlaceholderUnadoptedSnapshotFailureAndPrivacy() throws {
        let root = try source("PocketPal/Widget/Views/WidgetRootView.swift")
        for state in [".placeholder", ".unadopted", ".snapshot", ".failure"] {
            XCTAssertTrue(root.contains("case \(state)"))
        }
        XCTAssertTrue(root.contains("redactionReasons.contains(.privacy)"))
        XCTAssertTrue(root.contains(".privacySensitive()"))
        XCTAssertTrue(root.contains("宠物状态已保护"))
    }

    func testStatusAndActionLabelsUseFullAccessibleNames() throws {
        let support = try source("PocketPal/Widget/Views/WidgetViewSupport.swift")
        for label in ["心情", "饥饿", "亲密度", "金币", "喂食", "抚摸", "玩耍"] {
            XCTAssertTrue(support.contains("\"\(label)\""))
        }
        XCTAssertTrue(support.contains(".accessibilityLabel"))
        XCTAssertFalse(support.contains("Text(\"心\")"))
        XCTAssertFalse(support.contains("Text(\"饿\")"))
        XCTAssertFalse(support.contains("Text(\"亲\")"))
        XCTAssertFalse(support.contains("Text(\"币\")"))
    }

    func testFamiliesDeclareAccessibilityLayoutBranches() throws {
        let support = try source("PocketPal/Widget/Views/WidgetViewSupport.swift")
        XCTAssertTrue(support.contains("Text(kind.compactTitle)"))
        for path in [
            "PocketPal/Widget/Views/SmallPetWidgetView.swift",
            "PocketPal/Widget/Views/MediumPetWidgetView.swift",
            "PocketPal/Widget/Views/LargePetWidgetView.swift"
        ] {
            let familySource = try source(path)
            XCTAssertTrue(familySource.contains("dynamicTypeSize.isAccessibilitySize"))
            XCTAssertTrue(familySource.contains("accessibilityLayout"))
        }
    }

    func testContextualInteractionUsesHungerThenAvailabilityPriority() {
        var snapshot = makeSnapshot(hunger: 70)
        XCTAssertEqual(snapshot.contextualInteraction, .feed)

        snapshot = makeSnapshot(hunger: 69)
        XCTAssertEqual(snapshot.contextualInteraction, .pet)

        snapshot.petAvailability = InteractionAvailability(
            isAvailable: false,
            blockedReason: .cooldown,
            availableAt: TestFixtures.referenceDate.addingTimeInterval(5 * 60)
        )
        XCTAssertEqual(snapshot.contextualInteraction, .play)

        snapshot.playAvailability = InteractionAvailability(
            isAvailable: false,
            blockedReason: .cooldown,
            availableAt: TestFixtures.referenceDate.addingTimeInterval(10 * 60)
        )
        XCTAssertEqual(snapshot.contextualInteraction, .pet)
    }

    private func makeSnapshot(hunger: Int) -> WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: TestFixtures.referenceDate,
            petName: "奶糖",
            action: .wandering,
            mood: 80,
            hunger: hunger,
            intimacy: 20,
            coins: 10,
            snackCount: 5,
            feedAvailability: .available,
            petAvailability: .available,
            playAvailability: .available,
            latestGrowthEvent: nil
        )
    }

    private func source(_ relativePath: String) throws -> String {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: projectRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

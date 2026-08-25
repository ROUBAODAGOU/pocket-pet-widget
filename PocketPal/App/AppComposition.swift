import Foundation

@MainActor
enum AppComposition {
    static func makeStore() -> AppStore {
        do {
            let repository = try AppGroupPetRepository(location: try repositoryLocation())
            let refreshNotifier = WidgetCenterRefreshNotifier()
            let getSnapshot = GetPetSnapshotUseCase(repository: repository)
            let adopt = AdoptPetUseCase(
                repository: repository,
                refreshNotifier: refreshNotifier
            )
            let interact = PerformPetInteractionUseCase(
                repository: repository,
                refreshNotifier: refreshNotifier
            )
            return AppStore(
                dependencies: AppStore.Dependencies(
                    loadSnapshot: { try getSnapshot.execute() },
                    adopt: { try adopt.execute(name: $0) },
                    interact: { try interact.execute($0) }
                )
            )
        } catch {
            return AppStore(
                configurationErrorMessage: "无法打开本地宠物数据，请检查 App Group 配置后重试。"
            )
        }
    }

    private static func repositoryLocation() throws -> SharedContainerLocation {
#if DEBUG
        if let testingToken = ProcessInfo.processInfo.environment["POCKETPAL_TEST_DATA_DIRECTORY"],
           !testingToken.isEmpty {
            let allowedCharacters = CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: "-_"))
            guard testingToken.count <= 100,
                  testingToken.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
                throw PetRepositoryError.containerUnavailable("Invalid UI test data token")
            }

            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("PocketPalUITests", isDirectory: true)
                .appendingPathComponent(testingToken, isDirectory: true)
            if ProcessInfo.processInfo.environment["POCKETPAL_TEST_RESET_DATA"] == "1" {
                try? FileManager.default.removeItem(at: directory)
            }
            return .testingDirectory(directory)
        }
#endif
        return .appGroup(identifier: ProjectConfiguration.appGroupIdentifier)
    }
}

import Foundation

enum SharedContainerLocation: Equatable, Sendable {
    case appGroup(identifier: String)
    case testingDirectory(URL)
}

enum SharedContainerResolver {
    static func resolve(_ location: SharedContainerLocation) throws -> URL {
        let directory: URL
        switch location {
        case let .appGroup(identifier):
            guard let groupDirectory = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: identifier
            ) else {
                throw PetRepositoryError.containerUnavailable(identifier)
            }
            directory = groupDirectory
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("PocketPal", isDirectory: true)
        case let .testingDirectory(url):
            directory = url
        }

        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw PetRepositoryError.ioFailure(error.localizedDescription)
        }
        return directory
    }
}

import Foundation

protocol DateProviding: Sendable {
    func now() -> Date
}

struct SystemDateProvider: DateProviding {
    func now() -> Date {
        Date()
    }
}

struct FixedDateProvider: DateProviding {
    private let date: Date

    init(_ date: Date) {
        self.date = date
    }

    func now() -> Date {
        date
    }
}

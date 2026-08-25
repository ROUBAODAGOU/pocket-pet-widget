import Foundation

enum PetNameValidator {
    static let maximumVisibleCharacterCount = 12

    static func validate(_ input: String) throws -> String {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw PetNameValidationError.empty
        }
        guard !normalized.unicodeScalars.contains(where: CharacterSet.newlines.contains) else {
            throw PetNameValidationError.containsLineBreak
        }
        guard !normalized.unicodeScalars.contains(where: {
            $0.properties.generalCategory == .control
        }) else {
            throw PetNameValidationError.containsUnsupportedCharacter
        }

        let visibleCharacterCount = normalized.reduce(into: 0) { count, character in
            if character.unicodeScalars.contains(where: isVisible) {
                count += 1
            }
        }
        guard visibleCharacterCount > 0 else {
            throw PetNameValidationError.empty
        }
        guard visibleCharacterCount <= maximumVisibleCharacterCount else {
            throw PetNameValidationError.tooLong(maximum: maximumVisibleCharacterCount)
        }
        return normalized
    }

    static func visibleCharacterCount(in input: String) -> Int {
        input.reduce(into: 0) { count, character in
            if character.unicodeScalars.contains(where: isVisible) {
                count += 1
            }
        }
    }

    private static func isVisible(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .control,
             .format,
             .lineSeparator,
             .paragraphSeparator,
             .spaceSeparator,
             .nonspacingMark,
             .spacingMark,
             .enclosingMark:
            false
        default:
            true
        }
    }
}

enum PetNameValidationError: Error, Equatable, Sendable {
    case empty
    case containsLineBreak
    case containsUnsupportedCharacter
    case tooLong(maximum: Int)
}

// Turns raylib's SCREAMING_SNAKE_CASE constant names into Swift identifiers.

let swiftKeywords: Set<String> = [
    "default", "repeat", "static", "class", "struct", "enum", "func", "var", "let", "return", "true",
    "false", "nil", "self", "super", "import", "where", "as", "is", "in", "for", "while", "if", "else",
    "switch", "case", "break", "continue", "operator", "protocol", "extension", "init", "deinit",
    "subscript", "throws", "try", "catch", "do", "guard", "defer", "public", "private", "internal",
    "fileprivate", "open", "inout", "any", "some",
]

/// The common `PREFIX_` that every value of an enum shares, cut at the last underscore.
func commonPrefix(of names: [String]) -> String {
    guard var prefix = names.first else { return "" }
    for name in names.dropFirst() {
        while !name.hasPrefix(prefix) {
            prefix.removeLast()
        }
    }
    guard let underscore = prefix.lastIndex(of: "_") else { return "" }
    return String(prefix[...underscore])
}

/// `KEY_LEFT_SHIFT` with prefix `KEY_` becomes `leftShift`; keywords get backticks.
func swiftCaseName(_ cName: String, prefix: String) -> String {
    var rest = String(cName.dropFirst(prefix.count))
    if rest.hasPrefix("KP_") {
        rest = "KEYPAD_" + rest.dropFirst(3)
    }
    let parts = rest.split(separator: "_").map(String.init)
    var name = parts[0].lowercased()
    for part in parts.dropFirst() {
        name += isPixelLayout(part) ? part : part.prefix(1).uppercased() + part.dropFirst().lowercased()
    }
    if let first = name.first, first.isNumber {
        name = "_" + name
    }
    return swiftKeywords.contains(name) ? "`\(name)`" : name
}

/// `R8G8B8A8`, `R32`, `R5G6B5`: every letter is followed by a digit, so keep the case as is.
private func isPixelLayout(_ part: String) -> Bool {
    let characters = Array(part)
    guard characters.contains(where: \.isNumber) else { return false }
    for (index, character) in characters.enumerated() where character.isLetter {
        guard index + 1 < characters.count, characters[index + 1].isNumber else { return false }
    }
    return true
}

/// Escapes a description for use in a `///` comment.
func docComment(_ text: String, indent: String = "") -> String {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return "" }
    let sentence = trimmed.hasSuffix(".") ? trimmed : trimmed + "."
    return "\(indent)/// \(sentence.prefix(1).uppercased() + sentence.dropFirst())\n"
}

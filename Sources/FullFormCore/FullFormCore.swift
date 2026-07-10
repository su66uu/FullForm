import Foundation

public struct GlossaryEntry: Decodable {
    let fullForm: String
    let description: String?
    let example: String?
}

public typealias Glossary = [String: GlossaryEntry]

public func normalizeLookupTerm(_ term: String) -> String {
    let surroundingCharacters = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
    return term.trimmingCharacters(in: surroundingCharacters).uppercased()
}

public func formatLookupResult(term: String, entry: GlossaryEntry?) -> String {
    guard let entry else {
        return "No FullForm entry found for \"\(term)\"."
    }

    var lines = [
        term,
        "",
        entry.fullForm,
    ]

    if let description = entry.description {
        lines.append("")
        lines.append(description)
    }

    if let example = entry.example {
        lines.append("")
        lines.append("Example: \(example)")
    }

    return lines.joined(separator: "\n")
}

public func decodeGlossary(from data: Data) throws -> Glossary {
    try JSONDecoder().decode(Glossary.self, from: data)
}

public func lookupGlossaryEntry(for term: String, in glossary: Glossary) -> GlossaryEntry? {
    let lookupKey = normalizeLookupTerm(term)
    return glossary[lookupKey]
}

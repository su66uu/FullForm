// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

struct GlossaryEntry: Decodable {
    let fullform: String
    let description: String?
    let example: String?
}

@main
struct Fullform {
    static func main() {
        let arguments = CommandLine.arguments.dropFirst()

        guard arguments.count == 2 else {
            print("Usage: fullform lookup <term>")
            Foundation.exit(1)
        }

        let command = arguments[arguments.startIndex]
        let term = arguments[arguments.index(after: arguments.startIndex)]

        guard command == "lookup" else {
            print("Usage: fullform lookup <term>")
            Foundation.exit(1)
        }

        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Select text first")
            Foundation.exit(1)
        }

        print("Looking up: \(term)")
    }
}
typealias Glossary = [String: GlossaryEntry]

func decodeGlossary(from data: Data) throws -> Glossary {
    try JSONDecoder().decode(Glossary.self, from: data)
}

func loadGlossary(from path: String) throws -> Glossary {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    return try decodeGlossary(from: data)
}

func normalizeLookupTerm(_ term: String) -> String {
    let surroundingCharacters = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
    return term.trimmingCharacters(in: surroundingCharacters)
}

func formatLookupResult(term: String, entry: GlossaryEntry?) -> String {
    guard let entry else {
        return "No entry found for \"\(term)\"."
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

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

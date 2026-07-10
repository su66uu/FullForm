// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import FullFormCore

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

        let glossary: Glossary

        do {
            glossary = try loadGlossary(from: defaultGlossaryPath())
        } catch CocoaError.fileReadNoSuchFile {
            let message = missingGlossaryMessage(path: defaultGlossaryPath())
            presentMessage(message)
            Foundation.exit(1)
        } catch DecodingError.dataCorrupted {
            print("FullForm glossary JSON is invalid")
            Foundation.exit(1)
        } catch DecodingError.keyNotFound {
            print("FullForm glossary JSON is missing a required field.")
            Foundation.exit(1)
        } catch {
            print("Could not load FullForm glossary: \(error)")
            Foundation.exit(1)
        }

        let lookupKey = normalizeLookupTerm(term)
        let entry = lookupGlossaryEntry(for: term, in: glossary)
        let message = formatLookupResult(term: lookupKey, entry: entry)
        presentMessage(message)
    }
}

func loadGlossary(from path: String) throws -> Glossary {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    return try decodeGlossary(from: data)
}

func makeDialogScript(message: String) -> String {
    let escapedMessage = message
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

    return "display dialog \"\(escapedMessage)\" buttons {\"OK\"} default button \"OK\""
}

func showDialog(message: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", makeDialogScript(message: message)]

    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        throw CocoaError(.executableLoad)
    }
}

func defaultGlossaryPath() -> String {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    let glossaryURL = homeDirectory
        .appendingPathComponent("Library")
        .appendingPathComponent("Application Support")
        .appendingPathComponent("FullForm")
        .appendingPathComponent("fullform.json")

    return glossaryURL.path
}

func missingGlossaryMessage(path: String) -> String {
    """
    FullForm glossary file is missing.

    Expected location:
    \(path)
    """
}

func presentMessage(_ message: String) {
    do {
        try showDialog(message: message)
    } catch {
        print(message)
    }
}

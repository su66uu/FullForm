// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import FullFormCore

@main
struct Fullform {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if arguments.count == 1, arguments[0] == "install-service" {
            installService()
            return
        }

        guard arguments.count == 2, arguments[0] == "lookup" else {
            printUsage()
            Foundation.exit(1)
        }

        let term = arguments[1]

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

struct SupportFileSources {
    let workflowURL: URL
    let sampleGlossaryURL: URL
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
    defaultAppSupportDirectoryURL().appendingPathComponent("fullform.json").path
}

func defaultServicesDirectoryURL() -> URL {
    installHomeDirectoryURL()
        .appendingPathComponent("Library")
        .appendingPathComponent("Services")
}

func defaultAppSupportDirectoryURL() -> URL {
    installHomeDirectoryURL()
        .appendingPathComponent("Library")
        .appendingPathComponent("Application Support")
        .appendingPathComponent("FullForm")
}

func installHomeDirectoryURL() -> URL {
    let environment = ProcessInfo.processInfo.environment
    if let installHome = environment["FULLFORM_INSTALL_HOME"], !installHome.isEmpty {
        return URL(fileURLWithPath: installHome)
    }

    return FileManager.default.homeDirectoryForCurrentUser
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

func printUsage() {
    print(
        """
        Usage:
          fullform lookup <term>
          fullform install-service
        """
    )
}

func installService() {
    guard let sources = findSupportFileSources() else {
        print("Could not find FullForm support files. Reinstall FullForm and try again.")
        Foundation.exit(1)
    }

    do {
        let result = try installSupportFiles(
            workflowSourceURL: sources.workflowURL,
            sampleGlossarySourceURL: sources.sampleGlossaryURL,
            servicesDirectoryURL: defaultServicesDirectoryURL(),
            appSupportDirectoryURL: defaultAppSupportDirectoryURL()
        )

        print("Installed Look Up FullForm Quick Action.")
        if result.installedGlossary {
            print("Installed sample glossary.")
        } else {
            print("Existing glossary found; left it unchanged.")
        }
    } catch {
        print("Could not install FullForm support files: \(error)")
        Foundation.exit(1)
    }
}

func findSupportFileSources(fileManager: FileManager = .default) -> SupportFileSources? {
    for sources in supportFileSourceCandidates() {
        var isDirectory: ObjCBool = false
        let workflowExists = fileManager.fileExists(atPath: sources.workflowURL.path, isDirectory: &isDirectory)
        let glossaryExists = fileManager.fileExists(atPath: sources.sampleGlossaryURL.path)

        if workflowExists, isDirectory.boolValue, glossaryExists {
            return sources
        }
    }

    return nil
}

func supportFileSourceCandidates() -> [SupportFileSources] {
    var candidates: [SupportFileSources] = []
    let environment = ProcessInfo.processInfo.environment

    if let resourceDirectory = environment["FULLFORM_RESOURCE_DIR"], !resourceDirectory.isEmpty {
        candidates.append(supportFileSources(in: URL(fileURLWithPath: resourceDirectory)))
    }

    if let executableURL = executableURL() {
        let installRootURL = executableURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        candidates.append(supportFileSources(in: installRootURL.appendingPathComponent("share/fullform")))
    }

    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    candidates.append(
        SupportFileSources(
            workflowURL: currentDirectoryURL.appendingPathComponent("Workflows/Look Up FullForm.workflow"),
            sampleGlossaryURL: currentDirectoryURL.appendingPathComponent("Resources/fullform.json")
        )
    )

    return candidates
}

func supportFileSources(in resourceDirectoryURL: URL) -> SupportFileSources {
    SupportFileSources(
        workflowURL: resourceDirectoryURL.appendingPathComponent("Look Up FullForm.workflow"),
        sampleGlossaryURL: resourceDirectoryURL.appendingPathComponent("fullform.json")
    )
}

func executableURL() -> URL? {
    guard let executablePath = CommandLine.arguments.first else {
        return nil
    }

    return URL(fileURLWithPath: executablePath).resolvingSymlinksInPath()
}

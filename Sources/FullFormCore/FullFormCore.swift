import Foundation

public struct GlossaryEntry: Codable {
    let fullForm: String
    let description: String?
    let example: String?
}

public typealias Glossary = [String: GlossaryEntry]

public struct SupportInstallResult {
    public let installedWorkflow: Bool
    public let installedGlossary: Bool
}

public struct SupportUninstallResult {
    public let removedWorkflow: Bool
}

public struct GlossaryUpdateResult {
    public let glossary: Glossary
    public let addedEntries: Int
}

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

public func encodeGlossary(_ glossary: Glossary) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(glossary)
}

public func lookupGlossaryEntry(for term: String, in glossary: Glossary) -> GlossaryEntry? {
    let lookupKey = normalizeLookupTerm(term)
    return glossary[lookupKey]
}

public func updateGlossary(existing: Glossary, bundled: Glossary) -> GlossaryUpdateResult {
    var updatedGlossary = existing
    var addedEntries = 0

    for (key, entry) in bundled where updatedGlossary[key] == nil {
        updatedGlossary[key] = entry
        addedEntries += 1
    }

    return GlossaryUpdateResult(glossary: updatedGlossary, addedEntries: addedEntries)
}

public func installSupportFiles(
    workflowSourceURL: URL,
    sampleGlossarySourceURL: URL,
    servicesDirectoryURL: URL,
    appSupportDirectoryURL: URL,
    fileManager: FileManager = .default
) throws -> SupportInstallResult {
    let workflowTargetURL = servicesDirectoryURL.appendingPathComponent("Look Up FullForm.workflow")
    let glossaryTargetURL = appSupportDirectoryURL.appendingPathComponent("fullform.json")

    try fileManager.createDirectory(at: servicesDirectoryURL, withIntermediateDirectories: true)
    if fileManager.fileExists(atPath: workflowTargetURL.path) {
        try fileManager.removeItem(at: workflowTargetURL)
    }
    try fileManager.copyItem(at: workflowSourceURL, to: workflowTargetURL)

    try fileManager.createDirectory(at: appSupportDirectoryURL, withIntermediateDirectories: true)
    let installedGlossary: Bool
    if fileManager.fileExists(atPath: glossaryTargetURL.path) {
        installedGlossary = false
    } else {
        try fileManager.copyItem(at: sampleGlossarySourceURL, to: glossaryTargetURL)
        installedGlossary = true
    }

    return SupportInstallResult(installedWorkflow: true, installedGlossary: installedGlossary)
}

public func uninstallSupportFiles(
    servicesDirectoryURL: URL,
    fileManager: FileManager = .default
) throws -> SupportUninstallResult {
    let workflowTargetURL = servicesDirectoryURL.appendingPathComponent("Look Up FullForm.workflow")

    guard fileManager.fileExists(atPath: workflowTargetURL.path) else {
        return SupportUninstallResult(removedWorkflow: false)
    }

    try fileManager.removeItem(at: workflowTargetURL)
    return SupportUninstallResult(removedWorkflow: true)
}

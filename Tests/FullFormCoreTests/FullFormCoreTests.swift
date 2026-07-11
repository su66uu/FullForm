@testable import FullFormCore
import XCTest

final class FullFormCoreTests: XCTestCase {
    func testNormalizeLookupTermUppercasesInput() {
        XCTAssertEqual(normalizeLookupTerm("irl"), "IRL")
    }

    func testNormalizeLookupTermTrimsWhitespace() {
        XCTAssertEqual(normalizeLookupTerm(" IRL "), "IRL")
    }

    func testNormalizeLookupTermRemovesSurroundingPunctuation() {
        XCTAssertEqual(normalizeLookupTerm("IRL."), "IRL")
    }

    func testNormalizeLookupTermDoesNotExtractTermFromSentence() {
        XCTAssertEqual(normalizeLookupTerm("Let's discuss IRL"), "LET'S DISCUSS IRL")
    }

    func testDecodeGlossaryReadsFullForm() throws {
        let json = """
        {
          "IRL": {
            "fullForm": "In Real Life"
          }
        }
        """.data(using: .utf8)!

        let glossary = try decodeGlossary(from: json)

        XCTAssertNotNil(glossary["IRL"])
        XCTAssertEqual(glossary["IRL"]?.fullForm, "In Real Life")
    }

    func testDecodeGlossaryReadsOptionalFields() throws {
        let json = """
        {
          "IRL": {
            "fullForm": "In Real Life",
            "description": "Used for in-person context.",
            "example": "Let's discuss this IRL."
          }
        }
        """.data(using: .utf8)!

        let glossary = try decodeGlossary(from: json)

        XCTAssertEqual(glossary["IRL"]?.description, "Used for in-person context.")
        XCTAssertEqual(glossary["IRL"]?.example, "Let's discuss this IRL.")
    }

    func testDecodeGlossaryThrowsForMalformedJSON() {
        let json = """
        {
          "IRL": {
            "fullForm": "In Real Life"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decodeGlossary(from: json))
    }

    func testDecodeGlossaryThrowsWhenFullFormIsMissing() {
        let json = """
        {
          "IRL": {
            "description": "Used for in-person context."
          }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decodeGlossary(from: json))
    }

    func testFormatLookupResultIncludesAvailableFields() throws {
        let json = """
        {
          "IRL": {
            "fullForm": "In Real Life",
            "description": "Used for in-person context.",
            "example": "Let's discuss this IRL."
          }
        }
        """.data(using: .utf8)!
        let glossary = try decodeGlossary(from: json)

        let message = formatLookupResult(term: "IRL", entry: glossary["IRL"])

        XCTAssertEqual(
            message,
            """
            IRL

            In Real Life

            Used for in-person context.

            Example: Let's discuss this IRL.
            """
        )
    }

    func testFormatLookupResultOmitsMissingOptionalFields() throws {
        let json = """
        {
          "IRL": {
            "fullForm": "In Real Life"
          }
        }
        """.data(using: .utf8)!
        let glossary = try decodeGlossary(from: json)

        let message = formatLookupResult(term: "IRL", entry: glossary["IRL"])

        XCTAssertEqual(
            message,
            """
            IRL

            In Real Life
            """
        )
    }

    func testFormatLookupResultShowsNotFoundMessage() {
        let message = formatLookupResult(term: "XYZ", entry: nil)

        XCTAssertEqual(message, "No FullForm entry found for \"XYZ\".")
    }

    func testLookupGlossaryEntryFindsExactNormalizedMatch() throws {
        let glossary = try decodeGlossary(from: XCTUnwrap("""
        {
          "IRL": {
            "fullForm": "In Real Life"
          }
        }
        """.data(using: .utf8)))

        XCTAssertEqual(lookupGlossaryEntry(for: "irl", in: glossary)?.fullForm, "In Real Life")
        XCTAssertEqual(lookupGlossaryEntry(for: "IRL.", in: glossary)?.fullForm, "In Real Life")
    }

    func testLookupGlossaryEntryDoesNotScanInsideSentence() throws {
        let glossary = try decodeGlossary(from: XCTUnwrap("""
        {
          "IRL": {
            "fullForm": "In Real Life"
          }
        }
        """.data(using: .utf8)))

        XCTAssertNil(lookupGlossaryEntry(for: "Let's discuss IRL", in: glossary))
    }

    func testInstallSupportFilesCopiesWorkflowAndCreatesMissingGlossary() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let workflowSourceURL = root.appendingPathComponent("Source.workflow")
        let workflowContentsURL = workflowSourceURL.appendingPathComponent("Contents")
        let sampleGlossaryURL = root.appendingPathComponent("fullform.json")
        let servicesURL = root.appendingPathComponent("Services")
        let appSupportURL = root.appendingPathComponent("Application Support/FullForm")

        try FileManager.default.createDirectory(at: workflowContentsURL, withIntermediateDirectories: true)
        try "workflow".write(to: workflowContentsURL.appendingPathComponent("document.wflow"), atomically: true, encoding: .utf8)
        try #"{"IRL":{"fullForm":"In Real Life"}}"#.write(to: sampleGlossaryURL, atomically: true, encoding: .utf8)

        let result = try installSupportFiles(
            workflowSourceURL: workflowSourceURL,
            sampleGlossarySourceURL: sampleGlossaryURL,
            servicesDirectoryURL: servicesURL,
            appSupportDirectoryURL: appSupportURL
        )

        XCTAssertTrue(result.installedWorkflow)
        XCTAssertTrue(result.installedGlossary)
        XCTAssertTrue(FileManager.default.fileExists(atPath: servicesURL.appendingPathComponent("Look Up FullForm.workflow/Contents/document.wflow").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: appSupportURL.appendingPathComponent("fullform.json").path))
    }

    func testInstallSupportFilesUpdatesWorkflowWithoutOverwritingExistingGlossary() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let workflowSourceURL = root.appendingPathComponent("Source.workflow")
        let workflowContentsURL = workflowSourceURL.appendingPathComponent("Contents")
        let sampleGlossaryURL = root.appendingPathComponent("fullform.json")
        let servicesURL = root.appendingPathComponent("Services")
        let installedWorkflowURL = servicesURL.appendingPathComponent("Look Up FullForm.workflow")
        let appSupportURL = root.appendingPathComponent("Application Support/FullForm")
        let existingGlossaryURL = appSupportURL.appendingPathComponent("fullform.json")

        try FileManager.default.createDirectory(at: workflowContentsURL, withIntermediateDirectories: true)
        try "new workflow".write(to: workflowContentsURL.appendingPathComponent("document.wflow"), atomically: true, encoding: .utf8)
        try #"{"IRL":{"fullForm":"In Real Life"}}"#.write(to: sampleGlossaryURL, atomically: true, encoding: .utf8)

        try FileManager.default.createDirectory(at: installedWorkflowURL, withIntermediateDirectories: true)
        try "old workflow".write(to: installedWorkflowURL.appendingPathComponent("old.txt"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try "custom glossary".write(to: existingGlossaryURL, atomically: true, encoding: .utf8)

        let result = try installSupportFiles(
            workflowSourceURL: workflowSourceURL,
            sampleGlossarySourceURL: sampleGlossaryURL,
            servicesDirectoryURL: servicesURL,
            appSupportDirectoryURL: appSupportURL
        )

        XCTAssertTrue(result.installedWorkflow)
        XCTAssertFalse(result.installedGlossary)
        XCTAssertFalse(FileManager.default.fileExists(atPath: installedWorkflowURL.appendingPathComponent("old.txt").path))
        XCTAssertEqual(try String(contentsOf: installedWorkflowURL.appendingPathComponent("Contents/document.wflow")), "new workflow")
        XCTAssertEqual(try String(contentsOf: existingGlossaryURL), "custom glossary")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fullform-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

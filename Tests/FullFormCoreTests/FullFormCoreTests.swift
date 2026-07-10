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
}

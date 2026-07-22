//
//  VaccineScanDecodingTests.swift
//  PawsonaTests
//
//  Decoding a Gemini reply into ScannedVisit values. No network — these guard
//  the mapping that used to drop vaccines, and they stay green in CI even when
//  the API is unreachable.
//

import Foundation
import Testing
@testable import Pawsona

@Suite("Vaccine scan decoding")
struct VaccineScanDecodingTests {
    /// Wraps a bare JSON payload in the envelope generateContent returns.
    private func response(_ payload: String) -> Data {
        let escaped = payload
            .replacing(#"\"#, with: #"\\"#)
            .replacing("\"", with: "\\\"")
            .replacing("\n", with: #"\n"#)
        return Data(#"{"candidates":[{"content":{"parts":[{"text":"\#(escaped)"}]}}]}"#.utf8)
    }

    @Test("A page with two visits decodes to two records")
    func multipleVisitsDecode() throws {
        let visits = try GeminiScanner.decodeVisits(from: response("""
            {"visits":[
              {"ink_marks_seen":"Parvo=ink tick","date_given":"2020-05-26","next_visit_date":"2020-06-26",
               "vaccines":["parvovirus","distemper","parainfluenza","hepatitis","leptospira"]},
              {"ink_marks_seen":"Rabies=ink tick","date_given":"2020-06-12","next_visit_date":"2021-06-12",
               "vaccines":["rabies"]}
            ]}
            """))

        #expect(visits.count == 2)
        #expect(visits[0].vaccines == [.parvovirus, .distemper, .parainfluenza, .hepatitis, .leptospira])
        #expect(visits[1].vaccines == [.rabies])
        #expect(visits[0].dateGiven == Self.localDate(2020, 5, 26))
        #expect(visits[1].nextVisitDate == Self.localDate(2021, 6, 12))
    }

    @Test("Blocks with no vaccines are dropped as blank future visits")
    func emptyBlocksDropped() throws {
        let visits = try GeminiScanner.decodeVisits(from: response("""
            {"visits":[
              {"ink_marks_seen":"Distemper=ink tick","date_given":"2025-09-06","vaccines":["distemper"]},
              {"ink_marks_seen":"all printed box only","date_given":null,"vaccines":[]}
            ]}
            """))

        #expect(visits.count == 1)
        #expect(visits[0].vaccines == [.distemper])
    }

    @Test("A page where nothing is ticked reports that, not an empty success")
    func nothingTickedThrows() {
        #expect(throws: GeminiScanner.ScanError.noVaccinationsFound) {
            _ = try GeminiScanner.decodeVisits(from: response("""
                {"visits":[{"ink_marks_seen":"all printed box only","date_given":null,"vaccines":[]}]}
                """))
        }
    }

    @Test("A missing date decodes to nil rather than today")
    func missingDateIsNil() throws {
        let visits = try GeminiScanner.decodeVisits(from: response("""
            {"visits":[{"ink_marks_seen":"Rabies=ink tick","date_given":null,"vaccines":["rabies"]}]}
            """))

        #expect(visits[0].dateGiven == nil)
        #expect(visits[0].nextVisitDate == nil)
    }

    @Test("Off-schema and duplicate vaccine names are dropped, known ones kept")
    func unknownNamesDropped() throws {
        let visits = try GeminiScanner.decodeVisits(from: response("""
            {"visits":[{"ink_marks_seen":"x","date_given":"2025-09-06",
             "vaccines":["parvovirus","Parvo","coronavirus","parvovirus","rabies"]}]}
            """))

        #expect(visits[0].vaccines == [.parvovirus, .rabies])
    }

    @Test("An empty or malformed reply throws rather than saving nothing silently")
    func malformedReplyThrows() {
        #expect(throws: GeminiScanner.ScanError.unreadableResponse) {
            _ = try GeminiScanner.decodeVisits(from: Data("{}".utf8))
        }
    }

    @Test("A reply whose payload isn't the expected shape reads as unreadable, not a crash")
    func wrongPayloadShapeThrows() {
        #expect(throws: GeminiScanner.ScanError.unreadableResponse) {
            _ = try GeminiScanner.decodeVisits(from: response(#"{"visits":"none"}"#))
        }
    }

    @Test(
        "HTTP failures map onto messages a user can act on",
        arguments: [
            (429, "RESOURCE_EXHAUSTED quota", GeminiScanner.ScanError.quotaExceeded),
            (403, "forbidden", .notAuthorized),
            (401, "unauthenticated", .notAuthorized),
            (400, "API key not valid. Please pass a valid API key.", .notAuthorized),
            (400, "invalid request payload", .unreadableResponse),
            (503, "The model is overloaded.", .serviceUnavailable),
            (500, "internal", .serviceUnavailable),
            (418, "teapot", .unreadableResponse)
        ]
    )
    func httpStatusMapping(_ status: Int, _ body: String, _ expected: GeminiScanner.ScanError) {
        #expect(GeminiScanner.scanError(forStatus: status, body: Data(body.utf8)) == expected)
    }

    /// The whole point of the custom errors: Gemini's raw JSON never reaches an alert.
    @Test("No error message leaks the raw API response")
    func messagesStayHumanReadable() {
        let quotaBody = #"{"error":{"code":429,"status":"RESOURCE_EXHAUSTED","message":"quota"}}"#
        let error = GeminiScanner.scanError(forStatus: 429, body: Data(quotaBody.utf8))
        let message = try? #require(error.errorDescription)

        #expect(message?.contains("RESOURCE_EXHAUSTED") == false)
        #expect(message?.contains("{") == false)
        #expect(message?.contains("http") == false)
    }

    @Test("Only overload is retried automatically")
    func transientErrors() {
        #expect(GeminiScanner.ScanError.serviceUnavailable.isTransient)
        #expect(!GeminiScanner.ScanError.quotaExceeded.isTransient)
        #expect(!GeminiScanner.ScanError.notAuthorized.isTransient)
        #expect(!GeminiScanner.ScanError.offline.isTransient)
    }

    @Test("Every error case says something, and says it without jargon")
    func everyCaseHasCopy() {
        let errors: [GeminiScanner.ScanError] = [
            .missingKey, .notAuthorized, .cameraUnavailable, .badImage, .offline,
            .quotaExceeded, .serviceUnavailable, .unreadableResponse, .noVaccinationsFound
        ]

        for error in errors {
            let message = error.errorDescription ?? ""
            #expect(!message.isEmpty, Comment(rawValue: "\(error) has no message"))
            #expect(!message.contains("Gemini"), Comment(rawValue: "\(error) names the vendor"))
            #expect(!message.contains("API"), Comment(rawValue: "\(error) leaks API jargon"))
        }
    }

    @Test(
        "Book date strings map to the right day",
        arguments: [
            ("2020-05-26", Self.localDate(2020, 5, 26)),
            ("2025-09-06", Self.localDate(2025, 9, 6)),
            ("26/05/2020", Self.localDate(2020, 5, 26)),
            ("", nil)
        ]
    )
    func dateParsing(_ input: String, _ expected: Date?) {
        #expect(ScannedVisit.date(from: input) == expected)
    }

    private static func localDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }
}

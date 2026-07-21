//
//  ScannedVisit.swift
//  Pawsona
//
//  One vaccination visit block read off a photographed vaccine book. A single
//  page usually holds two or three of these, so a scan produces an array.
//

import Foundation

struct ScannedVisit: Decodable, Identifiable {
    var id = UUID()
    /// Gemini's row-by-row verdict on which checkboxes carry pen ink. It is a
    /// reasoning step, not user-facing — asking for it first is what stops the
    /// model treating a printed coloured checkbox as a tick.
    var inkMarksSeen: String = ""
    var dateGiven: Date?
    var nextVisitDate: Date?
    var vaccines: [VaccineType] = []

    private enum CodingKeys: String, CodingKey {
        case inkMarksSeen = "ink_marks_seen"
        case dateGiven = "date_given"
        case nextVisitDate = "next_visit_date"
        case vaccines
    }

    init(
        inkMarksSeen: String = "",
        dateGiven: Date? = nil,
        nextVisitDate: Date? = nil,
        vaccines: [VaccineType] = []
    ) {
        self.inkMarksSeen = inkMarksSeen
        self.dateGiven = dateGiven
        self.nextVisitDate = nextVisitDate
        self.vaccines = vaccines
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inkMarksSeen = try container.decodeIfPresent(String.self, forKey: .inkMarksSeen) ?? ""
        dateGiven = Self.date(from: try container.decodeIfPresent(String.self, forKey: .dateGiven))
        nextVisitDate = Self.date(from: try container.decodeIfPresent(String.self, forKey: .nextVisitDate))

        // The response schema pins these to VaccineType.allCases, so an unknown
        // string means the model went off-script — drop it rather than fail the
        // whole scan. Duplicates are dropped too, since the record stores a list.
        let names = try container.decodeIfPresent([String].self, forKey: .vaccines) ?? []
        vaccines = names.compactMap(VaccineType.init(rawValue:)).reduce(into: []) { unique, vaccine in
            if !unique.contains(vaccine) { unique.append(vaccine) }
        }
    }

    /// The prompt pins dates to `YYYY-MM-DD`; anything else is treated as unread.
    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return try? Date(string, strategy: dateStrategy)
    }

    private static let dateStrategy = Date.ISO8601FormatStyle(
        dateSeparator: .dash,
        timeZone: .autoupdatingCurrent
    )
    .year()
    .month()
    .day()
}

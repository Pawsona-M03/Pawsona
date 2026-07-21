//
//  GeminiScanner.swift
//  Pawsona
//
//  Created by Aloysia Jennifer on 20/07/26.
//
//  Sends the vaccine book photo straight to Gemini (multimodal, so no OCR
//  step) and asks for JSON constrained by a response schema.
//
//  Accuracy hinges on two things, both verified against the books in
//  PawsonaTests/Fixtures:
//
//  1. The schema pins every vaccine string to a VaccineType raw value, so the
//     model cannot answer "Parvo" when the app stores "parvovirus".
//  2. Each visit reports `ink_marks_seen` *before* `vaccines`. Books like
//     Nobivac print a solid coloured icon as the checkbox, and without the
//     row-by-row pass the model reads that printing as a tick and invents
//     vaccines nobody was given.
//

import OSLog
import UIKit

struct GeminiScanner {
    static let model = "gemini-3.6-flash"

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Pawsona",
        category: "GeminiScanner"
    )

    private static let prompt = """
        You are reading a photo of a pet vaccination booklet (buku vaksin). Extract every DOG
        vaccination visit that has actually been administered.

        A booklet page has several visit blocks stacked vertically. Each block has its own date and its
        own checklist. Return one entry in "visits" per block that has at least one dog vaccine marked.

        RULES

        1. DOG ONLY. Booklets list dogs and cats side by side. The dog column is headed "DOGS" or
           "ANJING"; the cat column is "CATS" or "KUCING". Ignore the cat column completely, including
           FeLV, Panleucopenia / Panleukopenia, Rhinotracheitis, Calicivirus, Chlamydia, Leukimia,
           Infectious Peritonitis, and Tricat products.

        2. ONLY HANDWRITTEN MARKS COUNT. Every disease row is pre-printed with a checkbox: a plain
           square in some books, a small coloured pet/shirt/paw icon in others (Nobivac uses a solid
           teal shirt). That printed box is ALWAYS there and is ALWAYS coloured or shaded, on ticked and
           unticked rows alike. Its colour and fill mean nothing.
           A row counts only when a human added ink on top of it - a pen tick (V, /, check), a cross (X),
           or a circle drawn round the name - in a visibly different colour from the printing, usually
           blue or black ballpoint. Compare the rows against each other: the ticked ones will look
           clearly different from their neighbours. If a row looks identical to the untouched printed
           rows below it, it is NOT ticked.
           Also do NOT count:
           - a dash, hyphen or short line next to a name,
           - a single long diagonal stroke drawn across a whole column (that means "not applicable"),
           - anything struck through.
           Be conservative: when you cannot see ink on a row, leave it out. A blank block (a future
           visit not yet filled in) produces no entry at all.

        3. MAP TO THE ALLOWED NAMES. "vaccines" accepts only these seven values:
           parvovirus, hepatitis, distemper, leptospira, rabies, parainfluenza, bordetella.
           Translate whatever the book says:
           - Parvo, Parvovirus, Parvovirosis, "P" in a combo -> parvovirus
           - Hepatitis, Hepatitis CAV-2, CAV-2, CAV2, Adenovirus, Adenovirus type 2, "H" or "A2" in a
             combo -> hepatitis
           - Distemper, Distemper Carre, Carre, Canine Distemper, "D" or "C" in a combo -> distemper
           - Leptospirosis, Leptospirosis 2/4, Lepto, L, L4, Leptospira -> leptospira
           - Rabies, Rabive, Rabisin, Defensor, Nobivac Rabies, "R" -> rabies
           - Parainfluenza, Para influenza, Pi, PI2 -> parainfluenza
           - Bordetella, Bordetella bronchiseptica, Kennel Cough, KC, Bronchi-Shield -> bordetella
           Ignore any dog vaccine outside that list, such as Coronavirus / Corona, Giardia, Lyme,
           deworming ("obat cacing"), and vitamins.

        4. THE CHECKLIST WINS. If a block has any ticked disease at all, the ticked diseases are the
           complete answer for that block. A product label or sticker beside it only confirms them - it
           must never add a disease whose box was left unticked. Example: three ticks on Distemper,
           Parvo and Hepatitis next to a "Nobivac DHP" sticker means exactly distemper, hepatitis,
           parvovirus - not leptospira, not parainfluenza.

        5. EXPAND COMBINATION VACCINES only for a block that has a product label but NO ticked diseases
           at all. Then read the product name:
           - DHPPi, DHPP, DAPP, DA2PP, CHPPi, Eurican DHPPi2, Vanguard Plus 5, Duramune Max 5
             -> distemper, hepatitis, parvovirus, parainfluenza
           - DHPPi-L, DHPPi2-L, DHLPP, DA2PPL, Vanguard Plus 5 L4, Eurican DHPPi2-L, a "+L" or a
             separate "L" vial -> the four above plus leptospira
           - DHP, Nobivac DHP, Nobivac DHPPi -> distemper, hepatitis, parvovirus (add parainfluenza
             only when the label actually shows Pi)
           - DP, Nobivac Puppy DP -> distemper, parvovirus
           - Rabisin, Nobivac Rabies, Defensor 3 -> rabies
           - Nobivac KC, Bronchi-Shield -> bordetella, parainfluenza
           Never let a sticker printed on a future/blank block leak into an earlier block.

        6. DATES. "date_given" is the date the shot was given ("DATE GIVEN", "Tanggal diberikan").
           "next_visit_date" is the recall date ("DATE DUE", "Kunjungan berikutnya", "next: ...").
           Return both strictly as "YYYY-MM-DD".
           - Handwritten dates are day-first: 26/05/20 is 2020-05-26, 12/06/20 is 2020-06-12.
           - A two-digit year 00-79 means 20xx.
           - If the year is written on its own line under the day/month (e.g. "6/9" above "2025"),
             combine them: 2025-09-06.
           - If a date is missing, unreadable or ambiguous, use null. Never invent one.
           - Do NOT take the date from a vaccine vial's expiry ("Exp.", "Exp/Valid", "Batch/Lot") or
             from the vet's licence number.

        7. Do not merge two blocks that have different dates, and do not split one block into several
           entries. Order the visits top to bottom as they appear on the page.

        8. WORK ROW BY ROW. Fill "ink_marks_seen" FIRST, before deciding "vaccines". In it, walk the
           block's dog column from top to bottom and name every printed row with a verdict, like:
           "Distemper=ink tick; Parvo=ink tick; Leptospirosis=printed box only; Parainfluenza=printed
           box only; Hepatitis=ink tick; Bordetella=printed box only; Rabies=printed box only".
           List every row, including the ones with no ink. Then "vaccines" must contain exactly the
           rows you called "ink tick" - no more.

        Return only the JSON.
        """

    private static var responseSchema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "visits": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "ink_marks_seen": ["type": "STRING"],
                            "date_given": ["type": "STRING", "nullable": true],
                            "next_visit_date": ["type": "STRING", "nullable": true],
                            "vaccines": [
                                "type": "ARRAY",
                                "items": ["type": "STRING", "enum": VaccineType.allCases.map(\.rawValue)]
                            ]
                        ],
                        "required": ["ink_marks_seen", "vaccines"],
                        // Ordering matters: the model fills the fields in this order, so the
                        // row-by-row pass happens before it commits to a vaccine list.
                        "propertyOrdering": ["ink_marks_seen", "date_given", "next_visit_date", "vaccines"]
                    ]
                ]
            ],
            "required": ["visits"]
        ]
    }

    /// Returns every dog vaccination visit legible on the page, top to bottom.
    static func scan(_ image: UIImage) async throws -> [ScannedVisit] {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String,
            !key.isEmpty
        else { throw ScanError.missingKey }

        let jpeg = try await encodeForUpload(image)

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inline_data": ["mime_type": "image/jpeg", "data": jpeg.base64EncodedString()]],
                    ["text": prompt]
                ]
            ]],
            "generationConfig": [
                // Reading handwriting should not be a dice roll.
                "temperature": 0,
                "responseMimeType": "application/json",
                "responseSchema": responseSchema
            ]
        ]

        var request = URLRequest(
            url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await send(request)
        return try decodeVisits(from: data)
    }

    /// Gemini goes 503 under load often enough that a one-shot scan looks broken,
    /// so overload is retried with a short backoff. Quota and auth failures are
    /// not retried — they will not clear within a couple of seconds.
    private static func send(_ request: URLRequest, attempts: Int = 3) async throws -> Data {
        var lastError = ScanError.serviceUnavailable

        for attempt in 1...attempts {
            let data: Data
            let response: URLResponse

            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch let error as URLError {
                logger.error("Gemini request failed: \(error.localizedDescription, privacy: .public)")
                throw ScanError.offline
            }

            guard let http = response as? HTTPURLResponse else { return data }
            if http.statusCode == 200 { return data }

            lastError = scanError(forStatus: http.statusCode, body: data)
            guard lastError.isTransient, attempt < attempts else { throw lastError }
            try await Task.sleep(for: .seconds(attempt))
        }

        throw lastError
    }

    /// Maps Gemini's HTTP failures onto something worth showing a user. The raw
    /// body is logged rather than surfaced, so it stays available for debugging.
    static func scanError(forStatus status: Int, body: Data) -> ScanError {
        let message = String(data: body, encoding: .utf8) ?? "no body"
        logger.error("Gemini returned HTTP \(status, privacy: .public): \(message)")

        switch status {
        case 429:
            return .quotaExceeded
        case 401, 403:
            return .notAuthorized
        // A 400 is usually a malformed request, but Gemini also uses it to reject
        // a bad key, and those two want very different messages.
        case 400 where message.localizedStandardContains("api key"):
            return .notAuthorized
        case 500...599:
            return .serviceUnavailable
        default:
            return .unreadableResponse
        }
    }

    /// Split out from `scan` so the response shape can be tested without the network.
    static func decodeVisits(from data: Data) throws -> [ScannedVisit] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.compactMap({ $0["text"] as? String }).last,
            let textData = text.data(using: .utf8)
        else {
            logger.error("Unrecognised Gemini envelope: \(String(data: data, encoding: .utf8) ?? "")")
            throw ScanError.unreadableResponse
        }

        struct Payload: Decodable {
            var visits: [ScannedVisit]
        }

        do {
            // A block with nothing ticked is a blank future visit, not a record.
            let visits = try JSONDecoder().decode(Payload.self, from: textData)
                .visits
                .filter { !$0.vaccines.isEmpty }
            guard !visits.isEmpty else { throw ScanError.noVaccinationsFound }
            return visits
        } catch let error as DecodingError {
            logger.error("Could not decode Gemini payload: \(String(describing: error), privacy: .public)")
            throw ScanError.unreadableResponse
        }
    }

    /// Resizes and JPEG-encodes the photo away from the main actor.
    ///
    /// The project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so
    /// this type is main-actor isolated and all of this ran on the main thread —
    /// a full redraw plus a JPEG encode of a 12MP camera image, right as the
    /// scanning spinner appeared. `nonisolated async` puts it on the cooperative
    /// pool instead.
    private nonisolated static func encodeForUpload(_ image: UIImage) async throws -> Data {
        guard let jpeg = downscale(image).jpegData(compressionQuality: 0.75) else {
            throw ScanError.badImage
        }
        return jpeg
    }

    // Cap the longest side to keep upload size and token cost down.
    private nonisolated static func downscale(_ image: UIImage, maxDimension: CGFloat = 1568) -> UIImage {
        let largest = max(image.size.width, image.size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

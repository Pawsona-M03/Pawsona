//
//  GeminiScanner.swift
//  Pawsona
//
//  Created by Aloysia Jennifer on 20/07/26.
//
//  Sends the vaccine book photo straight to Gemini (multimodal, so no OCR
//  step) and asks for JSON constrained by a response schema.
//

import UIKit

struct VaccineVisit: Codable, Equatable {
    var vaccinationDateGiven: String?
    var nextVisitDate: String?
    var vaccinesAdministered: [String]

    enum CodingKeys: String, CodingKey {
        case vaccinationDateGiven = "vaccination_date_given"
        case nextVisitDate = "next_visit_date"
        case vaccinesAdministered = "vaccines_administered"
    }
}

struct GeminiScanner {
    static let model = "gemini-3.5-flash"

    struct ScanResult {
        var rawResponse: String
        var visit: VaccineVisit
    }

    enum ScanError: LocalizedError {
        case missingKey
        case badImage
        case apiError(String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingKey: "No Gemini API key. Fill in Secrets.swift (see Secrets.swift.example)."
            case .badImage: "Could not read the selected image."
            case .apiError(let message): "Gemini API error: \(message)"
            case .emptyResponse: "Gemini returned an empty response."
            }
        }
    }

    private static let prompt = """
        In this photo of my dog's vaccine book: which vaccines was my dog given, and on \
        what date? Keep dates exactly as written; use null for anything \
        not visible.

        Respond with ONLY valid JSON, no extra text, in this exact schema:

        {
          "vaccination_date_given": "<string as written, or null>",
          "next_visit_date": "<string as written, or null>",
          "vaccines_administered": ["<vaccine name>", "..."],
        }
        """

    private static let responseSchema: [String: Any] = [
        "type": "OBJECT",
        "properties": [
            "vaccination_date_given": ["type": "STRING", "nullable": true],
            "next_visit_date": ["type": "STRING", "nullable": true],
            "vaccines_administered": ["type": "ARRAY", "items": ["type": "STRING"]],
        ],
        "required": ["vaccines_administered"],
    ]

    static func scan(_ image: UIImage) async throws -> ScanResult {
        let key = Secrets.geminiAPIKey
        guard !key.isEmpty, !key.contains("YOUR_API_KEY") else { throw ScanError.missingKey }
        guard let jpeg = downscale(image).jpegData(compressionQuality: 0.75) else {
            throw ScanError.badImage
        }

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inline_data": ["mime_type": "image/jpeg", "data": jpeg.base64EncodedString()]],
                    ["text": prompt],
                ],
            ]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": responseSchema,
            ],
        ]

        var request = URLRequest(
            url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ScanError.apiError(message)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.compactMap({ $0["text"] as? String }).first,
            let textData = text.data(using: .utf8)
        else { throw ScanError.emptyResponse }

        let visit = try JSONDecoder().decode(VaccineVisit.self, from: textData)
        return ScanResult(rawResponse: text, visit: visit)
    }

    // Cap the longest side to keep upload size and token cost down.
    private static func downscale(_ image: UIImage, maxDimension: CGFloat = 1568) -> UIImage {
        let largest = max(image.size.width, image.size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

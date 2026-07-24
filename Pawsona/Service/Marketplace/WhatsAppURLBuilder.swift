import Foundation

enum WhatsAppURLBuilder {
    static func url(number: String, puppyName: String) throws -> URL {
        let digits = try MarketplacePhoneNumber.digitsOnly(number)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wa.me"
        components.path = "/\(digits)"
        components.queryItems = [
            URLQueryItem(
                name: "text",
                value: "Hi, I found \(puppyName)’s listing on Pawsona. Is \(puppyName) still available?"
            )
        ]

        guard let url = components.url else {
            throw MarketplaceError.unsupportedContactMethod
        }
        return url
    }

    static func phoneURL(number: String) throws -> URL {
        let digits = try MarketplacePhoneNumber.digitsOnly(number)
        guard let url = URL(string: "tel:+\(digits)") else {
            throw MarketplaceError.unsupportedContactMethod
        }
        return url
    }
}

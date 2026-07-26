import Foundation

enum MarketplaceCloudKitSchema {
    enum RecordType {
        static let listing = "MarketplaceListing"
        static let sellerProfile = "SellerProfile"
        static let sellerContact = "SellerContact"
        static let report = "MarketplaceReport"
    }

    enum ListingField {
        static let sourceDogID = "sourceDogID"
        static let sellerProfile = "sellerProfile"
        static let name = "name"
        static let breed = "breed"
        static let dateOfBirth = "dateOfBirth"
        static let sex = "sex"
        static let weight = "weight"
        static let backgroundColor = "backgroundColor"
        static let photo = "photo"
        static let vaccinationNames = "vaccinationNames"
        static let vaccinationRecordCount = "vaccinationRecordCount"
        static let listingType = "listingType"
        static let priceAmount = "priceAmount"
        static let currencyCode = "currencyCode"
        static let region = "region"
        static let status = "status"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    enum SellerProfileField {
        static let displayName = "displayName"
        static let region = "region"
        static let sellerType = "sellerType"
        static let joinedAt = "joinedAt"
        static let profileComplete = "profileComplete"
        static let rulesAcceptedAt = "rulesAcceptedAt"
    }

    enum SellerContactField {
        static let sellerProfile = "sellerProfile"
        static let whatsAppNumber = "whatsAppNumber"
        static let preferredMethod = "preferredMethod"
        static let updatedAt = "updatedAt"
    }

    enum ReportField {
        static let listing = "listing"
        static let reportedSeller = "reportedSeller"
        static let reason = "reason"
        static let details = "details"
        static let createdAt = "createdAt"
        static let status = "status"
    }
}

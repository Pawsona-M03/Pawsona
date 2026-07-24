import Foundation

struct SellerContact: Equatable, Hashable {
    var sellerProfileID: String
    var whatsAppNumber: String
    var preferredMethod: PreferredContactMethod
}

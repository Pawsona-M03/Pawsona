import Foundation

protocol SellerBlocking {
    var blockedSellerIDs: Set<String> { get }
    func isBlocked(_ sellerID: String) -> Bool
    func block(_ sellerID: String)
    func unblock(_ sellerID: String)
}

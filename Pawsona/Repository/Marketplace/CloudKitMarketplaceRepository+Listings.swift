import CloudKit
import Foundation

// MARK: - Listings

extension CloudKitMarketplaceRepository {
    func fetchListings(
        query: MarketplaceListingQuery,
        after token: MarketplacePageToken?
    ) async throws -> MarketplacePage {
        let response = try await withRetry {
            if let token {
                guard let cursor = self.cursors[token.rawValue] else {
                    throw MarketplaceError.notFound
                }
                return try await self.database.records(
                    continuingMatchFrom: cursor,
                    desiredKeys: nil,
                    resultsLimit: self.pageSize
                )
            }

            let cloudQuery = CKQuery(
                recordType: MarketplaceCloudKitSchema.RecordType.listing,
                predicate: self.predicate(for: query)
            )
            cloudQuery.sortDescriptors = self.sortDescriptors(for: query.sort)
            return try await self.database.records(
                matching: cloudQuery,
                desiredKeys: nil,
                resultsLimit: self.pageSize
            )
        }

        let listings = try response.matchResults.compactMap { _, result in
            let record = try record(from: result)
            return try MarketplaceCloudKitMapper.listing(from: record)
        }

        let nextToken = response.queryCursor.map { cursor in
            let token = MarketplacePageToken(rawValue: UUID().uuidString)
            cursors[token.rawValue] = cursor
            return token
        }

        return MarketplacePage(
            listings: query.sorted(listings.filter(query.matches)),
            nextToken: nextToken
        )
    }

    func fetchListing(id: String) async throws -> MarketplaceListing {
        let record = try await record(id: id)
        return try MarketplaceCloudKitMapper.listing(from: record)
    }

    func fetchListing(sourceDogID: String) async throws -> MarketplaceListing? {
        let userRecordID = try await authenticatedUserRecordID()
        let cloudQuery = CKQuery(
            recordType: MarketplaceCloudKitSchema.RecordType.listing,
            predicate: NSPredicate(
                format: "%K == %@",
                MarketplaceCloudKitSchema.ListingField.sourceDogID,
                sourceDogID
            )
        )
        let response = try await withRetry {
            try await self.database.records(
                matching: cloudQuery,
                desiredKeys: nil,
                resultsLimit: 100
            )
        }
        for (_, result) in response.matchResults {
            let record = try record(from: result)
            if record.creatorUserRecordID == userRecordID {
                return try MarketplaceCloudKitMapper.listing(from: record)
            }
        }
        return nil
    }

    func publish(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        let validatedListing = try listing.validated()
        let currentProfile = try await fetchCurrentSellerProfile()
        guard let currentProfile,
              currentProfile.profileComplete,
              currentProfile.id == validatedListing.sellerProfileID else {
            throw MarketplaceError.incompleteSellerProfile
        }

        let record = CKRecord(
            recordType: MarketplaceCloudKitSchema.RecordType.listing,
            recordID: CKRecord.ID(recordName: validatedListing.id)
        )
        MarketplaceCloudKitMapper.apply(validatedListing, to: record)
        let saved = try await save(record, photoData: validatedListing.photoData)
        return try MarketplaceCloudKitMapper
            .listing(from: saved)
            .withPhotoData(validatedListing.photoData)
    }

    func updateListingFromDog(_ listing: MarketplaceListing) async throws -> MarketplaceListing {
        _ = try listing.validated()
        let record = try await ownedRecord(id: listing.id)
        let existing = try MarketplaceCloudKitMapper.listing(from: record)
        guard existing.sourceDogID == listing.sourceDogID else {
            throw MarketplaceError.notAuthorized
        }

        var updated = existing
        updated.name = listing.name
        updated.breed = listing.breed
        updated.dateOfBirth = listing.dateOfBirth
        updated.sex = listing.sex
        updated.weight = listing.weight
        updated.backgroundColor = listing.backgroundColor
        updated.photoData = listing.photoData
        updated.vaccinationSummary = listing.vaccinationSummary
        updated.updatedAt = .now

        MarketplaceCloudKitMapper.apply(updated, to: record)
        let saved = try await save(record, photoData: updated.photoData)
        return try MarketplaceCloudKitMapper
            .listing(from: saved)
            .withPhotoData(updated.photoData)
    }

    func updateListingStatus(id: String, status: MarketplaceListingStatus) async throws {
        let record = try await ownedRecord(id: id)
        record[MarketplaceCloudKitSchema.ListingField.status] = status.rawValue
        record[MarketplaceCloudKitSchema.ListingField.updatedAt] = Date.now
        _ = try await withRetry {
            try await self.database.save(record)
        }
    }

    func deleteListing(id: String) async throws {
        let record = try await ownedRecord(id: id)
        _ = try await withRetry {
            try await self.database.deleteRecord(withID: record.recordID)
        }
    }

    func isListingOwnedByCurrentUser(id: String) async throws -> Bool {
        let userRecordID = try await authenticatedUserRecordID()
        let record = try await record(id: id)
        return record.creatorUserRecordID == userRecordID
    }

    private func predicate(for query: MarketplaceListingQuery) -> NSPredicate {
        var predicates = [
            NSPredicate(
                format: "%K == %@",
                MarketplaceCloudKitSchema.ListingField.status,
                MarketplaceListingStatus.available.rawValue
            )
        ]

        if query.listingTypes.count == 1, let listingType = query.listingTypes.first {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.listingType,
                    listingType.rawValue
                )
            )
        }
        if let breed = query.breed, !breed.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.breed,
                    breed
                )
            )
        }
        if let sex = query.sex {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.sex,
                    sex.rawValue
                )
            )
        }
        if let region = query.region, !region.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    MarketplaceCloudKitSchema.ListingField.region,
                    region
                )
            )
        }
        if let minimumPrice = query.minimumPrice {
            predicates.append(
                NSPredicate(
                    format: "%K >= %lld",
                    MarketplaceCloudKitSchema.ListingField.priceAmount,
                    minimumPrice
                )
            )
        }
        if let maximumPrice = query.maximumPrice {
            predicates.append(
                NSPredicate(
                    format: "%K <= %lld",
                    MarketplaceCloudKitSchema.ListingField.priceAmount,
                    maximumPrice
                )
            )
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func sortDescriptors(for sort: MarketplaceSortOption) -> [NSSortDescriptor] {
        switch sort {
        case .newest:
            [
                NSSortDescriptor(
                    key: MarketplaceCloudKitSchema.ListingField.createdAt,
                    ascending: false
                )
            ]
        case .priceLowToHigh:
            [
                NSSortDescriptor(
                    key: MarketplaceCloudKitSchema.ListingField.priceAmount,
                    ascending: true
                )
            ]
        case .priceHighToLow:
            [
                NSSortDescriptor(
                    key: MarketplaceCloudKitSchema.ListingField.priceAmount,
                    ascending: false
                )
            ]
        }
    }
}

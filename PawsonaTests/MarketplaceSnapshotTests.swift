import Foundation
import Testing
@testable import Pawsona

@Suite("Marketplace puppy snapshot")
@MainActor
struct MarketplaceSnapshotTests {
    @Test("Mapping transforms the internal dog id and publishes only a vaccine summary")
    func privacySafeMapping() throws {
        let dogID = try #require(UUID(uuidString: "12345678-1234-1234-1234-123456789012"))
        let dog = Dog(
            id: dogID,
            name: "Berry",
            breed: "Labrador",
            backgroundColor: .green,
            photoData: Data("processed-photo".utf8)
        )
        let privateReminder = Reminder(title: "Private medicine note", dogList: [dog])
        dog.reminders = [privateReminder]
        dog.vaccineRecords = [
            VaccineRecord(
                vaccines: [.rabies, .parvovirus],
                notes: "Private vaccine document details",
                dogList: [dog]
            )
        ]

        let snapshot = MarketplaceDogSnapshotMapper.snapshot(from: dog)

        #expect(snapshot.sourceDogID != dog.id.uuidString)
        #expect(!snapshot.sourceDogID.contains(dog.id.uuidString.lowercased()))
        #expect(snapshot.name == "Berry")
        #expect(snapshot.vaccinationSummary.vaccineNames == ["Parvovirus", "Rabies"])
        #expect(snapshot.vaccinationSummary.recordCount == 1)

        let fieldNames = Set(Mirror(reflecting: snapshot).children.compactMap(\.label))
        #expect(!fieldNames.contains("reminders"))
        #expect(!fieldNames.contains("notes"))
        #expect(!fieldNames.contains("vaccineRecords"))
        #expect(!fieldNames.contains("exactAddress"))
        #expect(!fieldNames.contains("scanSourceImage"))
    }
}

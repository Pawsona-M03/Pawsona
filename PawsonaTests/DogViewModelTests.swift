//
//  DogViewModelTests.swift
//  PawsonaTests
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("DogViewModel")
@MainActor
struct DogViewModelTests {
    // MARK: - Creating

    @Test("A draft's fields all reach the saved dog")
    func createPersistsEveryField() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let birthday = Date(timeIntervalSince1970: 1_600_000_000)

        let draft = DogDraft(
            name: "Berry",
            breed: "Labrador Retriever",
            dateOfBirth: birthday,
            backgroundColor: .green,
            weightKg: 12.5,
            sex: .female
        )
        viewModel.createDog(from: draft, in: context)

        let dogs = try context.fetch(FetchDescriptor<Dog>())
        let dog = try #require(dogs.first)
        #expect(dogs.count == 1)
        #expect(dog.name == "Berry")
        #expect(dog.breed == "Labrador Retriever")
        #expect(dog.backgroundColor == .green)
        #expect(dog.dateOfBirth == birthday)
        #expect(dog.weight == 12.5)
        #expect(dog.sex == .female)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("An unnamed dog is numbered rather than left blank")
    func blankNameIsGenerated() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()

        let dog = viewModel.createDog(from: DogDraft(name: "   ", breed: "Poodle"), in: context)

        #expect(dog.name == "Puppy 1")
    }

    @Test("Generated names skip the numbers already taken")
    func generatedNamesDoNotCollide() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()

        let first = viewModel.createDog(from: DogDraft(name: "", breed: "Poodle"), in: context)
        let second = viewModel.createDog(from: DogDraft(name: "", breed: "Beagle"), in: context)
        let third = viewModel.createDog(from: DogDraft(name: "", breed: "Corgi"), in: context)

        #expect(first.name == "Puppy 1")
        #expect(second.name == "Puppy 2")
        #expect(third.name == "Puppy 3")
    }

    @Test("A generated name ignores a taken name's casing and padding")
    func generatedNameMatchIsForgiving() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        context.insert(Dog(name: "  PUPPY 1 ", breed: "Poodle"))

        let dog = viewModel.createDog(from: DogDraft(name: "", breed: "Beagle"), in: context)

        #expect(dog.name == "Puppy 2")
    }

    // MARK: - Editing

    @Test("Editing writes the draft over the existing dog")
    func editUpdatesFields() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let dog = viewModel.createDog(
            from: DogDraft(name: "Berry", breed: "Labrador", weightKg: 12.5),
            in: context
        )

        viewModel.editDog(
            dog,
            from: DogDraft(name: "Berry", breed: "Golden Retriever", weightKg: 14),
            in: context
        )

        #expect(dog.breed == "Golden Retriever")
        #expect(dog.weight == 14)
    }

    /// The bug this whole audit opened on: an edit that touches only the name
    /// must not take the weight with it.
    @Test("Editing the name alone leaves the weight intact")
    func editingNameKeepsWeight() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let dog = viewModel.createDog(
            from: DogDraft(name: "Berry", breed: "Labrador", weightKg: 12.5),
            in: context
        )

        // Exactly what DogEditView builds: the weight goes out to the field as
        // text and comes back through the parser.
        let shownWeight = DogDraft.weightText(for: dog.weight)
        let editedDraft = DogDraft(
            name: "Berry Junior",
            breed: dog.breed,
            weightKg: DogDraft.weightKg(fromText: shownWeight)
        )
        viewModel.editDog(dog, from: editedDraft, in: context)

        #expect(dog.name == "Berry Junior")
        #expect(dog.weight == 12.5)
    }

    @Test("Clearing a dog's name renumbers it without colliding with itself")
    func editingToBlankNameSkipsSelf() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let dog = viewModel.createDog(from: DogDraft(name: "", breed: "Poodle"), in: context)
        #expect(dog.name == "Puppy 1")

        viewModel.editDog(dog, from: DogDraft(name: "", breed: "Poodle"), in: context)

        // Its own "Puppy 1" is excluded, so it keeps the number rather than
        // stepping to "Puppy 2" every time it is saved.
        #expect(dog.name == "Puppy 1")
    }

    // MARK: - Deleting

    @Test("Deleting removes the dog from the store")
    func deleteRemovesDog() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let dog = viewModel.createDog(from: DogDraft(name: "Berry", breed: "Labrador"), in: context)

        viewModel.deleteDog(dog, in: context)

        #expect(try context.fetch(FetchDescriptor<Dog>()).isEmpty)
    }

    // MARK: - Duplicating

    @Test("Duplicating copies the profile and appends Copy to the name")
    func duplicateCopiesProfile() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let birthday = Date(timeIntervalSince1970: 1_600_000_000)
        let original = viewModel.createDog(
            from: DogDraft(
                name: "Berry",
                breed: "Labrador",
                dateOfBirth: birthday,
                backgroundColor: .green,
                weightKg: 12.5,
                sex: .female
            ),
            in: context
        )

        let copy = viewModel.duplicateDog(original, in: context)

        #expect(copy.name == "Berry Copy")
        #expect(copy.breed == "Labrador")
        #expect(copy.backgroundColor == .green)
        #expect(copy.dateOfBirth == birthday)
        #expect(copy.weight == 12.5)
        #expect(copy.sex == .female)
        #expect(copy.id != original.id)
        #expect(try context.fetch(FetchDescriptor<Dog>()).count == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Duplicating does not clone vaccine records")
    func duplicateDropsHealthHistory() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let original = viewModel.createDog(from: DogDraft(name: "Berry", breed: "Labrador"), in: context)
        original.vaccineRecords = [VaccineRecord(vaccines: [.rabies], dateGiven: .now, dogList: [original])]

        let copy = viewModel.duplicateDog(original, in: context)

        #expect((copy.vaccineRecords ?? []).isEmpty)
    }

    // MARK: - Sharing and import

    @Test("A shared dog round-trips back through import")
    func shareAndImportRoundTrip() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let dog = viewModel.createDog(
            from: DogDraft(name: "Berry", breed: "Labrador", backgroundColor: .green, weightKg: 12.5, sex: .female),
            in: context
        )
        dog.vaccineRecords = [VaccineRecord(vaccines: [.rabies], dateGiven: .now, dogList: [dog])]

        let fileURL = try #require(viewModel.shareDogData(dog))
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let freshContext = try TestSupport.makeContext()
        let imported = try #require(viewModel.importDogData(from: fileURL, in: freshContext))

        #expect(imported.name == "Berry")
        #expect(imported.breed == "Labrador")
        #expect(imported.weight == 12.5)
        #expect(imported.sex == .female)
        #expect(imported.backgroundColor == .green)
        #expect(imported.vaccineRecords?.first?.vaccines == [.rabies])
    }

    @Test("Importing keeps a file the user owns rather than deleting it")
    func importDoesNotDeleteUserFiles() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()
        let dog = viewModel.createDog(from: DogDraft(name: "Berry", breed: "Labrador"), in: context)

        // Stand in for a file opened from Files or iCloud Drive: somewhere that
        // is not the throwaway Inbox copy iOS hands us for AirDrop.
        let userDirectory = URL.documentsDirectory.appending(path: "ImportTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: userDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: userDirectory) }

        let exported = try #require(viewModel.shareDogData(dog))
        let userFile = userDirectory.appending(path: "Berry.pawsonadog")
        try FileManager.default.moveItem(at: exported, to: userFile)

        let freshContext = try TestSupport.makeContext()
        _ = viewModel.importDogData(from: userFile, in: freshContext)

        #expect(
            FileManager.default.fileExists(atPath: userFile.path),
            "importing must not destroy a file the user opened from their own storage"
        )
    }

    @Test("A file that isn't ours reports a readable error instead of throwing")
    func importRejectsGarbage() throws {
        let context = try TestSupport.makeContext()
        let viewModel = DogViewModel()

        let junkURL = URL.temporaryDirectory.appending(path: "junk-\(UUID().uuidString).pawsonadog")
        try Data("not a dog".utf8).write(to: junkURL)
        defer { try? FileManager.default.removeItem(at: junkURL) }

        let imported = viewModel.importDogData(from: junkURL, in: context)

        #expect(imported == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(try context.fetch(FetchDescriptor<Dog>()).isEmpty)
    }

    @Test("An error is showing exactly while there is a message")
    func errorPresentationTracksMessage() {
        let viewModel = DogViewModel()
        #expect(viewModel.isShowingError == false)

        viewModel.errorMessage = "Something went wrong"
        #expect(viewModel.isShowingError)

        viewModel.isShowingError = false
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Display helpers

    @Test("A blank or whitespace-only name falls back to Puppy")
    func displayNameFallsBack() {
        #expect(Dog(name: nil, breed: "Poodle").displayName == "Puppy")
        #expect(Dog(name: "   ", breed: "Poodle").displayName == "Puppy")
        #expect(Dog(name: "  Berry  ", breed: "Poodle").displayName == "Berry")
    }

    @Test("A missing breed reads as not set")
    func breedTextFallsBack() {
        #expect(Dog(name: "Berry", breed: "").breedText == "Breed not set")
        #expect(Dog(name: "Berry", breed: "Poodle").breedText == "Poodle")
    }

    @Test("Age text reads as the largest unit that is not zero")
    func ageTextReadsNaturally() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 22)))
        let oneDayAgo = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21)))
        let twoMonthsAgo = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 22)))
        let fullAge = try #require(calendar.date(from: DateComponents(year: 2025, month: 5, day: 19)))
        let oneYearAgo = try #require(calendar.date(from: DateComponents(year: 2025, month: 7, day: 22)))
        let newborn = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 22)))

        #expect(Dog.ageText(from: oneDayAgo, to: now, calendar: calendar) == "1 day old")
        #expect(Dog.ageText(from: twoMonthsAgo, to: now, calendar: calendar) == "2 months old")
        // 1 year 2 months 3 days: the months and days drop off, they do not
        // trail the year. Left stale by #79, which changed the phrasing.
        #expect(Dog.ageText(from: fullAge, to: now, calendar: calendar) == "1 year old")
        #expect(Dog.ageText(from: oneYearAgo, to: now, calendar: calendar) == "1 year old")
        #expect(Dog.ageText(from: newborn, to: now, calendar: calendar) == "0 days old")
        #expect(Dog.ageText(from: nil, to: now, calendar: calendar) == nil)
    }
}

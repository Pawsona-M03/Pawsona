//
//  DogViewModel.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import Observation
import SwiftData
import PDFKit

@Observable
final class DogViewModel {
    var dogs: [Dog] = []
    var errorMessage: String?

    func createDog(
        name: String,
        breed: String,
        dateOfBirth: Date,
        backgroundColor: ColorType,
        photoData: Data? = nil,
        in modelContext: ModelContext
    ) {
        let dog = Dog(
            name: resolvedDogName(from: name, in: modelContext),
            breed: breed,
            backgroundColor: backgroundColor,
            dateOfBirth: dateOfBirth,
            photoData: photoData
        )

        modelContext.insert(dog)
        saveChanges(in: modelContext)
        getDogLists(in: modelContext)
    }

    func getDogLists(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Dog>(
            sortBy: [SortDescriptor(\Dog.name)]
        )

        do {
            dogs = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func getDog(id: UUID, in modelContext: ModelContext) -> Dog? {
        let descriptor = FetchDescriptor<Dog>(
            predicate: #Predicate { dog in
                dog.id == id
            }
        )

        do {
            errorMessage = nil
            return try modelContext.fetch(descriptor).first
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func editDog(
        _ dog: Dog,
        name: String,
        breed: String,
        dateOfBirth: Date,
        backgroundColor: ColorType,
        photoData: Data? = nil,
        in modelContext: ModelContext
    ) {
        dog.name = resolvedDogName(from: name, excluding: dog.id, in: modelContext)
        dog.breed = breed
        dog.dateOfBirth = dateOfBirth
        dog.backgroundColor = backgroundColor
        dog.photoData = photoData

        saveChanges(in: modelContext)
        getDogLists(in: modelContext)
    }

    func deleteDog(id: UUID, in modelContext: ModelContext) {
        guard let dog = getDog(id: id, in: modelContext) else {
            return
        }

        modelContext.delete(dog)
        saveChanges(in: modelContext)
        getDogLists(in: modelContext)
    }
    
    @discardableResult
    func exportDogsToPDF() -> URL? {
        guard let pdfData = PDFGenerator.generate(from: dogs), PDFDocument(data: pdfData) != nil else {
            errorMessage = "Unable to generate PDF."
            return nil
        }

        let fileURL = URL.temporaryDirectory.appending(path: "Pawsona-Dogs.pdf")

        do {
            try pdfData.write(to: fileURL)
            errorMessage = nil
            return fileURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    @discardableResult
    func exportDogToPDF(_ dog: Dog) -> URL? {
        guard let pdfData = PDFGenerator.generate(from: [dog]), PDFDocument(data: pdfData) != nil else {
            errorMessage = "Unable to generate PDF."
            return nil
        }

        let fileURL = URL.temporaryDirectory.appending(path: "\(sanitizedFileName(for: dog))-data.pdf")

        do {
            try pdfData.write(to: fileURL)
            errorMessage = nil
            return fileURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func shareDogData(_ dog: Dog) -> URL? {
        do {
            let data = try JSONEncoder().encode(DogTransferPackage(dog: dog))
            let fileURL = URL.temporaryDirectory.appending(path: "\(sanitizedFileName(for: dog)).pawsonadog")

            try data.write(to: fileURL)
            errorMessage = nil
            return fileURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func importDogData(from url: URL, in modelContext: ModelContext) -> Dog? {
        do {
            let data = try Data(contentsOf: url)
            let package = try JSONDecoder().decode(DogTransferPackage.self, from: data)
            let dog = package.makeDog()

            modelContext.insert(dog)
            for vaccineRecord in dog.vaccineRecords ?? [] {
                modelContext.insert(vaccineRecord)
            }

            saveChanges(in: modelContext)
            getDogLists(in: modelContext)
            try? FileManager.default.removeItem(at: url)

            return dog
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func sanitizedFileName(for dog: Dog) -> String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = trimmedName.isEmpty ? "Dog" : trimmedName
        return name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }

    private func resolvedDogName(
        from name: String,
        excluding excludedDogID: UUID? = nil,
        in modelContext: ModelContext
    ) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedName.isEmpty {
            return trimmedName
        }

        return nextGeneratedDogName(excluding: excludedDogID, in: modelContext)
    }

    private func nextGeneratedDogName(excluding excludedDogID: UUID? = nil, in modelContext: ModelContext) -> String {
        let descriptor = FetchDescriptor<Dog>()

        do {
            let existingDogs = try modelContext.fetch(descriptor)
            let existingNames: Set<String> = Set(existingDogs.compactMap { dog in
                guard dog.id != excludedDogID else {
                    return nil
                }

                return dog.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            })

            var number = 1
            while existingNames.contains("puppy \(number)") {
                number += 1
            }

            return "Puppy \(number)"
        } catch {
            errorMessage = error.localizedDescription
            return "Puppy 1"
        }
    }

    private func saveChanges(in modelContext: ModelContext) {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

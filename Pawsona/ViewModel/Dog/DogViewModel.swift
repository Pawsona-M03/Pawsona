//
//  DogViewModel.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import Foundation
import Observation
import PDFKit
import SwiftData

/// Writes and exports for dogs. Reading is `@Query`'s job — this deliberately
/// keeps no dog array of its own, so there is one source of truth and no manual
/// cache to go stale when CloudKit syncs a change in from another device.
@Observable
final class DogViewModel {
    var errorMessage: String?

    /// Largest `.pawsonadog` we will even try to decode. A package is a little
    /// JSON plus base64 photos, so anything past this is not one of ours and
    /// reading it would only risk a memory-pressure kill.
    private static let maximumImportBytes = 50 * 1_024 * 1_024

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Writes

    @discardableResult
    func createDog(from draft: DogDraft, in modelContext: ModelContext) -> Dog {
        let dog = Dog(
            name: resolvedDogName(from: draft.name, in: modelContext),
            breed: draft.breed,
            backgroundColor: draft.backgroundColor,
            dateOfBirth: draft.dateOfBirth,
            weight: draft.weightKg,
            sex: draft.sex,
            photoData: draft.photoData
        )

        modelContext.insert(dog)
        saveChanges(in: modelContext)
        return dog
    }

    func editDog(_ dog: Dog, from draft: DogDraft, in modelContext: ModelContext) {
        dog.name = resolvedDogName(from: draft.name, excluding: dog.id, in: modelContext)
        dog.breed = draft.breed
        dog.dateOfBirth = draft.dateOfBirth
        dog.backgroundColor = draft.backgroundColor
        dog.weight = draft.weightKg
        dog.sex = draft.sex
        dog.photoData = draft.photoData

        saveChanges(in: modelContext)
    }

    func deleteDog(_ dog: Dog, in modelContext: ModelContext) {
        modelContext.delete(dog)
        saveChanges(in: modelContext)
    }

    // MARK: - Exports

    /// Renders the dogs to a PDF on disk. Call this only when the user actually
    /// asks to share: it walks every photo through `ImageRenderer` on the main
    /// actor, which is far too expensive to run speculatively.
    func exportDogsToPDF(_ dogs: [Dog], named fileName: String = "Pawsona-Dogs") -> URL? {
        guard let pdfData = PDFGenerator.generate(from: dogs), PDFDocument(data: pdfData) != nil else {
            errorMessage = "That report couldn't be created. Try again."
            return nil
        }

        return write(pdfData, to: "\(fileName).pdf")
    }

    func exportDogToPDF(_ dog: Dog) -> URL? {
        exportDogsToPDF([dog], named: "\(sanitizedFileName(for: dog))-data")
    }

    /// Packages the dog and its vaccine history for AirDrop.
    func shareDogData(_ dog: Dog) -> URL? {
        do {
            let data = try JSONEncoder().encode(DogTransferPackage(dog: dog))
            return write(data, to: "\(sanitizedFileName(for: dog)).pawsonadog")
        } catch {
            errorMessage = "That dog couldn't be prepared for sharing. Try again."
            return nil
        }
    }

    private func write(_ data: Data, to fileName: String) -> URL? {
        let fileURL = URL.temporaryDirectory.appending(path: fileName)

        do {
            // The file carries a pet's health history and photos, so it gets
            // file protection rather than the temp directory's default.
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            errorMessage = nil
            return fileURL
        } catch {
            errorMessage = "That file couldn't be saved. Check your available storage."
            return nil
        }
    }

    // MARK: - Import

    @discardableResult
    func importDogData(from url: URL, in modelContext: ModelContext) -> Dog? {
        // A file handed over from outside our sandbox — Files, iCloud Drive,
        // another app's share sheet — arrives security-scoped and cannot be
        // read until the scope is claimed. AirDrop's own Inbox copy is already
        // readable, so a false here is not an error.
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer { if hasScopedAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)

            guard data.count <= Self.maximumImportBytes else {
                errorMessage = "That file is too big to be a Pawsona dog."
                return nil
            }

            let package = try JSONDecoder().decode(DogTransferPackage.self, from: data)
            let dog = package.makeDog()

            modelContext.insert(dog)
            for vaccineRecord in dog.vaccineRecords ?? [] {
                modelContext.insert(vaccineRecord)
            }

            saveChanges(in: modelContext)
            discardIfTemporaryCopy(url)

            return dog
        } catch {
            errorMessage = "That file couldn't be read as a Pawsona dog."
            return nil
        }
    }

    /// Deletes only the throwaway copy iOS made for us. Pawsona is registered as
    /// Editor and Owner for `.pawsonadog`, so this same path also receives files
    /// the user opened from Files or iCloud Drive — reading one of those is no
    /// reason to destroy it.
    private func discardIfTemporaryCopy(_ url: URL) {
        let disposableRoots = [
            URL.temporaryDirectory,
            URL.documentsDirectory.appending(path: "Inbox")
        ]
        let filePath = url.resolvingSymlinksInPath().path

        let isDisposable = disposableRoots.contains { root in
            filePath.hasPrefix(root.resolvingSymlinksInPath().path)
        }

        guard isDisposable else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Naming

    private func sanitizedFileName(for dog: Dog) -> String {
        let name = dog.displayName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return name.isEmpty ? "Dog" : name
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
            errorMessage = "Couldn't check existing names, so this puppy was numbered from the start."
            return "Puppy 1"
        }
    }

    private func saveChanges(in modelContext: ModelContext) {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "That change couldn't be saved. Try again."
        }
    }
}

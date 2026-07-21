//
//  VaccineScanViewModel.swift
//  Pawsona
//
//  Drives the camera -> Gemini -> review-sheet flow for scanning a vaccine book.
//

import Foundation
import Observation
import SwiftData
import UIKit

@Observable
final class VaccineScanViewModel {
    var isScanning = false
    var errorMessage: String?
    /// Non-nil once a scan succeeds — presents the review sheet.
    var reviewedVisits: [ScannedVisit]?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var isShowingReview: Bool {
        get { reviewedVisits != nil }
        set { if !newValue { reviewedVisits = nil } }
    }

    /// Surfaces a scan failure the view spotted before any request was made.
    func report(_ error: GeminiScanner.ScanError) {
        errorMessage = error.errorDescription
    }

    func scan(_ image: UIImage) async {
        isScanning = true
        defer { isScanning = false }

        do {
            reviewedVisits = try await GeminiScanner.scan(image)
        } catch let error as GeminiScanner.ScanError {
            errorMessage = error.errorDescription
        } catch {
            // Nothing else should reach here, but an unexpected failure must not
            // leak a raw framework message into the alert.
            errorMessage = GeminiScanner.ScanError.unreadableResponse.errorDescription
        }
    }

    /// Saves one record per visit. Dogs are assigned later — the record card
    /// flags anything still unassigned.
    func saveScannedVisits(
        _ visits: [ScannedVisit],
        using viewModel: VaccineViewModel,
        in modelContext: ModelContext
    ) {
        for visit in visits {
            viewModel.createRecord(
                from: VaccineRecordDraft(
                    vaccines: visit.vaccines,
                    dateGiven: visit.dateGiven ?? .now
                ),
                in: modelContext
            )
        }
    }
}

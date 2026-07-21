//
//  GeminiScanner+ScanError.swift
//  Pawsona
//
//  User-facing failures for vaccine book scanning. Kept apart from the scanner
//  itself so the copy is easy to find and review in one place.
//

import Foundation

extension GeminiScanner {
    /// Everything the scan flow can fail with, phrased for the person holding the
    /// phone. Gemini's own error bodies are long JSON blobs quoting quota metrics
    /// and doc links — those go to the log, never into an alert.
    enum ScanError: LocalizedError, Equatable {
        /// The build has no API key wired up. A developer problem, not a user one.
        case missingKey
        /// The key was rejected, so scanning is misconfigured rather than broken.
        case notAuthorized
        /// No camera to photograph the book with — a simulator, or hardware without one.
        case cameraUnavailable
        case badImage
        case offline
        /// Daily or per-minute request allowance is used up.
        case quotaExceeded
        /// Gemini is overloaded or down; retrying later is the right move.
        case serviceUnavailable
        /// A reply we could not make sense of — treated as a failed read.
        case unreadableResponse
        /// The scan worked, but the page had no ticked dog vaccines on it.
        case noVaccinationsFound

        var errorDescription: String? {
            switch self {
            case .missingKey:
                "Vaccine book scanning isn't set up in this build yet. Add the record manually for now."
            case .notAuthorized:
                """
                Vaccine book scanning isn't set up correctly, so the scan was refused. \
                Add the record manually for now.
                """
            case .cameraUnavailable:
                "This device has no camera, so a vaccine book can't be scanned. Add the record manually instead."
            case .badImage:
                "That photo couldn't be read. Take it again, holding the phone steady over the page."
            case .offline:
                "You're offline. Scanning a vaccine book needs an internet connection."
            case .quotaExceeded:
                "Pawsona has run out of scans for today. Try again tomorrow, or add the record manually."
            case .serviceUnavailable:
                "The scanning service is busy right now. Wait a moment and try again."
            case .unreadableResponse:
                "Something went wrong while reading the page. Try scanning it again."
            case .noVaccinationsFound:
                """
                No vaccinations were found on this page. Make sure the whole page is in frame, \
                the lighting is even, and the ticks are clearly visible — then scan again.
                """
            }
        }

        /// Worth retrying automatically; everything else needs the user to act.
        var isTransient: Bool {
            self == .serviceUnavailable
        }
    }
}

//
//  VaccineInputViewModelTests.swift
//  PawsonaTests
//

import Foundation
import SwiftData
import Testing
@testable import Pawsona

@Suite("VaccineInputViewModel")
struct VaccineInputViewModelTests {

    @Test("Save is disabled when no dogs are selected, even with a vaccine chosen")
    func isSaveEnabled_false_whenNoDogsSelected() throws {
        let context = try TestSupport.makeContext()
        let viewModel = VaccineInputViewModel(context: context)

        viewModel.vaccine = .rabies
        // sengaja TIDAK pilih dog apapun

        #expect(viewModel.isSaveEnabled == false)
    }
}

//
//  VaccineRecordFormSections.swift
//  Pawsona
//

import SwiftUI

struct VaccineRecordFormVaccineSection: View {
    var viewModel: VaccineRecordFormViewModel

    var body: some View {
        Section("Vaccine") {
            ForEach(VaccineType.allCases, id: \.self) { vaccine in
                VaccineSelectionRow(vaccine: vaccine, isSelected: viewModel.isVaccineSelected(vaccine)) {
                    viewModel.toggleVaccine(vaccine)
                }
            }
        }
    }
}

struct VaccineRecordFormDateSection: View {
    @Bindable var viewModel: VaccineRecordFormViewModel

    private var latestAllowedDate: ClosedRange<Date> {
        .distantPast...Date.now
    }

    var body: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                DatePicker(
                    "Date",
                    selection: $viewModel.dateGiven,
                    in: latestAllowedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }
        }
    }
}

struct VaccineRecordFormNotesSection: View {
    @Bindable var viewModel: VaccineRecordFormViewModel

    var body: some View {
        Section("Notes") {
            TextField("Notes", text: $viewModel.notes, axis: .vertical)
        }
    }
}

struct VaccineRecordFormDogSection: View {
    var viewModel: VaccineRecordFormViewModel
    var dogs: [Dog]

    var body: some View {
        Section("Dog") {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(dogs) { dog in
                        DogAvatarSelectionRow(dog: dog, isSelected: viewModel.isSelected(dog)) {
                            viewModel.toggleDog(dog)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct VaccineRecordFormDeleteSection: View {
    @Binding var isShowingDeleteConfirmation: Bool

    var body: some View {
        Section {
            Button("Delete Vaccination Record", systemImage: "trash", role: .destructive) {
                isShowingDeleteConfirmation = true
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

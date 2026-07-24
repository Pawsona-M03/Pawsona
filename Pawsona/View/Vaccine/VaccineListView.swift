//
//  VaccineListView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI
import UIKit

struct VaccineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VaccineRecord.dateGiven, order: .reverse) private var vaccineRecords: [VaccineRecord]
    @State private var viewModel = VaccineViewModel()
    @State private var scanViewModel = VaccineScanViewModel()
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var recordPendingDeletion: VaccineRecord?
    @State private var recordPendingContextDeletion: VaccineRecord?
    @State private var isShowingNewVaccineForm = false
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isShowingAddOptions = false

    var body: some View {
        NavigationStack {
            Group {
                if vaccineRecords.isEmpty {
                    ContentUnavailableView(
                        "No Vaccine Records",
                        systemImage: "syringe",
                        description: Text("Scan a vaccine book or add a record by hand to start tracking.")
                    )
                } else {
                    List {
                        ForEach(vaccineRecords, id: \.id) { vaccineRecord in
                            Button {
                                editingVaccineRecord = vaccineRecord
                            } label: {
                                VaccineRecordRowView(vaccineRecord: vaccineRecord, showsDogName: true)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 26, bottom: 8, trailing: 26))
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    viewModel.deleteRecord(vaccineRecord, in: modelContext)
                                }
                            }
                            .contextMenu {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    recordPendingContextDeletion = vaccineRecord
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
            .background(Color(.appBackground).ignoresSafeArea())
            .overlay {
                if scanViewModel.isScanning {
                    ScanProgressOverlay()
                }
            }
            .navigationTitle("Vaccination Record")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Vaccination Record", systemImage: "plus") {
                        isShowingAddOptions = true
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color(.primaryBrown))
                    .disabled(scanViewModel.isScanning)
                    .accessibilityShowsLargeContentViewer()
                    .confirmationDialog(
                        "Add Vaccination Record",
                        isPresented: $isShowingAddOptions,
                        titleVisibility: .hidden
                    ) {
                        Button("Scan Vaccine Book", systemImage: "camera.viewfinder", action: scanVaccineBook)
                        Button("Input Manually", systemImage: "square.and.pencil", action: inputManually)
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedImage) {
                guard let image = capturedImage else { return }
                capturedImage = nil
                Task { await scanViewModel.scan(image) }
            }
            .sheet(isPresented: $scanViewModel.isShowingReview) {
                if let visits = scanViewModel.reviewedVisits {
                    VaccineScanReviewView(visits: visits, onConfirm: saveScannedVisits)
                }
            }
            .alert("Scan Failed", isPresented: $scanViewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(scanViewModel.errorMessage ?? "")
            }
            .alert("Something went wrong", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .deleteConfirmation(
                $recordPendingContextDeletion,
                title: "Delete Record?",
                message: { record in
                    """
                    This removes the \(record.vaccineNames) record from every dog \
                    it's assigned to. You can't undo this.
                    """
                },
                perform: { record in
                    viewModel.deleteRecord(record, in: modelContext)
                }
            )
            .sheet(isPresented: $isShowingNewVaccineForm) {
                VaccineRecordFormView(
                    title: "New Vaccination Record",
                    onSave: createVaccineRecord
                )
            }
            .sheet(item: $editingVaccineRecord, onDismiss: deleteIfRequested) { vaccineRecord in
                VaccineRecordFormView(
                    title: "Edit Vaccination Record",
                    draft: VaccineRecordDraft(
                        vaccines: vaccineRecord.vaccines,
                        dateGiven: vaccineRecord.dateGiven,
                        dogs: vaccineRecord.dogList ?? [],
                        notes: vaccineRecord.notes
                    ),
                    onDelete: { recordPendingDeletion = vaccineRecord },
                    onSave: { draft in
                        viewModel.editRecord(vaccineRecord, from: draft, in: modelContext)
                    }
                )
            }
        }
    }

    private func inputManually() {
        isShowingNewVaccineForm = true
    }

    private func scanVaccineBook() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            scanViewModel.report(.cameraUnavailable)
            return
        }

        isShowingCamera = true
    }

    private func saveScannedVisits(_ visits: [ScannedVisit]) {
        scanViewModel.saveScannedVisits(visits, using: viewModel, in: modelContext)
    }

    private func createVaccineRecord(_ draft: VaccineRecordDraft) {
        viewModel.createRecord(from: draft, in: modelContext)
    }

    /// Runs once the edit sheet is gone. Deleting from inside it would destroy
    /// the record while `sheet(item:)` still holds it, and rebuilding that sheet
    /// re-reads the record's properties to fill the draft.
    private func deleteIfRequested() {
        guard let record = recordPendingDeletion else { return }

        recordPendingDeletion = nil
        viewModel.deleteRecord(record, in: modelContext)
    }
}

private struct ScanProgressOverlay: View {
    var body: some View {
        ZStack {
            Color(.appBackground).opacity(0.85)

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)

                Text("Reading vaccine book…")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reading vaccine book")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: [Dog.self, VaccineRecord.self], inMemory: true)
}

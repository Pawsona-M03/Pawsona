//
//  VaccineListView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI

struct VaccineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VaccineRecord.dateGiven, order: .reverse) private var vaccineRecords: [VaccineRecord]
    @State private var viewModel = VaccineViewModel()
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var isShowingNewVaccineForm = false
    
    var body: some View {
        NavigationStack {
            Group {
                if vaccineRecords.isEmpty {
                    VStack {
                        Spacer()
                        
                        Text("Tap '+' to add Vaccination Record")
                            .font(.headline)
                            .foregroundStyle(Color("textSecondary"))
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 26)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vaccineRecords, id: \.id) { vaccineRecord in
                                Button {
                                    editingVaccineRecord = vaccineRecord
                                } label: {
                                    VaccineRecordRowView(vaccineRecord: vaccineRecord, showsDogName: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 26)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background {
                ZStack {
                    Color("backgroundColor")
                    
                    Image("paws_bg")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.3)
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Vaccination Record")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            scanVaccineBook()
                        } label: {
                            Label("Scan Vaccine Book", systemImage: "camera.viewfinder")
                        }
                        
                        Button {
                            inputManually()
                        } label: {
                            Label("Input Manually", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color("textPrimary"))
        
                            .accessibilityLabel("Add Vaccination Record")
                        
                    }
                    .tint(Color("ActionBrown"))
                    .accessibilityShowsLargeContentViewer()
                }
            }
            .sheet(isPresented: $isShowingNewVaccineForm) {
                VaccineRecordFormView(
                    title: "New Vaccination Record",
                    onSave: createVaccineRecord
                )
            }
            .sheet(item: $editingVaccineRecord) { vaccineRecord in
                VaccineRecordFormView(
                    title: "Edit Vaccination Record",
                    vaccines: vaccineRecord.vaccines,
                    dateGiven: vaccineRecord.dateGiven,
                    selectedDogs: vaccineRecord.dogList ?? [],
                    notes: vaccineRecord.notes ?? "",
                    onSave: { vaccines, dateGiven, dogList, notes in
                        editVaccineRecord(
                            vaccineRecord,
                            dogList: dogList,
                            vaccines: vaccines,
                            dateGiven: dateGiven,
                            notes: notes
                        )
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    private func inputManually() {
        isShowingNewVaccineForm = true
    }
    
    private func scanVaccineBook() {
        
    }
    
    private func createVaccineRecord(vaccines: [VaccineType], dateGiven: Date, dogList: [Dog], notes: String?) {
        viewModel.createRecord(
            vaccines: vaccines,
            dateGiven: dateGiven,
            notes: notes,
            dogList: dogList,
            in: modelContext
        )
    }
    
    private func editVaccineRecord(
        _ vaccineRecord: VaccineRecord,
        dogList: [Dog],
        vaccines: [VaccineType],
        dateGiven: Date,
        notes: String?
    ) {
        viewModel.editRecord(
            vaccineRecord,
            vaccines: vaccines,
            dateGiven: dateGiven,
            notes: notes,
            dogList: dogList,
            in: modelContext
        )
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: [Dog.self, VaccineRecord.self], inMemory: true)
}

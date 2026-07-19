//
//  VaccineListView.swift
//  Pawsona
//
//  Created by Raff Melvern Surya Gunawan on 16/07/26.
//

import SwiftData
import SwiftUI

struct VaccineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VaccineRecord.dateGiven, order: .reverse) private var vaccineRecords: [VaccineRecord]
    @State private var viewModel = VaccineViewModel()

    @State private var isShowingAddVaccineForm = false
    @State private var editingVaccineRecord: VaccineRecord?
    @State private var isShowingEditVaccineForm = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Vaccination Record")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        // fungsi: buka sheet VaccineRecordFormView utk tambah record baru
                        Button("Add Vaccination Record", systemImage: "plus") {
                            isShowingAddVaccineForm = true
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddVaccineForm) {
                    VaccineRecordFormView()
                }
                .sheet(isPresented: $isShowingEditVaccineForm) {
                    if let editingVaccineRecord {
                        VaccineRecordFormView(editing: editingVaccineRecord)
                    }
                }
        }
    }

    // fungsi: tampilan kondisional -> empty state kalau vaccineRecords kosong, list grouped kalau ada isinya
    @ViewBuilder
    private var content: some View {
        if vaccineRecords.isEmpty {
            emptyState
        } else {
            recordList
        }
    }

    // fungsi: empty state sesuai referensi (paw pattern background + "Tap '+' to add Vaccination Record")
    private var emptyState: some View {
        ContentUnavailableView(
            "Vaccination Record",
            systemImage: "syringe",
            description: Text("Tap '+' to add Vaccination Record")
        )
    }

    // fungsi: list card, satu card = satu grup (vaccine + tanggal yg sama), isi stacked avatar dog
    private var recordList: some View {
        List {
            // id: record pertama tiap grup — grup nggak pernah kosong (hasil Dictionary(grouping:))
            ForEach(groupedRecords, id: \.[0].id) { group in
                Button {
                    // ponytail: tap-to-edit ambil record pertama di grup, edit form
                    // cuma nampilin 1 dog. Kalau nanti butuh edit semua dog dalam
                    // grup sekaligus, form-nya perlu diubah nerima banyak record.
                    editingVaccineRecord = group.first
                    isShowingEditVaccineForm = true
                } label: {
                    VaccineRecordGroupRowView(records: group)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteVaccineRecordGroups)
        }
    }

    // fungsi: kelompokkan vaccineRecords by (vaccine, dateGiven dibulatkan ke menit)
    // biar record yg dibikin dari 1x submit form (banyak dog) nyatu jadi 1 card
    private var groupedRecords: [[VaccineRecord]] {
        let groups = Dictionary(grouping: vaccineRecords, by: groupKey)
        return groups.values.sorted { lhs, rhs in
            (lhs.first?.dateGiven ?? .distantPast) > (rhs.first?.dateGiven ?? .distantPast)
        }
    }

    private func groupKey(for record: VaccineRecord) -> String {
        let roundedMinute = Int(record.dateGiven.timeIntervalSinceReferenceDate / 60)
        return "\(record.vaccine.rawValue)-\(roundedMinute)"
    }

    private func deleteVaccineRecordGroups(at offsets: IndexSet) {
        let idsToDelete = offsets.flatMap { groupedRecords[$0].map(\.id) }

        Task {
            for id in idsToDelete {
                viewModel.deleteRecord(id: id, in: modelContext)
            }
        }
    }
}

#Preview {
    VaccineListView()
        .modelContainer(for: Dog.self, inMemory: true)
}

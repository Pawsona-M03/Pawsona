//
//  VaccineRecordListScaffold.swift
//  Pawsona
//

import SwiftData
import SwiftUI

struct VaccineRecordListScaffold<
    Data: RandomAccessCollection,
    ID: Hashable,
    RowContent: View,
    AddFormContent: View
>: View {
    var data: Data
    var id: KeyPath<Data.Element, ID>
    var emptyTitle: String
    var emptyDescription: String

    @Binding var isShowingAddVaccineForm: Bool

    var recordToEdit: (Data.Element) -> VaccineRecord?
    var onDelete: (IndexSet) -> Void

    @ViewBuilder var rowContent: (Data.Element) -> RowContent
    @ViewBuilder var addFormContent: () -> AddFormContent

    @State private var editingVaccineRecord: VaccineRecord?
    @State private var isShowingEditVaccineForm = false

    var body: some View {
        Group {
            if data.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "syringe",
                    description: Text(emptyDescription)
                )
            } else {
                List {
                    ForEach(data, id: id) { element in
                        Button {
                            if let record = recordToEdit(element) {
                                editingVaccineRecord = record
                                isShowingEditVaccineForm = true
                            }
                        } label: {
                            rowContent(element)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: onDelete)
                }
            }
        }
        .sheet(isPresented: $isShowingAddVaccineForm) {
            addFormContent()
        }
        .sheet(isPresented: $isShowingEditVaccineForm) {
            if let editingVaccineRecord {
                VaccineRecordFormView(editing: editingVaccineRecord)
            }
        }
    }
}

extension VaccineRecordListScaffold where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        data: Data,
        emptyTitle: String,
        emptyDescription: String,
        isShowingAddVaccineForm: Binding<Bool>,
        recordToEdit: @escaping (Data.Element) -> VaccineRecord?,
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent,
        @ViewBuilder addFormContent: @escaping () -> AddFormContent
    ) {
        self.init(
            data: data,
            id: \.id,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
            isShowingAddVaccineForm: isShowingAddVaccineForm,
            recordToEdit: recordToEdit,
            onDelete: onDelete,
            rowContent: rowContent,
            addFormContent: addFormContent
        )
    }
}

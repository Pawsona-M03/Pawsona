import SwiftUI

struct MarketplaceFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MarketplaceListingQuery

    let breeds: [String]
    let regions: [String]
    let onApply: (MarketplaceListingQuery) -> Void

    init(
        query: MarketplaceListingQuery,
        breeds: [String],
        regions: [String],
        onApply: @escaping (MarketplaceListingQuery) -> Void
    ) {
        _draft = State(initialValue: query)
        self.breeds = breeds
        self.regions = regions
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Listing type") {
                    ForEach(MarketplaceListingType.allCases) { listingType in
                        Toggle(
                            listingType.displayName,
                            isOn: binding(for: listingType)
                        )
                    }
                }

                Section("Puppy") {
                    Picker("Breed", selection: $draft.breed) {
                        Text("Any breed").tag(nil as String?)
                        ForEach(breeds, id: \.self) { breed in
                            Text(breed).tag(breed as String?)
                        }
                    }

                    Picker("Sex", selection: $draft.sex) {
                        Text("Any sex").tag(nil as Sex?)
                        Text("Male").tag(Sex.male as Sex?)
                        Text("Female").tag(Sex.female as Sex?)
                    }

                    Picker("Region", selection: $draft.region) {
                        Text("Any region").tag(nil as String?)
                        ForEach(regions, id: \.self) { region in
                            Text(region).tag(region as String?)
                        }
                    }
                }

                Section {
                    TextField("Minimum price", value: $draft.minimumPrice, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Maximum price", value: $draft.maximumPrice, format: .number)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Sale price in IDR")
                } footer: {
                    Text("Price filters apply only to sale listings.")
                }
            }
            .navigationTitle("Adoption Hub Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        let searchText = draft.searchText
                        draft = MarketplaceListingQuery(searchText: searchText)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    private func binding(for listingType: MarketplaceListingType) -> Binding<Bool> {
        Binding(
            get: { draft.listingTypes.contains(listingType) },
            set: { isSelected in
                if isSelected {
                    draft.listingTypes.insert(listingType)
                } else {
                    draft.listingTypes.remove(listingType)
                }
            }
        )
    }
}

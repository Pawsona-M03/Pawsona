//
//  ContentView.swift
//  Pawsona
//
//  Created by Nathan Sudiara on 11/07/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DogViewModel()
    @State private var selectedTab = AppTab.puppy

    private let marketplaceRepository: any MarketplaceRepository
    private let sellerBlockStore: any SellerBlocking

    init(
        marketplaceRepository: any MarketplaceRepository = LazyCloudKitMarketplaceRepository(),
        sellerBlockStore: any SellerBlocking = UserDefaultsSellerBlockStore()
    ) {
        self.marketplaceRepository = marketplaceRepository
        self.sellerBlockStore = sellerBlockStore
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Puppy", systemImage: "dog", value: .puppy) {
                DogListView(
                    marketplaceRepository: marketplaceRepository,
                    sellerBlockStore: sellerBlockStore
                )
            }

            Tab("Reminder", systemImage: "bell", value: .reminder) {
                UpcomingRemindersView()
            }

            Tab("Vaccine", systemImage: "syringe", value: .vaccine) {
                VaccineListView()
            }

            Tab("Adopt", systemImage: "house", value: .marketplace) {
                MarketplaceView(
                    repository: marketplaceRepository,
                    blockStore: sellerBlockStore
                )
            }
        }
        .tint(Color(.primaryBrown))
        // Handled here rather than inside DogListView: a TabView does not keep
        // unselected tabs alive, so an AirDropped .pawsonadog arriving while the
        // Reminder or Vaccine tab was showing used to be dropped silently.
        .onOpenURL { url in
            guard viewModel.importDogData(from: url, in: modelContext) != nil else { return }
            selectedTab = .puppy
            AccessibilityNotification.Announcement("Dog imported").post()
        }
        .alert("Import failed", isPresented: $viewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Dog.self, Reminder.self, VaccineRecord.self], inMemory: true)
}

//
//  DogDetailView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
import SwiftUI

struct DogDetailView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var dogViewModel = DogViewModel()
    @State private var isShowingEditDogForm = false
    @State private var isPendingDeletion = false
    @State private var sharedFile: SharedFile?
    @State private var marketplaceListing: MarketplaceListing?
    @State private var isShowingMarketplaceFlow = false
    @State private var isCheckingMarketplaceListing = false

    let dog: Dog
    private let marketplaceRepository: any MarketplaceRepository
    private let sellerBlockStore: any SellerBlocking

    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight = 380
    private let sheetCornerRadius: CGFloat = 32

    @State private var containerHeight: CGFloat = 0

    init(
        dog: Dog,
        marketplaceRepository: any MarketplaceRepository = LazyCloudKitMarketplaceRepository(),
        sellerBlockStore: any SellerBlocking = UserDefaultsSellerBlockStore()
    ) {
        self.dog = dog
        self.marketplaceRepository = marketplaceRepository
        self.sellerBlockStore = sellerBlockStore
    }

    var body: some View {
        ZStack(alignment: .top) {
            DogPhotoView(dog: dog, placeholderIconHeight: displayedHeroHeight * 0.6)
                .frame(maxWidth: 410)
                .frame(height: displayedHeroHeight)
                .background(dog.backgroundColor.color.opacity(0.3))
                .background(dog.backgroundColor.color.opacity(0.3))
                .clipped()
                .ignoresSafeArea(edges: .top)
                .accessibilityLabel("Photo of \(displayName)")
                .accessibilityHidden(dog.photoData == nil)

            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: displayedHeroHeight - sheetCornerRadius)

                    sheetContent
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                containerHeight = height
            }
        }
        .background(Color(.appBackground).ignoresSafeArea(edges: .bottom))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: showEditDogForm)
                    // These two are chrome, not calls to action, so they opt out
                    // of the brown the TabView tints everything with.
                    .tint(.primary)
                    .accessibilityShowsLargeContentViewer()
                    .accessibilityLabel("Edit \(displayName)")
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Share via AirDrop", systemImage: "wifi") {
                        share(dogViewModel.shareDogData(dog))
                    }

                    Button("Export as PDF", systemImage: "doc.richtext") {
                        share(dogViewModel.exportDogToPDF(dog))
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.primary)
                .accessibilityLabel("Share \(displayName)")
            }
        }
        .sheet(isPresented: $isShowingEditDogForm, onDismiss: deleteIfRequested) {
            DogEditView(dog: dog, onDelete: { isPendingDeletion = true })
        }
        // Both exports are generated on tap. They used to run on every
        // appearance and every edit-sheet toggle, rendering the dog's photo
        // through ImageRenderer and base64-ing it into JSON for the large
        // majority of visits that never shared anything.
        .sheet(item: $sharedFile) { sharedFile in
            ShareSheet(fileURL: sharedFile.url, previewTitle: displayName)
        }
        .sheet(isPresented: $isShowingMarketplaceFlow, onDismiss: refreshMarketplaceListing) {
            if let marketplaceListing {
                NavigationStack {
                    MarketplaceDetailView(
                        listing: marketplaceListing,
                        repository: marketplaceRepository,
                        blockStore: sellerBlockStore,
                        // Reached from this puppy's own profile, so ownership
                        // is a fact here rather than something to go ask about.
                        isKnownOwnListing: true,
                        updateListingFromPuppy: updateMarketplaceListingFromPuppy
                    )
                }
            } else {
                MarketplacePublishingFlowView(
                    puppy: MarketplaceDogSnapshotMapper.snapshot(from: dog),
                    repository: marketplaceRepository
                )
            }
        }
        .task {
            await loadMarketplaceListing()
        }
        .alert("Something went wrong", isPresented: $dogViewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dogViewModel.errorMessage ?? "")
        }
    }

    private var sheetContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityHeading(.h1)

                Text(breedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel("Breed")
                    .accessibilityValue(breedText)
                Text(dateDog)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel("Date of Birth")
                    .accessibilityValue(dateDog)
            }
            .padding(.top, 24)

            statLayout {
                DogStatBox(title: "Age", value: ageText)
                    .accessibilityLabel("Age")
                    .accessibilityValue(ageAccessibilityValue)
                DogStatBox(title: "Sex", value: sexText)
                    .accessibilityLabel("Sex")
                    .accessibilityValue(sexAccessibilityValue)
                DogStatBox(title: "Weight", value: weightText)
                    .accessibilityLabel("Weight")
                    .accessibilityValue(weightAccessibilityValue)
            }
            .padding(.horizontal)

            NavigationLink {
                DogVaccinationRecordView(dog: dog)
            } label: {
                HStack {
                    Text("Vaccination Record")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(vaccineRecordCount) entries")
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding()
                .cardBackground()
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .accessibilityLabel("Vaccination record")
            .accessibilityValue(vaccineRecordAccessibilityValue)
            .accessibilityHint("Shows vaccination records")

            Button {
                isShowingMarketplaceFlow = true
            } label: {
                Label(
                    marketplaceListing == nil
                        ? "List on Marketplace" : "Manage Marketplace Listing",
                    systemImage: marketplaceListing == nil ? "storefront" : "slider.horizontal.3"
                )
                .frame(maxWidth: .infinity, maxHeight: 27)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCheckingMarketplaceListing)
            .padding(.horizontal)
            .accessibilityHint(
                marketplaceListing == nil
                    ? "Creates a public snapshot after confirmation"
                    : "Shows public listing management actions"
            )
            .tint(.primaryBrown)

            Spacer(minLength: 40)
        }
        .padding(.bottom, 120)
        .frame(
            maxWidth: .infinity,
            minHeight: max(0, containerHeight),
            alignment: .top
        )
        .background(Color(.appBackground))
        .clipShape(.rect(topLeadingRadius: sheetCornerRadius, topTrailingRadius: sheetCornerRadius))
    }

    private var displayName: String { dog.displayName }

    /// The hero grows with Dynamic Type but stops short of swallowing the
    /// screen. It was previously capped at its own base value, which made the
    /// ScaledMetric a no-op at every size at or above default.
    private var displayedHeroHeight: CGFloat {
        min(heroHeight, 520)
    }

    private var statLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(spacing: 12))
        } else {
            AnyLayout(HStackLayout(spacing: 12))
        }
    }

    private var breedText: String { dog.breedText }
    private var dateDog: String {
        guard let dateOfBirth = dog.dateOfBirth else { return "-" }

        return dateOfBirth.formatted(date: .abbreviated, time: .omitted)
    }

    /// Presents a freshly generated export, unless generating it failed — in
    /// which case the view model has already set the message the alert shows.
    private func share(_ fileURL: URL?) {
        guard let fileURL else { return }
        sharedFile = SharedFile(url: fileURL)
    }

    private var ageText: String {
        dog.ageText ?? "-"
    }

    private var ageAccessibilityValue: String {
        dog.ageText ?? "Not set"
    }

    private var sexText: String {
        switch dog.sex {
        case .male: "Male"
        case .female: "Female"
        case nil: "-"
        }
    }

    private var sexAccessibilityValue: String {
        switch dog.sex {
        case .male: "Male"
        case .female: "Female"
        case nil: "Not set"
        }
    }

    private var weightText: String {
        guard let weight = dog.weight else { return "-" }
        return weight.formatted(.number.precision(.fractionLength(1)))
    }

    private var weightAccessibilityValue: String {
        dog.weight == nil ? "Not set" : weightText
    }

    private var vaccineRecordCount: Int {
        dog.vaccineRecords?.count ?? 0
    }

    private var vaccineRecordAccessibilityValue: String {
        vaccineRecordCount == 1 ? "1 entry" : "\(vaccineRecordCount) entries"
    }

    private func showEditDogForm() {
        isShowingEditDogForm = true
    }

    private func loadMarketplaceListing() async {
        guard !isCheckingMarketplaceListing else { return }
        isCheckingMarketplaceListing = true
        defer { isCheckingMarketplaceListing = false }
        marketplaceListing = try? await marketplaceRepository.fetchListing(
            sourceDogID: MarketplaceDogSnapshotMapper.safeSourceID(for: dog)
        )
    }

    private func refreshMarketplaceListing() {
        Task {
            await loadMarketplaceListing()
        }
    }

    private func updateMarketplaceListingFromPuppy() async throws -> MarketplaceListing {
        guard let marketplaceListing else {
            throw MarketplaceError.notFound
        }
        let sellerProfile = try await marketplaceRepository.fetchSellerProfile(
            id: marketplaceListing.sellerProfileID
        )
        let snapshot = try MarketplaceDogSnapshotMapper.listing(
            from: MarketplaceDogSnapshotMapper.snapshot(from: dog),
            sellerProfile: sellerProfile,
            listingType: marketplaceListing.listingType,
            priceAmount: marketplaceListing.priceAmount,
            existingListing: marketplaceListing
        )
        let updated = try await marketplaceRepository.updateListingFromDog(snapshot)
        self.marketplaceListing = updated
        return updated
    }

    /// Runs once the edit sheet is fully gone, not from inside it. This screen is
    /// pushed and holds `dog`, so destroying the model while the sheet is still
    /// animating away would leave the body reading an invalidated object for a
    /// frame. Popping first means there is nothing left to re-render.
    private func deleteIfRequested() {
        guard isPendingDeletion else { return }

        isPendingDeletion = false
        dismiss()
        dogViewModel.deleteDog(dog, in: modelContext)
        AccessibilityNotification.Announcement("Dog deleted").post()
    }
}

#Preview {
    NavigationStack {
        DogDetailView(
            dog: Dog(
                name: "Berry sodijoasidjfoaisdjfoaisdjfoaisdosidBerry  Berry asiodjfoaisjdfoaisjdoaijdsfoaijsdofiajsdo",
                breed: "Labrador Retriever",
                backgroundColor: .green,
                dateOfBirth: DateComponents(
                    calendar: .current,
                    year: 2000,
                    month: 10,
                    day: 19
                ).date ?? .now
            )
        )
    }
    .modelContainer(for: Dog.self, inMemory: true)
}

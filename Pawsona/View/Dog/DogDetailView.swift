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
    @State private var dogViewModel = DogViewModel()
    @State private var isShowingEditDogForm = false
    @State private var exportedPDFURL: URL?
    @State private var exportedDataURL: URL?

    let dog: Dog

    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight = 380
    private let sheetCornerRadius: CGFloat = 32

    @State private var containerHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            DogPhotoView(dog: dog, placeholderIconHeight: displayedHeroHeight * 0.6)
                .frame(maxWidth: 410)
                .frame(height: displayedHeroHeight)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: showEditDogForm)
                    .accessibilityShowsLargeContentViewer()
                    .accessibilityLabel("Edit \(displayName)")
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let exportedDataURL {
                        ShareLink(item: exportedDataURL, preview: SharePreview(displayName)) {
                            Label("Share via AirDrop", systemImage: "wifi")
                        }
                    }

                    if let exportedPDFURL {
                        ShareLink(item: exportedPDFURL, preview: SharePreview(displayName)) {
                            Label("Export as PDF", systemImage: "doc.richtext")
                        }
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(exportedDataURL == nil && exportedPDFURL == nil)
                .accessibilityLabel("Share \(displayName)")
            }
        }
        .sheet(isPresented: $isShowingEditDogForm) {
            DogEditView(dog: dog)
        }
        .task(id: isShowingEditDogForm) {
            exportedPDFURL = dogViewModel.exportDogToPDF(dog)
            exportedDataURL = dogViewModel.shareDogData(dog)
        }
    }

    private var sheetContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .accessibilityHeading(.h1)

                Text(breedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Breed")
                    .accessibilityValue(breedText)
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

            Spacer(minLength: 40)
        }
        .padding(.bottom, 24)
        .frame(
            maxWidth: .infinity,
            minHeight: max(0, containerHeight - (sheetCornerRadius)),
            alignment: .top
        )
        .background(Color(.appBackground))
        .clipShape(.rect(topLeadingRadius: sheetCornerRadius, topTrailingRadius: sheetCornerRadius))
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var displayedHeroHeight: CGFloat {
        min(heroHeight, 380)
    }

    private var statLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(spacing: 12))
        } else {
            AnyLayout(HStackLayout(spacing: 12))
        }
    }

    private var breedText: String {
        dog.breed.isEmpty ? "Breed not set" : dog.breed
    }

    private var ageText: String {
        guard let age = dog.age else { return "-" }
        return "\(age)"
    }

    private var ageAccessibilityValue: String {
        guard let age = dog.age else { return "Not set" }
        return age == 1 ? "1 year" : "\(age) years"
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
}

#Preview {
    NavigationStack {
        DogDetailView(
            dog: Dog(
                name: "Berry",
                breed: "Labrador Retriever",
                backgroundColor: .green,
                dateOfBirth: Date.now
            )
        )
    }
    .modelContainer(for: Dog.self, inMemory: true)
}

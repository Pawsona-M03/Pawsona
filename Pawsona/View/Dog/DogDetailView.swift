//
//  DogDetailView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 14/07/26.
//

import SwiftData
import SwiftUI

struct DogDetailView: View {
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
            DogPhotoView(dog: dog, placeholderIconHeight: heroHeight * 0.6)
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .background(dog.backgroundColor.color.opacity(0.3))
                .clipped()
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: heroHeight - sheetCornerRadius)

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
            }
        }
        .sheet(isPresented: $isShowingEditDogForm) {
            DogEditView(dog: dog)
        }
        .task(id: isShowingEditDogForm) {
            // Skip PDF and data regeneration when the edit sheet is opening.
            guard !isShowingEditDogForm else { return }
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

                Text(breedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            HStack(spacing: 12) {
                DogStatBox(title: "Age", value: ageText)
                DogStatBox(title: "Sex", value: sexText)
                DogStatBox(title: "Weight", value: weightText)
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
                }
                .padding()
                .background(.quinary, in: .rect(cornerRadius: 14))
                .background(.background, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Spacer(minLength: 40)
        }
        .padding(.bottom, 24)
        .frame(
            maxWidth: .infinity,
            minHeight: max(0, containerHeight - (sheetCornerRadius)),
            alignment: .top
        )
        .background {
            Image(.pawsBg)
                .resizable()
                .scaledToFill()
        }
        .background(.background)
        .clipShape(.rect(topLeadingRadius: sheetCornerRadius, topTrailingRadius: sheetCornerRadius))
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
    }

    private var breedText: String {
        dog.breed.isEmpty ? "Breed not set" : dog.breed
    }

    private var ageText: String {
        guard let age = dog.age else { return "-" }
        return "\(age)"
    }

    private var sexText: String {
        switch dog.sex {
        case .male: "Male"
        case .female: "Female"
        case nil: "-"
        }
    }

    private var weightText: String {
        guard let weight = dog.weight else { return "-" }
        return weight.formatted(.number.precision(.fractionLength(1)))
    }

    private var vaccineRecordCount: Int {
        dog.vaccineRecords?.count ?? 0
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

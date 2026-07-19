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

                    DogDetailSheetContent(
                        dog: dog,
                        containerHeight: containerHeight,
                        sheetCornerRadius: sheetCornerRadius
                    )
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
            dogViewModel.clearExportsDirectory()
            exportedPDFURL = dogViewModel.exportDogToPDF(dog)
            exportedDataURL = dogViewModel.shareDogData(dog)
        }
    }

    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Dog" : trimmedName
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

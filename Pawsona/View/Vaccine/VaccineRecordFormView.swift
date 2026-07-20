//
//  VaccineRecordFormView.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftData
import SwiftUI
import UIKit

struct VaccineRecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dog.name) private var dogs: [Dog]
    
    let title: String
    let onSave: ([VaccineType], Date, [Dog], String?) -> Void
    
    @State private var vaccines: [VaccineType]
    @State private var selectedDogIDs: Set<UUID>
    @State private var dateGiven: Date
    @State private var notes: String
    
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isScanning = false
    @State private var scannerErrorMsg: String?
    
    init(
        title: String = "New Vaccination Record",
        vaccines: [VaccineType] = [],
        dateGiven: Date = Date.now,
        selectedDogs: [Dog] = [],
        notes: String = "",
        onSave: @escaping ([VaccineType], Date, [Dog], String?) -> Void
    ) {
        self.title = title
        self.onSave = onSave
        self._vaccines = State(initialValue: vaccines)
        self._selectedDogIDs = State(initialValue: Set(selectedDogs.map(\.id)))
        self._dateGiven = State(initialValue: dateGiven)
        self._notes = State(initialValue: notes)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    vaccineSection
                    dateSection
                    dogSection
                }
                .padding(.horizontal, 30)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: scanVaccineBook) {
                    HStack {
                        if isScanning {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                            Text("Analyzing Book...")
                        } else {
                            Text("Scan Vaccine Book")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(isScanning ? Color.gray : Color.brown)
                    .clipShape(.rect(cornerRadius: 26))
                    .padding(.horizontal, 30)
                    .padding(.bottom, 18)
                    .background(.background)
                }
                .disabled(isScanning)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                        .disabled(isScanning)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveVaccineRecord)
                        .disabled(!isSaveEnabled || isScanning)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedImage) {
                if let image = capturedImage {
                    processImageWithGemini(image)
                }
            }
            .alert(
                "Scan Error",
                isPresented: Binding(
                    get: { scannerErrorMsg != nil },
                    set: { if !$0 { scannerErrorMsg = nil } }
                ),
                presenting: scannerErrorMsg
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { errorMsg in
                Text(errorMsg)
            }
            
        }
    }
    
    private func scanVaccineBook() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            scannerErrorMsg = "Camera is not available on this device."
        }
    }
    
    private func processImageWithGemini(_ image: UIImage) {
        isScanning = true
        capturedImage = nil
        
        Task {
            do {
                let result = try await GeminiScanner.scan(image)
                
                await MainActor.run {
                    applyGeminiResult(result.visit)
                    isScanning = false
                }
            } catch {
                await MainActor.run {
                    scannerErrorMsg = error.localizedDescription
                    isScanning = false
                }
            }
        }
    }
    
    private func applyGeminiResult(_ visit: VaccineVisit) {
        // Mencocokkan string Gemini dengan Enum Pawsona
        for geminiVaccineName in visit.vaccinesAdministered {
            let normalizedName = geminiVaccineName.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Mencari di Enum VaccineType apakah ada yang cocok
            if let matchedType = VaccineType.allCases.first(where: {
                $0.rawValue.lowercased() == normalizedName ||
                $0.displayName.lowercased() == normalizedName
            }) {
                if !vaccines.contains(matchedType) {
                    vaccines.append(matchedType)
                }
            }
        }
        
        // Menerjemahkan string ke Date
        if let dateString = visit.vaccinationDateGiven {
            if let extractedDate = parseDateString(dateString) {
                dateGiven = extractedDate
            }
        }
        
    }
    
    private func parseDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        
        let formats = ["dd/MM/yy", "dd/MM/yyyy", "dd-MM-yy", "yyyy-MM-dd", "dd MMM yyyy"]
        let cleanString = dateString.replacingOccurrences(of: " ", with: "")
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleanString) {
                return date
            }
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
    
    private var vaccineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vaccine")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                ForEach(VaccineType.allCases, id: \.self) { vaccine in
                    VaccineSelectionButton(
                        vaccine: vaccine,
                        isSelected: vaccines.contains(vaccine),
                        action: { toggleVaccine(vaccine) }
                    )
                }
            }
        }
    }
    
    private var dateSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Date")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            Spacer()
            
            DatePicker(
                "Vaccination date",
                selection: $dateGiven,
                displayedComponents: .date
            )
            .labelsHidden()
            
            DatePicker(
                "Vaccination time",
                selection: $dateGiven,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }
    
    private var dogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dog")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            if dogs.isEmpty {
                ContentUnavailableView(
                    "No Dogs Yet",
                    systemImage: "pawprint",
                    description: Text("Add a dog before saving a vaccination record.")
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 14)], alignment: .leading, spacing: 14) {
                    ForEach(dogs, id: \.id) { dog in
                        VaccineDogSelectionButton(
                            dog: dog,
                            isSelected: selectedDogIDs.contains(dog.id),
                            action: { toggleDog(dog) }
                        )
                    }
                }
            }
        }
    }
    
    private var isSaveEnabled: Bool {
        !vaccines.isEmpty && !selectedDogIDs.isEmpty
    }
    
    private var selectedDogs: [Dog] {
        dogs.filter { selectedDogIDs.contains($0.id) }
    }
    
    private func toggleVaccine(_ vaccine: VaccineType) {
        if let index = vaccines.firstIndex(of: vaccine) {
            vaccines.remove(at: index)
        } else {
            vaccines.append(vaccine)
        }
    }
    
    private func toggleDog(_ dog: Dog) {
        if selectedDogIDs.contains(dog.id) {
            selectedDogIDs.remove(dog.id)
        } else {
            selectedDogIDs.insert(dog.id)
        }
    }
    
    private func saveVaccineRecord() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(
            vaccines,
            dateGiven,
            selectedDogs,
            trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        dismiss()
    }
    
}

private struct VaccineSelectionButton: View {
    let vaccine: VaccineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(vaccine.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brown : Color.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct VaccineDogSelectionButton: View {
    let dog: Dog
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                avatar
                    .overlay {
                        Circle()
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 3)
                    }
                
                Text(displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 58)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 58, minHeight: 78)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let photoData = dog.photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(.circle)
        } else {
            Circle()
                .fill(.secondary.opacity(0.14))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary.opacity(0.28))
                }
        }
    }
    
    private var displayName: String {
        let trimmedName = dog.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Puppy" : trimmedName
    }
}

#Preview {
    VaccineRecordFormView { _, _, _, _ in }
        .modelContainer(for: [Dog.self, VaccineRecord.self], inMemory: true)
}

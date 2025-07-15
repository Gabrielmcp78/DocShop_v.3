import SwiftUI

struct BulkDeleteView: View {
    @ObservedObject private var library = DocLibraryIndex.shared
    @State private var selectedCriteria: DeleteCriteria = .company
    @State private var selectedItems: Set<String> = []
    @State private var selectedDocuments: Set<UUID> = []
    @State private var showIndividualSelection = false
    @State private var showConfirmation = false
    @State private var isDeleting = false
    @Environment(\.presentationMode) var presentationMode
    
    enum DeleteCriteria: String, CaseIterable {
        case company = "Company"
        case language = "Language"
        case contentType = "Content Type"
        case dateRange = "Date Range"
        case accessCount = "Access Count"
        case fileSize = "File Size"
        
        var icon: String {
            switch self {
            case .company: return "building.2"
            case .language: return "chevron.left.forwardslash.chevron.right"
            case .contentType: return "doc.text"
            case .dateRange: return "calendar"
            case .accessCount: return "eye"
            case .fileSize: return "doc.badge.gearshape"
            }
        }
    }
    
    var availableOptions: [String] {
        switch selectedCriteria {
        case .company:
            return getCompanyOptions()
        case .language:
            return getLanguageOptions()
        case .contentType:
            return getContentTypeOptions()
        case .dateRange:
            return getDateRangeOptions()
        case .accessCount:
            return getAccessCountOptions()
        case .fileSize:
            return getFileSizeOptions()
        }
    }
    
    var filteredDocuments: [DocumentMetaData] {
        return library.documents.filter { document in
            selectedItems.contains { selectedItem in
                switch selectedCriteria {
                case .company:
                    return extractCompany(from: document.sourceURL) == selectedItem
                case .language:
                    return extractLanguage(from: document.tagsArray) == selectedItem
                case .contentType:
                    return document.contentType.displayName == selectedItem
                case .dateRange:
                    return getDateRange(for: document) == selectedItem
                case .accessCount:
                    return getAccessCountRange(for: document) == selectedItem
                case .fileSize:
                    return getFileSizeRange(for: document) == selectedItem
                }
            }
        }
    }
    
    var documentsToDelete: [DocumentMetaData] {
        if showIndividualSelection {
            return library.documents.filter { selectedDocuments.contains($0.id) }
        } else {
            return filteredDocuments
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            
            criteriaSelectionSection
            
            itemSelectionSection
            
            if !filteredDocuments.isEmpty && !selectedItems.isEmpty {
                individualDocumentSelectionSection
            }
            
            previewSection
            
            Spacer()
            
            actionButtonsSection
        }
        .padding()
        .navigationTitle("Bulk Delete Documents")
        .alert("Confirm Deletion", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(documentsToDelete.count) Documents", role: .destructive) {
                performBulkDelete()
            }
        } message: {
            Text("This will permanently delete \(documentsToDelete.count) documents. This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Bulk Delete Documents")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Select documents to delete by choosing criteria and specific items.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var criteriaSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delete By")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 8)
            ], spacing: 8) {
                ForEach(DeleteCriteria.allCases, id: \.self) { criteria in
                    Button(action: {
                        selectedCriteria = criteria
                        selectedItems.removeAll()
                    }) {
                        HStack {
                            Image(systemName: criteria.icon)
                                .font(.caption)
                            Text(criteria.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCriteria == criteria ? .blue : .gray.opacity(0.1))
                        .foregroundColor(selectedCriteria == criteria ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var itemSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select \(selectedCriteria.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Check All") {
                        selectedItems = Set(availableOptions)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .disabled(availableOptions.isEmpty)
                    
                    if !selectedItems.isEmpty {
                        Button("Clear All") {
                            selectedItems.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            if availableOptions.isEmpty {
                Text("No options available for this criteria")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 8)
                ], spacing: 8) {
                    ForEach(availableOptions, id: \.self) { option in
                        let documentCount = getDocumentCount(for: option)
                        
                        Button(action: {
                            if selectedItems.contains(option) {
                                selectedItems.remove(option)
                            } else {
                                selectedItems.insert(option)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(option)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Spacer()
                                    if selectedItems.contains(option) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                                
                                Text("\(documentCount) documents")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedItems.contains(option) ? .blue.opacity(0.1) : .gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedItems.contains(option) ? .blue : .clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            if documentsToDelete.isEmpty {
                Text("No documents selected for deletion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(documentsToDelete.count) documents will be deleted:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(documentsToDelete.prefix(10), id: \.id) { document in
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(document.displayTitle)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            
                            if documentsToDelete.count > 10 {
                                Text("... and \(documentsToDelete.count - 10) more")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
                .padding()
                .background(.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var actionButtonsSection: some View {
        HStack {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            if isDeleting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Deleting...")
                        .font(.subheadline)
                }
            } else {
                Button("Delete \(documentsToDelete.count) Documents") {
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(documentsToDelete.isEmpty)
                .foregroundColor(.white)
                .background(documentsToDelete.isEmpty ? .gray : .red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCompanyOptions() -> [String] {
        let companies = Set(library.documents.map { extractCompany(from: $0.sourceURL) })
        return Array(companies).sorted()
    }
    
    private func getLanguageOptions() -> [String] {
        let languages = Set(library.documents.map { extractLanguage(from: $0.tagsArray) })
        return Array(languages).sorted()
    }
    
    private func getContentTypeOptions() -> [String] {
        let types = Set(library.documents.map { $0.contentType.displayName })
        return Array(types).sorted()
    }
    
    private func getDateRangeOptions() -> [String] {
        return ["Last 7 days", "Last 30 days", "Last 3 months", "Last 6 months", "Older than 6 months"]
    }
    
    private func getAccessCountOptions() -> [String] {
        return ["Never accessed", "1-5 times", "6-20 times", "More than 20 times"]
    }
    
    private func getFileSizeOptions() -> [String] {
        return ["Less than 10 KB", "10-100 KB", "100 KB - 1 MB", "Larger than 1 MB"]
    }
    
    private func getDocumentCount(for option: String) -> Int {
        return library.documents.filter { document in
            switch selectedCriteria {
            case .company:
                return extractCompany(from: document.sourceURL) == option
            case .language:
                return extractLanguage(from: document.tagsArray) == option
            case .contentType:
                return document.contentType.displayName == option
            case .dateRange:
                return getDateRange(for: document) == option
            case .accessCount:
                return getAccessCountRange(for: document) == option
            case .fileSize:
                return getFileSizeRange(for: document) == option
            }
        }.count
    }
    
    private func extractCompany(from url: String) -> String {
        let lowercaseURL = url.lowercased()
        if lowercaseURL.contains("apple") { return "Apple" }
        if lowercaseURL.contains("google") { return "Google" }
        if lowercaseURL.contains("microsoft") { return "Microsoft" }
        if lowercaseURL.contains("amazon") { return "Amazon" }
        if lowercaseURL.contains("meta") || lowercaseURL.contains("facebook") { return "Meta" }
        if lowercaseURL.contains("github") { return "GitHub" }
        if lowercaseURL.contains("stackoverflow") { return "Stack Overflow" }
        if lowercaseURL.contains("mozilla") { return "Mozilla" }
        if lowercaseURL.contains("openai") { return "OpenAI" }
        if lowercaseURL.contains("anthropic") { return "Anthropic" }
        
        if let domain = URL(string: url)?.host {
            let cleanDomain = domain.replacingOccurrences(of: "www.", with: "")
            return cleanDomain.components(separatedBy: ".").first?.capitalized ?? "Unknown"
        }
        return "Unknown"
    }
    
    private func extractLanguage(from tags: [String]) -> String {
        let lowercaseTags = tags.map { $0.lowercased() }
        if lowercaseTags.contains("swift") { return "Swift" }
        if lowercaseTags.contains("python") { return "Python" }
        if lowercaseTags.contains("javascript") || lowercaseTags.contains("js") { return "JavaScript" }
        if lowercaseTags.contains("java") { return "Java" }
        if lowercaseTags.contains("typescript") || lowercaseTags.contains("ts") { return "TypeScript" }
        if lowercaseTags.contains("rust") { return "Rust" }
        if lowercaseTags.contains("go") || lowercaseTags.contains("golang") { return "Go" }
        if lowercaseTags.contains("c++") || lowercaseTags.contains("cpp") { return "C++" }
        if lowercaseTags.contains("c#") || lowercaseTags.contains("csharp") { return "C#" }
        return "General"
    }
    
    private func getDateRange(for document: DocumentMetaData) -> String {
        let daysSinceImport = Calendar.current.dateComponents([.day], from: document.dateImported, to: Date()).day ?? 0
        
        if daysSinceImport <= 7 { return "Last 7 days" }
        if daysSinceImport <= 30 { return "Last 30 days" }
        if daysSinceImport <= 90 { return "Last 3 months" }
        if daysSinceImport <= 180 { return "Last 6 months" }
        return "Older than 6 months"
    }
    
    private func getAccessCountRange(for document: DocumentMetaData) -> String {
        if document.accessCount == 0 { return "Never accessed" }
        if document.accessCount <= 5 { return "1-5 times" }
        if document.accessCount <= 20 { return "6-20 times" }
        return "More than 20 times"
    }
    
    private func getFileSizeRange(for document: DocumentMetaData) -> String {
        let sizeKB = document.fileSize / 1024
        
        if sizeKB < 10 { return "Less than 10 KB" }
        if sizeKB < 100 { return "10-100 KB" }
        if sizeKB < 1024 { return "100 KB - 1 MB" }
        return "Larger than 1 MB"
    }
    
    private var individualDocumentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Individual Documents")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("(\(filteredDocuments.count) found)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Select All") {
                        selectedDocuments = Set(filteredDocuments.map { $0.id })
                        showIndividualSelection = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    if !selectedDocuments.isEmpty {
                        Button("Clear Selection") {
                            selectedDocuments.removeAll()
                            showIndividualSelection = false
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Button(showIndividualSelection ? "Hide Individual" : "Show Individual") {
                        showIndividualSelection.toggle()
                        if !showIndividualSelection {
                            selectedDocuments.removeAll()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
            }
            
            if showIndividualSelection {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredDocuments, id: \.id) { document in
                            Button(action: {
                                if selectedDocuments.contains(document.id) {
                                    selectedDocuments.remove(document.id)
                                } else {
                                    selectedDocuments.insert(document.id)
                                }
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: selectedDocuments.contains(document.id) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedDocuments.contains(document.id) ? .blue : .secondary)
                                        .font(.subheadline)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(document.displayTitle)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack {
                                            Text(extractCompany(from: document.sourceURL))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(document.contentType.displayName)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(document.formattedFileSize)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(document.formattedDate)
                                            .font(.caption2)
                                            .foregroundColor(.tertiary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedDocuments.contains(document.id) ? .blue.opacity(0.1) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func performBulkDelete() {
        isDeleting = true
        
        Task {
            for document in documentsToDelete {
                // Delete the document file
                do {
                    try DocumentStorage.shared.deleteDocument(at: URL(fileURLWithPath: document.filePath))
                } catch {
                    print("Failed to delete document file: \(error)")
                }
                
                // Remove from library
                library.removeDocument(document)
            }
            
            await MainActor.run {
                isDeleting = false
                selectedItems.removeAll() // Clear selections but stay in the view
                selectedDocuments.removeAll() // Clear individual selections too
                showIndividualSelection = false // Hide individual selection
                // Don't dismiss - stay in bulk delete view for more operations
            }
        }
    }
}

#Preview {
    NavigationView {
        BulkDeleteView()
    }
}
import SwiftUI

/// Advanced search interface for DocShop - BMad Implementation Example
struct SearchView: View {
    @StateObject private var searchEngine = SearchEngine()
    @State private var showingFilters = false
    @State private var selectedSearchType: SearchEngine.SearchType = .combined
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            SearchHeaderView(
                searchEngine: searchEngine,
                selectedSearchType: $selectedSearchType,
                showingFilters: $showingFilters
            )
            
            // Active Filters
            if !searchEngine.appliedFilters.isEmpty {
                ActiveFiltersView(searchEngine: searchEngine)
            }
            
            // Search Results
            SearchResultsView(searchEngine: searchEngine)
        }
        .navigationTitle("Search")
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(searchEngine: searchEngine)
        }
    }
}

struct SearchHeaderView: View {
    @ObservedObject var searchEngine: SearchEngine
    @Binding var selectedSearchType: SearchEngine.SearchType
    @Binding var showingFilters: Bool
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search documents...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            searchEngine.search(searchText, type: selectedSearchType)
                        }
                        .onChange(of: searchText) { _, newValue in
                            if newValue.isEmpty {
                                searchEngine.clearSearch()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchEngine.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                Button("Filters") {
                    showingFilters = true
                }
                .buttonStyle(.bordered)
            }
            
            // Search Type Picker
            Picker("Search Type", selection: $selectedSearchType) {
                Text("All").tag(SearchEngine.SearchType.combined)
                Text("Content").tag(SearchEngine.SearchType.fullText)
                Text("Metadata").tag(SearchEngine.SearchType.metadata)
                Text("Tags").tag(SearchEngine.SearchType.tags)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedSearchType) { _, _ in
                if !searchText.isEmpty {
                    searchEngine.search(searchText, type: selectedSearchType)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}

struct ActiveFiltersView: View {
    @ObservedObject var searchEngine: SearchEngine
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(searchEngine.appliedFilters, id: \.value) { filter in
                    FilterChip(filter: filter) {
                        searchEngine.removeFilter(filter)
                    }
                }
                
                Button("Clear All") {
                    searchEngine.clearFilters()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor).opacity(0.3))
    }
}

struct FilterChip: View {
    let filter: SearchEngine.SearchFilter
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(filterDisplayText)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
    
    private var filterDisplayText: String {
        switch filter.type {
        case .documentType:
            return "Type: \(filter.value)"
        case .dateRange:
            return "Date: \(filter.value)"
        case .fileSize:
            return "Size: \(filter.value)"
        case .tag:
            return "Tag: \(filter.value)"
        }
    }
}

struct SearchResultsView: View {
    @ObservedObject var searchEngine: SearchEngine
    
    var body: some View {
        Group {
            if searchEngine.isSearching {
                VStack {
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if searchEngine.searchResults.isEmpty && !searchEngine.searchQuery.isEmpty {
                SearchEmptyStateView(query: searchEngine.searchQuery)
                
            } else if searchEngine.searchResults.isEmpty {
                SearchWelcomeView()
                
            } else {
                SearchResultsList(results: searchEngine.searchResults, query: searchEngine.searchQuery)
            }
        }
    }
}

struct SearchResultsList: View {
    let results: [DocumentMetaData]
    let query: String
    
    var body: some View {
        List {
            Section(header: Text("\(results.count) results for \"\(query)\"")) {
                ForEach(results, id: \.id) { document in
                    SearchResultRow(document: document, query: query)
                }
            }
        }
        .listStyle(.inset)
    }
}

struct SearchResultRow: View {
    let document: DocumentMetaData
    let query: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(URL(fileURLWithPath: document.filePath).lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(document.contentType.displayName.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    if let dateModified = document.dateModified {
                        Text(dateModified, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    else {
                        Text("Never Modified")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Content preview with highlighted search terms
            Text(getContentPreview(document: document, query: query))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to document detail
        }
    }
    
    private func getContentPreview(document: DocumentMetaData, query: String) -> String {
        // Try to load document content for preview
        do {
            let fileURL = URL(fileURLWithPath: document.filePath)
            let content = try DocumentStorage.shared.loadDocument(at: fileURL)
            
            let queryTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            guard let firstTerm = queryTerms.first else {
                return String(content.prefix(200))
            }
            
            let lowercaseContent = content.lowercased()
            if let range = lowercaseContent.range(of: firstTerm) {
                let startIndex = max(content.startIndex, content.index(range.lowerBound, offsetBy: -50, limitedBy: content.startIndex) ?? content.startIndex)
                let endIndex = min(content.endIndex, content.index(range.upperBound, offsetBy: 150, limitedBy: content.endIndex) ?? content.endIndex)
                
                let preview = String(content[startIndex..<endIndex])
                return preview.hasPrefix(String(content.prefix(50))) ? preview : "..." + preview
            }
            
            return String(content.prefix(200))
        } catch {
            return "Preview not available"
        }
    }
}

struct SearchEmptyStateView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No documents match \"\(query)\"")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Try:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("• Using different keywords")
                Text("• Checking your spelling")
                Text("• Using fewer search terms")
                Text("• Adjusting your filters")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SearchWelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Search Your Documents")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Find documents by content, title, filename, or tags")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                SearchTipRow(icon: "text.magnifyingglass", title: "Full-text search", description: "Search within document content")
                SearchTipRow(icon: "tag", title: "Tag search", description: "Find documents by tags")
                SearchTipRow(icon: "slider.horizontal.3", title: "Advanced filters", description: "Filter by type, date, and more")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SearchTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SearchFiltersView: View {
    @ObservedObject var searchEngine: SearchEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Document Type") {
                    // Document type filters would go here
                }
                
                Section("Date Range") {
                    // Date range filters would go here
                }
                
                Section("File Size") {
                    // File size filters would go here
                }
                
                Section("Tags") {
                    // Tag filters would go here
                }
            }
            .navigationTitle("Search Filters")
            //.navigationBarTitleDisplayMode(.inline) // Removed for macOS compatibility
            .toolbar {
                ToolbarItemGroup {
                    Button("Cancel") {
                        dismiss()
                    }
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView()
}


import SwiftUI

// MARK: - Main Library View
struct EnhancedLibraryView: View {
    @StateObject private var libraryManager = DocumentLibraryManager()
    @State private var viewMode: LibraryViewMode = .grid
    @State private var filters = DocumentFilters()
    @State private var selectedDocument: Document?
    @State private var showingFilters = false
    @State private var showingPreview = false
    
    var filteredDocuments: [Document] {
        libraryManager.documents.filter { document in
            // Search text filter
            if !filters.searchText.isEmpty &&
               !document.searchableText.localizedCaseInsensitiveContains(filters.searchText) {
                return false
            }
            
            // Language filter
            if !filters.selectedLanguages.isEmpty &&
               !filters.selectedLanguages.contains(document.language) {
                return false
            }
            
            // Framework filter
            if !filters.selectedFrameworks.isEmpty &&
               !filters.selectedFrameworks.contains(document.framework) {
                return false
            }
            
            // Type filter
            if !filters.selectedTypes.isEmpty &&
               !filters.selectedTypes.contains(document.documentType) {
                return false
            }
            
            // Bookmark filter
            if filters.showBookmarkedOnly && !document.isBookmarked {
                return false
            }
            
            return true
        }.sorted { doc1, doc2 in
            switch filters.sortBy {
            case .title:
                return filters.sortOrder == .ascending ? 
                    doc1.title < doc2.title : doc1.title > doc2.title
            case .dateAdded:
                return filters.sortOrder == .ascending ? 
                    doc1.dateAdded < doc2.dateAdded : doc1.dateAdded > doc2.dateAdded
            case .dateModified:
                return filters.sortOrder == .ascending ? 
                    doc1.dateModified < doc2.dateModified : doc1.dateModified > doc2.dateModified
            case .accessCount:
                return filters.sortOrder == .ascending ? 
                    doc1.accessCount < doc2.accessCount : doc1.accessCount > doc2.accessCount
            case .fileSize:
                return filters.sortOrder == .ascending ? 
                    doc1.fileSize < doc2.fileSize : doc1.fileSize > doc2.fileSize
            case .relevance:
                // For now, just use access count as relevance
                return doc1.accessCount > doc2.accessCount
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with filters and analytics
            LibraryFilterSidebar(
                filters: $filters,
                analytics: libraryManager.analytics,
                isVisible: showingFilters
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // Main content area
            VStack(spacing: 0) {
                LibraryToolbar(
                    viewMode: $viewMode,
                    filters: $filters,
                    showingFilters: $showingFilters,
                    documentCount: filteredDocuments.count
                )
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        switch viewMode {
                        case .grid:
                            DocumentGridView(
                                documents: filteredDocuments,
                                selectedDocument: $selectedDocument,
                                onDocumentTap: handleDocumentTap
                            )
                        case .list:
                            DocumentListView(
                                documents: filteredDocuments,
                                selectedDocument: $selectedDocument,
                                onDocumentTap: handleDocumentTap
                            )
                        case .categories:
                            DocumentCategoryView(
                                documents: filteredDocuments,
                                selectedDocument: $selectedDocument,
                                onDocumentTap: handleDocumentTap
                            )
                        case .recent:
                            DocumentRecentView(
                                recentDocuments: libraryManager.analytics.recentlyAdded,
                                mostAccessedDocuments: libraryManager.analytics.mostAccessed,
                                selectedDocument: $selectedDocument,
                                onDocumentTap: handleDocumentTap
                            )
                        }
                    }
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        } detail: {
            // Document preview/detail pane
            if let selectedDocument = selectedDocument {
                DocumentDetailView(document: selectedDocument)
            } else {
                DocumentLibraryEmptyDetail()
            }
        }
        .onAppear {
            libraryManager.loadDocuments()
        }
    }
    
    private func handleDocumentTap(_ document: Document) {
        selectedDocument = document
        libraryManager.recordAccess(for: document)
    }
}

// MARK: - Library Toolbar
struct LibraryToolbar: View {
    @Binding var viewMode: LibraryViewMode
    @Binding var filters: DocumentFilters
    @Binding var showingFilters: Bool
    let documentCount: Int
    
    var body: some View {
        HStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search documents...", text: $filters.searchText)
                    .textFieldStyle(.plain)
                
                if !filters.searchText.isEmpty {
                    Button {
                        filters.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Document count
            Text("\(documentCount) documents")
                .foregroundColor(.secondary)
                .font(.caption)
            
            Spacer()
            
            // Quick filters
            HStack(spacing: 4) {
                Button {
                    filters.showBookmarkedOnly.toggle()
                } label: {
                    Image(systemName: filters.showBookmarkedOnly ? "bookmark.fill" : "bookmark")
                        .foregroundColor(filters.showBookmarkedOnly ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help("Show bookmarked only")
                
                Divider()
                    .frame(height: 16)
                
                // Sort options
                Menu {
                    ForEach(DocumentFilters.SortOption.allCases, id: \.self) { option in
                        Button {
                            if filters.sortBy == option {
                                filters.sortOrder = filters.sortOrder == .ascending ? .descending : .ascending
                            } else {
                                filters.sortBy = option
                                filters.sortOrder = .descending
                            }
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                                if filters.sortBy == option {
                                    Image(systemName: filters.sortOrder.icon)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: filters.sortBy.icon)
                        Image(systemName: filters.sortOrder.icon)
                    }
                    .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .help("Sort options")
                
                Divider()
                    .frame(height: 16)
                
                // View mode toggles
                ForEach(LibraryViewMode.allCases, id: \.self) { mode in
                    Button {
                        viewMode = mode
                    } label: {
                        Image(systemName: mode.icon)
                            .foregroundColor(viewMode == mode ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(mode.rawValue + " view")
                }
                
                Divider()
                    .frame(height: 16)
                
                // Filter sidebar toggle
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(showingFilters ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle filters")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Document Grid View
struct DocumentGridView: View {
    let documents: [Document]
    @Binding var selectedDocument: Document?
    let onDocumentTap: (Document) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(documents) { document in
                DocumentCard(
                    document: document,
                    isSelected: selectedDocument?.id == document.id
                ) {
                    onDocumentTap(document)
                }
            }
        }
        .padding()
    }
}

// MARK: - Document Card
struct DocumentCard: View {
    let document: Document
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and bookmark
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(document.formattedDateAdded)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if document.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            // Metadata badges
            HStack {
                MetadataBadge(
                    text: document.language.rawValue,
                    color: document.language.color,
                    icon: document.language.icon
                )
                
                if document.framework != .none {
                    MetadataBadge(
                        text: document.framework.rawValue,
                        color: document.framework.color
                    )
                }
                
                Spacer()
                
                MetadataBadge(
                    text: document.documentType.rawValue,
                    color: .secondary,
                    icon: document.documentType.icon
                )
            }
            
            // Content preview
            Text(document.contentPreview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Footer with file info
            HStack {
                Text(document.formattedSize)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
                
                Spacer()
                
                if document.accessCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "eye")
                        Text("\(document.accessCount)")
                    }
                    .font(.caption2)
                    .foregroundColor(.tertiary)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
        .frame(height: 180)
    }
}

// MARK: - Metadata Badge
struct MetadataBadge: View {
    let text: String
    let color: Color
    let icon: String?
    
    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

// MARK: - Document List View
struct DocumentListView: View {
    let documents: [Document]
    @Binding var selectedDocument: Document?
    let onDocumentTap: (Document) -> Void
    
    var body: some View {
        LazyVStack(spacing: 1) {
            ForEach(documents) { document in
                DocumentRow(
                    document: document,
                    isSelected: selectedDocument?.id == document.id
                ) {
                    onDocumentTap(document)
                }
            }
        }
    }
}

// MARK: - Document Row
struct DocumentRow: View {
    let document: Document
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Document type icon
            Image(systemName: document.documentType.icon)
                .foregroundColor(document.language.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title and bookmark
                HStack {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if document.isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                // Content preview
                Text(document.contentPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Metadata badges
                HStack {
                    MetadataBadge(
                        text: document.language.rawValue,
                        color: document.language.color,
                        icon: document.language.icon
                    )
                    
                    if document.framework != .none {
                        MetadataBadge(
                            text: document.framework.rawValue,
                            color: document.framework.color
                        )
                    }
                    
                    MetadataBadge(
                        text: document.documentType.rawValue,
                        color: .secondary,
                        icon: document.documentType.icon
                    )
                    
                    Spacer()
                    
                    // File info
                    HStack(spacing: 12) {
                        Text(document.formattedSize)
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        
                        Text(document.formattedDateAdded)
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        
                        if document.accessCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "eye")
                                Text("\(document.accessCount)")
                            }
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Document Category View
struct DocumentCategoryView: View {
    let documents: [Document]
    @Binding var selectedDocument: Document?
    let onDocumentTap: (Document) -> Void
    
    private var groupedDocuments: [(String, [Document])] {
        let groups = [
            ("Languages", Dictionary(grouping: documents, by: \.language)),
            ("Frameworks", Dictionary(grouping: documents, by: \.framework)),
            ("Document Types", Dictionary(grouping: documents, by: \.documentType))
        ]
        
        return groups.compactMap { title, dict in
            let items = dict.flatMap { $0.value }.sorted { $0.title < $1.title }
            return items.isEmpty ? nil : (title, items)
        }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(groupedDocuments, id: \.0) { category, docs in
                CategorySection(
                    title: category,
                    documents: docs,
                    selectedDocument: $selectedDocument,
                    onDocumentTap: onDocumentTap
                )
            }
        }
        .padding()
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let title: String
    let documents: [Document]
    @Binding var selectedDocument: Document?
    let onDocumentTap: (Document) -> Void
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("(\(documents.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                // Document grid for this category
                let columns = [
                    GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 16)
                ]
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(documents) { document in
                        DocumentCard(
                            document: document,
                            isSelected: selectedDocument?.id == document.id
                        ) {
                            onDocumentTap(document)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Document Recent View
struct DocumentRecentView: View {
    let recentDocuments: [Document]
    let mostAccessedDocuments: [Document]
    @Binding var selectedDocument: Document?
    let onDocumentTap: (Document) -> Void
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 32) {
            // Recently Added
            if !recentDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.accentColor)
                        Text("Recently Added")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    let columns = [
                        GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 16)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(recentDocuments) { document in
                            DocumentCard(
                                document: document,
                                isSelected: selectedDocument?.id == document.id
                            ) {
                                onDocumentTap(document)
                            }
                        }
                    }
                }
            }
            
            // Most Accessed
            if !mostAccessedDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.accentColor)
                        Text("Most Accessed")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    let columns = [
                        GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 16)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mostAccessedDocuments) { document in
                            DocumentCard(
                                document: document,
                                isSelected: selectedDocument?.id == document.id
                            ) {
                                onDocumentTap(document)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Filter Sidebar
struct LibraryFilterSidebar: View {
    @Binding var filters: DocumentFilters
    let analytics: DocumentAnalytics
    let isVisible: Bool
    
    var body: some View {
        if isVisible {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Library stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Library Stats")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.accentColor)
                            Text("\(analytics.totalDocuments) documents")
                        }
                        .font(.caption)
                        
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.yellow)
                            Text("\(analytics.bookmarkedCount) bookmarked")
                        }
                        .font(.caption)
                    }
                    
                    Divider()
                    
                    // Language filters
                    FilterSection(
                        title: "Languages",
                        icon: "curlybraces",
                        options: DocumentLanguage.allCases,
                        selectedOptions: $filters.selectedLanguages,
                        distribution: analytics.languageDistribution
                    )
                    
                    // Framework filters
                    FilterSection(
                        title: "Frameworks",
                        icon: "gear",
                        options: DocumentFramework.allCases.filter { $0 != .none },
                        selectedOptions: $filters.selectedFrameworks,
                        distribution: analytics.frameworkDistribution
                    )
                    
                    // Document type filters
                    FilterSection(
                        title: "Document Types",
                        icon: "doc",
                        options: DocumentType.allCases.filter { $0 != .unknown },
                        selectedOptions: $filters.selectedTypes,
                        distribution: analytics.typeDistribution
                    )
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

// MARK: - Filter Section
struct FilterSection<T: Hashable & RawRepresentable & CaseIterable>: View where T.RawValue == String {
    let title: String
    let icon: String
    let options: [T]
    @Binding var selectedOptions: Set<T>
    let distribution: [T: Int]
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        let count = distribution[option] ?? 0
                        if count > 0 {
                            Button {
                                if selectedOptions.contains(option) {
                                    selectedOptions.remove(option)
                                } else {
                                    selectedOptions.insert(option)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: selectedOptions.contains(option) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedOptions.contains(option) ? .accentColor : .secondary)
                                    
                                    Text(option.rawValue)
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .font(.caption2)
                                        .foregroundColor(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
}
                
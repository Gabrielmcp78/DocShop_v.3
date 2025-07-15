import SwiftUI

struct DocumentTableOfContentsView: View {
    @ObservedObject private var library = DocLibraryIndex.shared
    @State private var selectedDocument: DocumentMetaData?
    @State private var searchText = ""
    @State private var organizationMode: OrganizationMode = .company
    @State private var expandedSections: Set<String> = []
    
    enum OrganizationMode: String, CaseIterable {
        case company = "Company"
        case language = "Language" 
        case contentType = "Type"
        case dateImported = "Date"
        
        var displayName: String { rawValue }
        var icon: String {
            switch self {
            case .company: return "building.2"
            case .language: return "chevron.left.forwardslash.chevron.right"
            case .contentType: return "doc.text"
            case .dateImported: return "calendar"
            }
        }
    }
    
    var organizedDocuments: [String: [DocumentMetaData]] {
        let documents = searchText.isEmpty ? library.documents : 
            library.documents.filter { doc in
                doc.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                doc.sourceURL.localizedCaseInsensitiveContains(searchText) ||
                (doc.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        
        var grouped: [String: [DocumentMetaData]] = [:]
        
        for document in documents {
            let key: String
            switch organizationMode {
            case .company:
                key = extractCompany(from: document.sourceURL)
            case .language:
                key = extractLanguage(from: document.tagsArray)
            case .contentType:
                key = document.contentType.displayName
            case .dateImported:
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                key = formatter.string(from: document.dateImported)
            }
            
            grouped[key, default: []].append(document)
        }
        
        // Sort documents within each group by title
        for key in grouped.keys {
            grouped[key]?.sort { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
        }
        
        return grouped
    }
    
    var sortedSectionKeys: [String] {
        return organizedDocuments.keys.sorted { key1, key2 in
            // Put "Unknown" or "General" at the end
            if key1 == "Unknown" || key1 == "General" { return false }
            if key2 == "Unknown" || key2 == "General" { return true }
            return key1.localizedCaseInsensitiveCompare(key2) == .orderedAscending
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Table of Contents Sidebar
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                organizationControls
                Divider()
                tableOfContentsSection
            }
            .frame(width: selectedDocument == nil ? .infinity : 350)
            .background(.ultraThinMaterial)
            
            if let selectedDocument = selectedDocument {
                Divider()
                DocumentDetailView(document: selectedDocument)
                    .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDocument != nil)
        .onAppear {
            // Auto-expand first few sections by default
            let firstSections = Array(sortedSectionKeys.prefix(3))
            expandedSections = Set(firstSections)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Documentation")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
            Button(action: { library.refreshLibrary() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var organizationControls: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
            
            HStack {
                Text("Group by:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Organization", selection: $organizationMode) {
                    ForEach(OrganizationMode.allCases, id: \.self) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var tableOfContentsSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedSectionKeys, id: \.self) { sectionKey in
                    sectionView(for: sectionKey)
                }
            }
        }
    }
    
    private func sectionView(for sectionKey: String) -> some View {
        let documents = organizedDocuments[sectionKey] ?? []
        let isExpanded = expandedSections.contains(sectionKey)
        
        return VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedSections.remove(sectionKey)
                    } else {
                        expandedSections.insert(sectionKey)
                    }
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                    
                    Image(systemName: iconForSection(sectionKey))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .frame(width: 16)
                    
                    Text(sectionKey)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(documents.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Section Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(documents, id: \.id) { document in
                        documentRow(document)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Divider()
                .padding(.leading)
        }
    }
    
    private func documentRow(_ document: DocumentMetaData) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDocument = document
                var updatedDoc = document
                updatedDoc.recordAccess()
                library.updateDocument(updatedDoc)
            }
        }) {
            HStack(alignment: .top, spacing: 8) {
                // Document type icon
                Image(systemName: iconForDocument(document))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.displayTitle)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let summary = document.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text(document.formattedDate)
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        
                        if document.accessCount > 0 {
                            Spacer()
                            Text("↗ \(document.accessCount)")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }
                    }
                }
                
                Spacer()
                
                if document.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.leading, 24) // Indent under section
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(selectedDocument?.id == document.id ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    // MARK: - Helper Functions
    
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
        
        // Extract domain name as fallback
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
    
    private func iconForSection(_ sectionKey: String) -> String {
        switch organizationMode {
        case .company:
            switch sectionKey.lowercased() {
            case "apple": return "apple.logo"
            case "google": return "globe"
            case "microsoft": return "microsoft.logo"
            case "github": return "chevron.left.forwardslash.chevron.right"
            case "amazon": return "cart"
            default: return "building.2"
            }
        case .language:
            return "chevron.left.forwardslash.chevron.right"
        case .contentType:
            return "doc.text"
        case .dateImported:
            return "calendar"
        }
    }
    
    private func iconForDocument(_ document: DocumentMetaData) -> String {
        switch document.contentType {
        case .markdown: return "doc.text"
        case .html: return "globe"
        case .pdf: return "doc.richtext"
        default: return "doc"
        }
    }
}

#Preview {
    DocumentTableOfContentsView()
}
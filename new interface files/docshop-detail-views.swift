import SwiftUI

// MARK: - Document Detail View
struct DocumentDetailView: View {
    let document: Document
    @State private var showingTableOfContents = true
    @State private var selectedTOCItem: TOCItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with document metadata
            DocumentDetailHeader(document: document)
            
            Divider()
            
            HStack(spacing: 0) {
                // Table of Contents Sidebar
                if showingTableOfContents && !document.tableOfContents.isEmpty {
                    TableOfContentsView(
                        items: document.tableOfContents,
                        selectedItem: $selectedTOCItem
                    )
                    .frame(width: 250)
                    
                    Divider()
                }
                
                // Main content area
                ScrollView {
                    DocumentContentView(
                        content: document.content,
                        selectedTOCItem: selectedTOCItem
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(document.title)
        .navigationSubtitle(document.formattedDateAdded)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingTableOfContents.toggle()
                } label: {
                    Image(systemName: "list.bullet.indent")
                }
                .help("Toggle Table of Contents")
                
                Button {
                    // TODO: Export document
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export Document")
                
                Button {
                    // TODO: Edit document
                } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit Document")
            }
        }
    }
}

// MARK: - Document Detail Header
struct DocumentDetailHeader: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // Title and bookmark
                    HStack {
                        Text(document.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if document.isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Spacer()
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
                        
                        MetadataBadge(
                            text: document.documentType.rawValue,
                            color: .secondary,
                            icon: document.documentType.icon
                        )
                        
                        Spacer()
                    }
                    
                    // Tags
                    if !document.tags.isEmpty {
                        HStack {
                            ForEach(Array(document.tags.prefix(5)), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            if document.tags.count > 5 {
                                Text("+\(document.tags.count - 5) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Document stats
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(document.formattedDateAdded)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "doc")
                        Text(document.formattedSize)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if document.accessCount > 0 {
                        HStack {
                            Image(systemName: "eye")
                            Text("\(document.accessCount) views")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    if let lastAccessed = document.lastAccessed {
                        HStack {
                            Image(systemName: "clock")
                            Text("Last: \(RelativeDateTimeFormatter().localizedString(for: lastAccessed, relativeTo: Date()))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Table of Contents View
struct TableOfContentsView: View {
    let items: [TOCItem]
    @Binding var selectedItem: TOCItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Table of Contents")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                Spacer()
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(items, id: \.self) { item in
                        TOCItemView(
                            item: item,
                            isSelected: selectedItem == item
                        ) {
                            selectedItem = item
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - TOC Item View
struct TOCItemView: View {
    let item: TOCItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Text(item.indentedTitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let lineNumber = item.lineNumber {
                    Text("\(lineNumber)")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Content View
struct DocumentContentView: View {
    let content: String
    let selectedTOCItem: TOCItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Content with syntax highlighting (simplified)
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Empty Detail View
struct DocumentLibraryEmptyDetail: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Select a Document")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a document from the library to view its contents")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - Document Library Manager
@MainActor
class DocumentLibraryManager: ObservableObject {
    @Published var documents: [Document] = []
    @Published var analytics: DocumentAnalytics = DocumentAnalytics(
        totalDocuments: 0,
        languageDistribution: [:],
        frameworkDistribution: [:],
        typeDistribution: [:],
        recentlyAdded: [],
        mostAccessed: [],
        bookmarkedCount: 0
    )
    
    private let contentAnalyzer = DocumentContentAnalyzer()
    
    func loadDocuments() {
        // TODO: Load documents from storage
        // For now, create sample data
        loadSampleDocuments()
        updateAnalytics()
    }
    
    func recordAccess(for document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index].accessCount += 1
            documents[index].lastAccessed = Date()
            updateAnalytics()
        }
    }
    
    func toggleBookmark(for document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index].isBookmarked.toggle()
            updateAnalytics()
        }
    }
    
    private func updateAnalytics() {
        analytics = DocumentAnalytics.from(documents: documents)
    }
    
    private func loadSampleDocuments() {
        documents = [
            Document(
                title: "SwiftUI Navigation and Routing",
                content: "# SwiftUI Navigation\n\nNavigationView and NavigationStack provide powerful navigation capabilities...",
                filePath: "/docs/swiftui-nav.md",
                dateAdded: Date().addingTimeInterval(-86400 * 7),
                dateModified: Date().addingTimeInterval(-86400 * 2),
                fileSize: 15420,
                language: .swift,
                framework: .swiftui,
                documentType: .guide,
                tags: ["navigation", "routing", "ios"],
                tableOfContents: [
                    TOCItem(title: "NavigationView Basics", level: 1, lineNumber: 5),
                    TOCItem(title: "NavigationStack", level: 1, lineNumber: 25),
                    TOCItem(title: "Deep Linking", level: 2, lineNumber: 40)
                ],
                isBookmarked: true,
                accessCount: 15,
                lastAccessed: Date().addingTimeInterval(-3600)
            ),
            Document(
                title: "Python Async/Await Patterns",
                content: "# Asynchronous Programming in Python\n\nAsync/await syntax makes asynchronous programming more readable...",
                filePath: "/docs/python-async.md",
                dateAdded: Date().addingTimeInterval(-86400 * 3),
                dateModified: Date().addingTimeInterval(-86400),
                fileSize: 8930,
                language: .python,
                framework: .none,
                documentType: .tutorial,
                tags: ["async", "concurrency", "performance"],
                tableOfContents: [
                    TOCItem(title: "Introduction to Async", level: 1, lineNumber: 3),
                    TOCItem(title: "Event Loops", level: 1, lineNumber: 20),
                    TOCItem(title: "Common Patterns", level: 2, lineNumber: 35)
                ],
                isBookmarked: false,
                accessCount: 8,
                lastAccessed: Date().addingTimeInterval(-7200)
            ),
            Document(
                title: "React Hooks API Reference",
                content: "# React Hooks\n\nHooks are functions that let you 'hook into' React state and lifecycle features...",
                filePath: "/docs/react-hooks.md",
                dateAdded: Date().addingTimeInterval(-86400 * 14),
                dateModified: Date().addingTimeInterval(-86400 * 5),
                fileSize: 22150,
                language: .javascript,
                framework: .react,
                documentType: .apiReference,
                tags: ["hooks", "state", "effects"],
                tableOfContents: [
                    TOCItem(title: "useState", level: 1, lineNumber: 8),
                    TOCItem(title: "useEffect", level: 1, lineNumber: 28),
                    TOCItem(title: "Custom Hooks", level: 1, lineNumber: 55)
                ],
                isBookmarked: true,
                accessCount: 32,
                lastAccessed: Date().addingTimeInterval(-1800)
            )
        ]
    }
}

// MARK: - Document Content Analyzer
class DocumentContentAnalyzer {
    func analyzeContent(_ content: String, filePath: String) -> (DocumentLanguage, DocumentFramework, DocumentType, Set<String>, [TOCItem]) {
        let language = detectLanguage(content: content, filePath: filePath)
        let framework = detectFramework(content: content, language: language)
        let documentType = detectDocumentType(content: content)
        let tags = extractTags(content: content)
        let toc = extractTableOfContents(content: content)
        
        return (language, framework, documentType, tags, toc)
    }
    
    private func detectLanguage(content: String, filePath: String) -> DocumentLanguage {
        let lowercaseContent = content.lowercased()
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        
        // Check file extension first
        switch fileExtension {
        case "swift": return .swift
        case "py": return .python
        case "js": return .javascript
        case "ts": return .typescript
        case "go": return .go
        case "rs": return .rust
        case "java": return .java
        case "cs": return .csharp
        case "cpp", "cc", "cxx": return .cpp
        case "rb": return .ruby
        case "php": return .php
        case "html": return .html
        case "css": return .css
        case "md": return .markdown
        case "sh", "bash": return .shell
        default: break
        }
        
        // Check content patterns
        if lowercaseContent.contains("import swiftui") || lowercaseContent.contains("func ") {
            return .swift
        } else if lowercaseContent.contains("def ") || lowercaseContent.contains("import ") {
            return .python
        } else if lowercaseContent.contains("function ") || lowercaseContent.contains("const ") {
            return .javascript
        }
        
        return .unknown
    }
    
    private func detectFramework(content: String, language: DocumentLanguage) -> DocumentFramework {
        let lowercaseContent = content.lowercased()
        
        switch language {
        case .swift:
            if lowercaseContent.contains("swiftui") { return .swiftui }
            if lowercaseContent.contains("uikit") { return .uikit }
        case .javascript, .typescript:
            if lowercaseContent.contains("react") { return .react }
            if lowercaseContent.contains("angular") { return .angular }
            if lowercaseContent.contains("vue") { return .vue }
            if lowercaseContent.contains("next.js") { return .nextjs }
        case .python:
            if lowercaseContent.contains("django") { return .django }
            if lowercaseContent.contains("flask") { return .flask }
        default:
            break
        }
        
        return .none
    }
    
    private func detectDocumentType(content: String) -> DocumentType {
        let lowercaseContent = content.lowercased()
        
        if lowercaseContent.contains("api") && lowercaseContent.contains("reference") {
            return .apiReference
    private func detectDocumentType(content: String) -> DocumentType {
        let lowercaseContent = content.lowercased()
        
        if lowercaseContent.contains("api") && lowercaseContent.contains("reference") {
            return .apiReference
        } else if lowercaseContent.contains("tutorial") || lowercaseContent.contains("step by step") {
            return .tutorial
        } else if lowercaseContent.contains("guide") || lowercaseContent.contains("how to") {
            return .guide
        } else if lowercaseContent.contains("example") || lowercaseContent.contains("sample") {
            return .codeExample
        } else if lowercaseContent.contains("troubleshoot") || lowercaseContent.contains("error") {
            return .troubleshooting
        } else if lowercaseContent.contains("changelog") || lowercaseContent.contains("version") {
            return .changelog
        } else if lowercaseContent.contains("readme") {
            return .readme
        } else if lowercaseContent.contains("cheat") || lowercaseContent.contains("quick reference") {
            return .cheatSheet
        } else if lowercaseContent.contains("specification") || lowercaseContent.contains("spec") {
            return .specification
        }
        
        return .documentation
    }
    
    private func extractTags(content: String) -> Set<String> {
        var tags = Set<String>()
        let lowercaseContent = content.lowercased()
        
        // Common programming concepts
        let concepts = [
            "async", "await", "concurrency", "performance", "optimization",
            "networking", "database", "api", "authentication", "security",
            "testing", "debugging", "architecture", "design patterns",
            "state management", "navigation", "ui", "animation", "gesture"
        ]
        
        for concept in concepts {
            if lowercaseContent.contains(concept) {
                tags.insert(concept)
            }
        }
        
        // Extract hashtags if present
        let hashtagPattern = #"#(\w+)"#
        if let regex = try? NSRegularExpression(pattern: hashtagPattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let range = Range(match.range(at: 1), in: content) {
                    tags.insert(String(content[range]))
                }
            }
        }
        
        return tags
    }
    
    private func extractTableOfContents(content: String) -> [TOCItem] {
        var tocItems: [TOCItem] = []
        let lines = content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Markdown headers
            if trimmedLine.hasPrefix("#") {
                let level = trimmedLine.prefix(while: { $0 == "#" }).count
                let title = String(trimmedLine.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                if !title.isEmpty {
                    tocItems.append(TOCItem(title: title, level: level, lineNumber: index + 1))
                }
            }
            // Alternative header formats
            else if !trimmedLine.isEmpty && lines.indices.contains(index + 1) {
                let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                if nextLine.allSatisfy({ $0 == "=" }) && nextLine.count >= 3 {
                    tocItems.append(TOCItem(title: trimmedLine, level: 1, lineNumber: index + 1))
                } else if nextLine.allSatisfy({ $0 == "-" }) && nextLine.count >= 3 {
                    tocItems.append(TOCItem(title: trimmedLine, level: 2, lineNumber: index + 1))
                }
            }
        }
        
        return tocItems
    }
}

// MARK: - Document Import and Auto-Categorization
extension DocumentLibraryManager {
    func importDocument(from url: URL) async throws -> Document {
        let content = try String(contentsOf: url)
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        let dateModified = fileAttributes[.modificationDate] as? Date ?? Date()
        
        let (language, framework, documentType, tags, toc) = contentAnalyzer.analyzeContent(
            content,
            filePath: url.path
        )
        
        let document = Document(
            title: url.deletingPathExtension().lastPathComponent,
            content: content,
            filePath: url.path,
            dateAdded: Date(),
            dateModified: dateModified,
            fileSize: fileSize,
            language: language,
            framework: framework,
            documentType: documentType,
            tags: tags,
            tableOfContents: toc,
            isBookmarked: false,
            accessCount: 0,
            lastAccessed: nil
        )
        
        documents.append(document)
        updateAnalytics()
        
        return document
    }
    
    func bulkImport(from urls: [URL]) async throws -> [Document] {
        var importedDocuments: [Document] = []
        
        for url in urls {
            do {
                let document = try await importDocument(from: url)
                importedDocuments.append(document)
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }
        
        return importedDocuments
    }
    
    func refreshDocumentMetadata(_ document: Document) async {
        let (language, framework, documentType, tags, toc) = contentAnalyzer.analyzeContent(
            document.content,
            filePath: document.filePath
        )
        
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index].language = language
            documents[index].framework = framework
            documents[index].documentType = documentType
            documents[index].tags = tags
            documents[index].tableOfContents = toc
            updateAnalytics()
        }
    }
}

// MARK: - Search and Filtering Extensions
extension DocumentLibraryManager {
    func searchDocuments(query: String) -> [Document] {
        guard !query.isEmpty else { return documents }
        
        return documents.filter { document in
            document.searchableText.localizedCaseInsensitiveContains(query)
        }.sorted { doc1, doc2 in
            // Simple relevance scoring based on title matches
            let title1Score = doc1.title.localizedCaseInsensitiveContains(query) ? 1 : 0
            let title2Score = doc2.title.localizedCaseInsensitiveContains(query) ? 1 : 0
            
            if title1Score != title2Score {
                return title1Score > title2Score
            }
            
            // Fall back to access count
            return doc1.accessCount > doc2.accessCount
        }
    }
    
    func getDocumentsByLanguage(_ language: DocumentLanguage) -> [Document] {
        documents.filter { $0.language == language }
    }
    
    func getDocumentsByFramework(_ framework: DocumentFramework) -> [Document] {
        documents.filter { $0.framework == framework }
    }
    
    func getDocumentsByType(_ type: DocumentType) -> [Document] {
        documents.filter { $0.documentType == type }
    }
    
    func getBookmarkedDocuments() -> [Document] {
        documents.filter(\.isBookmarked)
    }
    
    func getRecentlyAccessedDocuments(limit: Int = 10) -> [Document] {
        documents
            .filter { $0.lastAccessed != nil }
            .sorted { $0.lastAccessed! > $1.lastAccessed! }
            .prefix(limit)
            .map { $0 }
    }
    
    func getMostAccessedDocuments(limit: Int = 10) -> [Document] {
        documents
            .filter { $0.accessCount > 0 }
            .sorted { $0.accessCount > $1.accessCount }
            .prefix(limit)
            .map { $0 }
    }
}
            
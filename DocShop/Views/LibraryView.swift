import SwiftUI

struct LibraryView: View {
    @ObservedObject private var library = DocLibraryIndex.shared
    @State private var selectedDocument: DocumentMetaData?
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var sortOption: SortOption = .dateImported
    @State private var showFavoritesOnly = false
    @State private var showingTagEditor = false
    @Namespace private var animation

    var filteredDocuments: [DocumentMetaData] {
        var documents = library.documents
        if !searchText.isEmpty {
            documents = documents.filter { doc in
                doc.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                doc.sourceURL.localizedCaseInsensitiveContains(searchText) ||
                (doc.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                doc.tagsArray.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        if let selectedTag = selectedTag {
            documents = documents.filter { $0.tags?.contains(selectedTag) ?? false }
        }
        if showFavoritesOnly {
            documents = documents.filter { $0.isFavorite }
        }
        switch sortOption {
        case .title: documents.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .dateImported: documents.sort { $0.dateImported > $1.dateImported }
        case .dateAccessed: documents.sort { ($0.dateLastAccessed ?? .distantPast) > ($1.dateLastAccessed ?? .distantPast) }
        case .fileSize: documents.sort { $0.fileSize > $1.fileSize }
        case .accessCount: documents.sort { $0.accessCount > $1.accessCount }
        }
        return documents
    }

    var allTags: [String] {
        let allTagSets = library.documents.compactMap { $0.tags }
        let combined = Set(allTagSets.flatMap { $0 })
        return Array(combined).sorted()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                filterSection
                Divider().padding(.bottom, 2)
                documentListSection
                if let error = library.lastError {
                    errorSection(error)
                }
            }
            .frame(maxWidth: selectedDocument == nil ? .infinity : 420)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 8)
            .padding([.top, .bottom, .leading], 16)
            .padding(.trailing, 8)
            .glassy()

            if let selectedDocument = selectedDocument {
                Divider()
                DocumentDetailView(document: selectedDocument)
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: selectedDocument.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.5), value: selectedDocument != nil)
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView()
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Document Library")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Button(action: { library.refreshLibrary() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .help("Refresh Library")
            Button(action: { showingTagEditor = true }) {
                Image(systemName: "tag")
            }
            .buttonStyle(.bordered)
            .help("Manage Tags")
        }
        .padding([.top, .horizontal])
    }

    private var filterSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search documents...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    Button(action: { showFavoritesOnly.toggle() }) {
                        HStack {
                            Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            Text("Favorites")
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(showFavoritesOnly ? .red : .primary)
                    if !allTags.isEmpty {
                        Picker("Tag", selection: $selectedTag) {
                            Text("All Tags").tag(String?.none)
                            ForEach(allTags, id: \.self) { tag in
                                Text(tag).tag(String?.some(tag))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 4)
    }

    private var documentListSection: some View {
        Group {
            if library.isLoading {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Loading...").foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredDocuments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text").font(.system(size: 48)).foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No documents in library" : "No matching documents")
                        .font(.headline).foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Import documentation from URLs to get started")
                            .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedDocument) {
                    ForEach(filteredDocuments, id: \.id) { document in
                        EnhancedDocumentRowView(document: document) {
                            withAnimation(.easeInOut(duration: 0.5)) { selectedDocument = document }
                            var updatedDoc = document; updatedDoc.recordAccess(); library.updateDocument(updatedDoc)
                        }
                        .tag(document)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
            Text(error).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct EnhancedDocumentRowView: View {
    let document: DocumentMetaData
    let onTap: () -> Void
    @ObservedObject private var library = DocLibraryIndex.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(document.displayTitle).font(.headline).lineLimit(2)
                Spacer()
                HStack(spacing: 4) {
                    if document.isFavorite {
                        Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                    }
                    if document.isRecentlyAccessed {
                        Image(systemName: "eye.fill").foregroundColor(.blue).font(.caption)
                    }
                    Text(document.contentType.displayName).font(.caption2).padding(.horizontal, 4).padding(.vertical, 1).background(Color.blue.opacity(0.1)).cornerRadius(4)
                    Text(document.importMethod.displayName).font(.caption2).padding(.horizontal, 4).padding(.vertical, 1).background(importMethodColor(for: document.importMethod).opacity(0.1)).foregroundColor(importMethodColor(for: document.importMethod)).cornerRadius(4)
                }
            }
            Text(document.sourceURL).font(.caption).foregroundColor(.secondary).lineLimit(1)
            if !document.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(document.tagsArray.prefix(3), id: \.self) { tag in
                            Text(tag).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.gray.opacity(0.2)).cornerRadius(8)
                        }
                        if document.tagsArray.count > 3 {
                            Text("+\(document.tagsArray.count - 3)").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Imported: \(document.formattedDate)").font(.caption2).foregroundColor(.secondary)
                    if document.accessCount > 0 {
                        Text("Accessed \(document.accessCount) times").font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(document.formattedFileSize).font(.caption2).foregroundColor(.secondary)
                    if let linkCount = document.extractedLinks?.count, linkCount > 0 {
                        Label("\(linkCount)", systemImage: "link").font(.caption2).foregroundColor(.blue)
                    }
                    if document.dateLastAccessed != nil {
                        Text("Last: \(document.formattedLastAccessed)").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            if let summary = document.summary, !summary.isEmpty {
                Text(summary).font(.caption).foregroundColor(.secondary).lineLimit(2).padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button(action: {
                var updatedDoc = document; updatedDoc.toggleFavorite(); library.updateDocument(updatedDoc)
            }) {
                Label(document.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: document.isFavorite ? "heart.slash" : "heart")
            }
            Button("Copy Content") {
                if let content = try? String(contentsOfFile: document.filePath, encoding: .utf8) {
                    let pasteboard = NSPasteboard.general; pasteboard.clearContents(); pasteboard.setString(content, forType: .string)
                }
            }
            Button("Share URL") {
                let pasteboard = NSPasteboard.general; pasteboard.clearContents(); pasteboard.setString(document.sourceURL, forType: .string)
            }
            Button("Open File Location") {
                NSWorkspace.shared.selectFile(document.filePath, inFileViewerRootedAtPath: "")
            }
            Divider()
            Button("Delete", role: .destructive) {
                library.removeDocument(document); try? DocumentStorage.shared.deleteDocument(at: URL(fileURLWithPath: document.filePath))
            }
        }
    }
    private func importMethodColor(for method: ImportMethod) -> Color {
        switch method {
        case .manual: return .blue
        case .update: return .orange
        case .jsRendering: return .purple
        }
    }
}

enum SortOption: String, CaseIterable {
    case title = "title"
    case dateImported = "dateImported"
    case dateAccessed = "dateAccessed"
    case fileSize = "fileSize"
    case accessCount = "accessCount"
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .dateImported: return "Date Added"
        case .dateAccessed: return "Last Accessed"
        case .fileSize: return "File Size"
        case .accessCount: return "Access Count"
        }
    }
}

struct TagEditorView: View {
    @ObservedObject private var library = DocLibraryIndex.shared
    @State private var newTag = ""
    var allTags: [String] {
        let allTagSets = library.documents.compactMap { $0.tags }
        let combined = Set(allTagSets.flatMap { $0 })
        return Array(combined).sorted()
    }
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Manage Tags").font(.title).fontWeight(.bold)
                Text("Tags help organize and find your documents").font(.subheadline).foregroundColor(.secondary)
                HStack {
                    TextField("New tag", text: $newTag).textFieldStyle(.roundedBorder)
                    Button("Add") { newTag = "" }.disabled(newTag.isEmpty)
                }
                if !allTags.isEmpty {
                    Text("Existing Tags").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            Text(tag).font(.caption).padding(.horizontal, 8).padding(.vertical, 4).background(Color.blue.opacity(0.1)).cornerRadius(8)
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    LibraryView()
}

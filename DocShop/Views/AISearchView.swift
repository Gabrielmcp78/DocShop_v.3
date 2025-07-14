import SwiftUI
import VisualEffects
import Combine

// MARK: - AISearchView (Production-Level)

struct AISearchView: View {
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var selectedTab: SearchTab = .all
    @State private var libraryResults: [DocumentMetaData] = []
    @State private var webResults: [WebSearchResult] = []
    @State private var showPreview: Bool = false
    @State private var previewDocument: DocumentMetaData?
    @State private var previewWebResult: WebSearchResult?
    @State private var error: String?
    @ObservedObject private var library = DocLibraryIndex.shared
    @ObservedObject private var aiAnalyzer = AIDocumentAnalyzer.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            searchBarSection
            tabPickerSection
            Divider().padding(.bottom, 2)
            resultsSection
            if let error = error {
                errorSection(error)
            }
        }
        .background(VisualEffectBlur(material: .underWindowBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 8)
        .padding(16)
        .sheet(isPresented: $showPreview) {
            if let doc = previewDocument {
                DocumentDetailView(document: doc)
            } else if let web = previewWebResult {
                WebPreviewView(result: web)
            }
        }
        .onAppear {
            aiAnalyzer.loadModel()
        }
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.purple)
            Text("AI-Powered Search")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Image(systemName: aiAnalyzer.isAIAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(aiAnalyzer.isAIAvailable ? .green : .orange)
        }
        .padding([.top, .horizontal])
    }

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            TextField("Search your docs or the web...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .onSubmit { performSearch() }
            Button(action: performSearch) {
                isSearching ? ProgressView().scaleEffect(0.8) : Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .disabled(searchQuery.isEmpty || isSearching)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var tabPickerSection: some View {
        Picker("Results", selection: $selectedTab) {
            ForEach(SearchTab.allCases, id: \ .self) { tab in
                Text(tab.displayName).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private var resultsSection: some View {
        Group {
            if isSearching {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Searching...").foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if allResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchQuery.isEmpty ? "Enter a query to search" : "No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedResults.compactMap { $0 as? DocumentMetaData }, id: \ .id) { doc in
                            SearchResultCard(document: doc, onPreview: {
                                previewDocument = doc; previewWebResult = nil; showPreview = true
                            })
                        }
                        ForEach(displayedResults.compactMap { $0 as? WebSearchResult }, id: \ .id) { web in
                            WebResultCard(result: web, onPreview: {
                                previewWebResult = web; previewDocument = nil; showPreview = true
                            }, onImport: {
                                importWebResult(web)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
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

    private var allResults: [Any] {
        switch selectedTab {
        case .all: return libraryResults + webResults
        case .library: return libraryResults
        case .web: return webResults
        }
    }

    private var displayedResults: [Any] {
        allResults
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        error = nil
        Task {
            do {
                try await aiAnalyzer.analyze(query: searchQuery)
                library.searchDocuments(query: searchQuery)
                await MainActor.run {
                    libraryResults = library.searchResults
                }
                webResults = try await WebSearchService.shared.search(query: searchQuery)
            } catch {
                self.error = error.localizedDescription
            }
            await MainActor.run {
                isSearching = false
            }
        }
    }

    private func importWebResult(_ result: WebSearchResult) {
        do {
            try DocImporter.importFromWeb(result)
            error = "Imported \(result.title) successfully"
        } catch {
            self.error = "Import failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Types

enum SearchTab: String, CaseIterable {
    case all, library, web
    var displayName: String {
        switch self {
        case .all: return "All"
        case .library: return "Library"
        case .web: return "Web"
        }
    }
}

// NOTE: Ensure that `DocumentMetaData`, `DocLibraryIndex`, `WebSearchService`, `AIDocumentAnalyzer`, and `DocImporter` are fully implemented elsewhere in the project.

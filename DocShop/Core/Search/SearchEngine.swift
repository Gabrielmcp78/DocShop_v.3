import Foundation
import Combine

/// Advanced search engine for DocShop - BMad Implementation Example
class SearchEngine: ObservableObject {
    @Published var searchResults: [DocumentMetaData] = []
    @Published var isSearching: Bool = false
    @Published var searchQuery: String = ""
    @Published var appliedFilters: [SearchFilter] = []
    
    private let library = DocLibraryIndex.shared
    private let storage = DocumentStorage.shared
    private var searchTask: Task<Void, Never>?
    
    enum SearchType {
        case fullText
        case metadata
        case tags
        case combined
    }
    
    struct SearchFilter {
        let type: FilterType
        let value: String
        
        enum FilterType {
            case documentType
            case dateRange
            case fileSize
            case tag
        }
    }
    
    func search(_ query: String, type: SearchType = .combined) {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchQuery = query
        isSearching = true
        
        searchTask = Task {
            await performSearch(query: query, type: type)
        }
    }
    
    @MainActor
    private func performSearch(query: String, type: SearchType) async {
        defer { isSearching = false }
        
        // Get all documents from the library
        let allDocuments = library.documents
        
        // Filter documents based on search query and type
        let filteredDocuments = await filterDocuments(allDocuments, query: query, type: type)
        
        // Apply additional filtering and ranking
        let filteredResults = applyFilters(to: filteredDocuments)
        let rankedResults = rankSearchResults(filteredResults, query: query)
        
        searchResults = rankedResults
    }
    
    private func filterDocuments(_ documents: [DocumentMetaData], query: String, type: SearchType) async -> [DocumentMetaData] {
        let searchTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return documents.filter { document in
            switch type {
            case .fullText:
                return matchesFullText(document: document, terms: searchTerms)
            case .metadata:
                return matchesMetadata(document: document, terms: searchTerms)
            case .tags:
                return matchesTags(document: document, terms: searchTerms)
            case .combined:
                return matchesFullText(document: document, terms: searchTerms) ||
                       matchesMetadata(document: document, terms: searchTerms) ||
                       matchesTags(document: document, terms: searchTerms)
            }
        }
    }
    
    private func matchesFullText(document: DocumentMetaData, terms: [String]) -> Bool {
        // Load document content for full-text search
        guard let content = loadDocumentContent(document: document) else { return false }
        let lowercaseContent = content.lowercased()
        
        return terms.contains { term in
            lowercaseContent.contains(term)
        }
    }
    
    private func matchesMetadata(document: DocumentMetaData, terms: [String]) -> Bool {
        let title = document.title.lowercased()
        let fileType = document.contentType.rawValue.lowercased()
        
        return terms.contains { term in
            title.contains(term) || fileType.contains(term)
        }
    }
    
    private func matchesTags(document: DocumentMetaData, terms: [String]) -> Bool {
        // This will be implemented when the tagging system is added
        let tags = (document.tags ?? []).map { $0.lowercased() }
        
        return terms.contains { term in
            tags.contains { tag in tag.contains(term) }
        }
    }
    
    private func loadDocumentContent(document: DocumentMetaData) -> String? {
        do {
            let fileURL = URL(fileURLWithPath: document.filePath)
            return try storage.loadDocument(at: fileURL)
        } catch {
            print("Failed to load document content for search: \(error)")
            return nil
        }
    }
    
    private func applyFilters(to results: [DocumentMetaData]) -> [DocumentMetaData] {
        var filteredResults = results
        
        for filter in appliedFilters {
            switch filter.type {
            case .documentType:
                filteredResults = filteredResults.filter { $0.contentType.rawValue.lowercased() == filter.value.lowercased() }
            case .fileSize:
                // Implement file size filtering based on document.fileSize
                break
            case .dateRange:
                // Implement date range filtering based on document.dateAdded or lastModified
                break
            case .tag:
                filteredResults = filteredResults.filter { document in
                    (document.tags ?? []).contains { tag in
                        tag.lowercased().contains(filter.value.lowercased())
                    }
                }
            }
        }
    
        return filteredResults
    }
    
    private func rankSearchResults(_ results: [DocumentMetaData], query: String) -> [DocumentMetaData] {
        let queryTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return results.sorted { doc1, doc2 in
            let score1 = calculateRelevanceScore(for: doc1, terms: queryTerms)
            let score2 = calculateRelevanceScore(for: doc2, terms: queryTerms)
            return score1 > score2
        }
    }
    
    private func calculateRelevanceScore(for document: DocumentMetaData, terms: [String]) -> Double {
        var score: Double = 0
        
        let title = document.title.lowercased()
        let content = loadDocumentContent(document: document)?.lowercased() ?? ""
        
        for term in terms {
            // Title matches get highest score
            if title.contains(term) {
                score += 10
            }
            
            // Filename matches get high score (replaced with title)
            if title.contains(term) {
                score += 5
            }
            
            // Content matches get base score
            if !content.isEmpty {
                let contentMatches = content.components(separatedBy: term).count - 1
                score += Double(contentMatches)
            }
        }
        
        // Boost score for recent documents
        let dateModified = document.dateModified ?? Date.distantPast
        let daysSinceModified = Date().timeIntervalSince(dateModified) / (24 * 60 * 60)
        if daysSinceModified < 7 {
            score *= 1.2
        }
        
        return score
    }
    
    func addFilter(_ filter: SearchFilter) {
        appliedFilters.append(filter)
        if !searchQuery.isEmpty {
            search(searchQuery)
        }
    }
    
    func removeFilter(_ filter: SearchFilter) {
        appliedFilters.removeAll { $0.type == filter.type && $0.value == filter.value }
        if !searchQuery.isEmpty {
            search(searchQuery)
        }
    }
    
    func clearFilters() {
        appliedFilters.removeAll()
        if !searchQuery.isEmpty {
            search(searchQuery)
        }
    }
    
    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        isSearching = false
    }
}

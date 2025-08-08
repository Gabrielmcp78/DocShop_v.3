import Foundation
import Combine

/// Proper document search index with full-text search capabilities
class DocumentSearchIndex: ObservableObject {
    static let shared = DocumentSearchIndex()
    
    @Published var searchResults: [DocumentMetaData] = []
    @Published var isIndexing = false
    @Published var indexProgress: Double = 0.0
    
    private var searchIndex: [UUID: SearchableDocument] = [:]
    private var wordIndex: [String: Set<UUID>] = [:]
    private var tagIndex: [String: Set<UUID>] = [:]
    private var urlIndex: [String: Set<UUID>] = [:]
    private let indexQueue = DispatchQueue(label: "search.index", qos: .userInitiated)
    private let logger = DocumentLogger.shared
    
    private init() {}
    
    // MARK: - Public Search Interface
    
    func search(query: String, in documents: [DocumentMetaData]) -> [DocumentMetaData] {
        guard !query.isEmpty else { return documents }
        
        let searchTerms = tokenize(query)
        var scoredResults: [(document: DocumentMetaData, score: Double)] = []
        
        for document in documents {
            let score = calculateRelevanceScore(for: document, searchTerms: searchTerms)
            if score > 0 {
                scoredResults.append((document, score))
            }
        }
        
        // Sort by relevance score (highest first)
        scoredResults.sort { $0.score > $1.score }
        return scoredResults.map { $0.document }
    }
    
    func buildIndex(for documents: [DocumentMetaData]) async {
        await MainActor.run {
            isIndexing = true
            indexProgress = 0.0
        }
        
        indexQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.clearIndex()
            
            let total = documents.count
            for (index, document) in documents.enumerated() {
                self.indexDocument(document)
                
                let progress = Double(index + 1) / Double(total)
                DispatchQueue.main.async {
                    self.indexProgress = progress
                }
            }
            
            DispatchQueue.main.async {
                self.isIndexing = false
                self.logger.info("Search index built for \(documents.count) documents")
            }
        }
    }
    
    func addToIndex(_ document: DocumentMetaData) {
        indexQueue.async { [weak self] in
            self?.indexDocument(document)
        }
    }
    
    func removeFromIndex(_ documentId: UUID) {
        indexQueue.async { [weak self] in
            self?.removeDocumentFromIndex(documentId)
        }
    }
    
    // MARK: - Private Implementation
    
    private func indexDocument(_ document: DocumentMetaData) {
        let searchableDoc = createSearchableDocument(from: document)
        searchIndex[document.id] = searchableDoc
        
        // Index words from title and content
        let allWords = searchableDoc.searchableText
        for word in allWords {
            wordIndex[word, default: Set()].insert(document.id)
        }
        
        // Index tags
        for tag in document.tagsArray {
            let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            tagIndex[normalizedTag, default: Set()].insert(document.id)
        }
        
        // Index URL components
        let urlComponents = extractUrlComponents(from: document.sourceURL)
        for component in urlComponents {
            urlIndex[component, default: Set()].insert(document.id)
        }
    }
    
    private func createSearchableDocument(from document: DocumentMetaData) -> SearchableDocument {
        var searchableText: [String] = []
        
        // Add title words
        searchableText.append(contentsOf: tokenize(document.title))
        
        // Add summary words if available
        if let summary = document.summary {
            searchableText.append(contentsOf: tokenize(summary))
        }
        
        // Add content from file if available
        if let content = loadDocumentContent(from: document.filePath) {
            let contentWords = tokenize(content)
            // Limit content words to prevent index bloat
            searchableText.append(contentsOf: Array(contentWords.prefix(500)))
        }
        
        // Add tags
        searchableText.append(contentsOf: document.tagsArray.map { $0.lowercased() })
        
        return SearchableDocument(
            id: document.id,
            searchableText: searchableText,
            title: document.title,
            summary: document.summary,
            tags: document.tagsArray,
            url: document.sourceURL
        )
    }
    
    private func calculateRelevanceScore(for document: DocumentMetaData, searchTerms: [String]) -> Double {
        guard let searchableDoc = searchIndex[document.id] else {
            // Fallback to basic search if not indexed
            return basicRelevanceScore(for: document, searchTerms: searchTerms)
        }
        
        var score: Double = 0.0
        
        for term in searchTerms {
            // Title matches get highest score
            if document.title.localizedCaseInsensitiveContains(term) {
                score += 10.0
            }
            
            // Tag matches get high score
            if document.tagsArray.contains(where: { $0.localizedCaseInsensitiveContains(term) }) {
                score += 8.0
            }
            
            // URL matches get medium score
            if document.sourceURL.localizedCaseInsensitiveContains(term) {
                score += 5.0
            }
            
            // Summary matches get medium score
            if document.summary?.localizedCaseInsensitiveContains(term) == true {
                score += 4.0
            }
            
            // Content matches get lower score
            let contentMatches = searchableDoc.searchableText.filter { $0.contains(term.lowercased()) }.count
            score += Double(contentMatches) * 0.5
        }
        
        // Boost score for exact phrase matches
        let fullQuery = searchTerms.joined(separator: " ")
        if document.title.localizedCaseInsensitiveContains(fullQuery) {
            score += 15.0
        }
        
        // Boost score for recent documents
        let daysSinceImport = Calendar.current.dateComponents([.day], from: document.dateImported, to: Date()).day ?? 0
        if daysSinceImport < 7 {
            score += 2.0
        }
        
        // Boost score for frequently accessed documents
        score += Double(document.accessCount) * 0.1
        
        return score
    }
    
    private func basicRelevanceScore(for document: DocumentMetaData, searchTerms: [String]) -> Double {
        var score: Double = 0.0
        
        for term in searchTerms {
            if document.title.localizedCaseInsensitiveContains(term) {
                score += 10.0
            }
            if document.sourceURL.localizedCaseInsensitiveContains(term) {
                score += 5.0
            }
            if document.summary?.localizedCaseInsensitiveContains(term) == true {
                score += 4.0
            }
            if document.tagsArray.contains(where: { $0.localizedCaseInsensitiveContains(term) }) {
                score += 8.0
            }
        }
        
        return score
    }
    
    private func tokenize(_ text: String) -> [String] {
        let cleanText = text.lowercased()
            .replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: " ", options: .regularExpression)
        
        return cleanText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 } // Filter out very short words
            .filter { !stopWords.contains($0) }
    }
    
    private func extractUrlComponents(from url: String) -> [String] {
        guard let urlObj = URL(string: url) else { return [] }
        
        var components: [String] = []
        
        if let host = urlObj.host {
            components.append(host.lowercased())
            // Add domain parts
            let domainParts = host.components(separatedBy: ".")
            components.append(contentsOf: domainParts.filter { !$0.isEmpty })
        }
        
        // Add path components
        let pathComponents = urlObj.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        components.append(contentsOf: pathComponents.map { $0.lowercased() })
        
        return components
    }
    
    private func loadDocumentContent(from filePath: String) -> String? {
        do {
            return try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func clearIndex() {
        searchIndex.removeAll()
        wordIndex.removeAll()
        tagIndex.removeAll()
        urlIndex.removeAll()
    }
    
    private func removeDocumentFromIndex(_ documentId: UUID) {
        guard let searchableDoc = searchIndex[documentId] else { return }
        
        // Remove from word index
        for word in searchableDoc.searchableText {
            wordIndex[word]?.remove(documentId)
            if wordIndex[word]?.isEmpty == true {
                wordIndex.removeValue(forKey: word)
            }
        }
        
        // Remove from tag index
        for tag in searchableDoc.tags {
            let normalizedTag = tag.lowercased()
            tagIndex[normalizedTag]?.remove(documentId)
            if tagIndex[normalizedTag]?.isEmpty == true {
                tagIndex.removeValue(forKey: normalizedTag)
            }
        }
        
        // Remove from URL index
        let urlComponents = extractUrlComponents(from: searchableDoc.url)
        for component in urlComponents {
            urlIndex[component]?.remove(documentId)
            if urlIndex[component]?.isEmpty == true {
                urlIndex.removeValue(forKey: component)
            }
        }
        
        searchIndex.removeValue(forKey: documentId)
    }
    
    // Common English stop words to filter out
    private let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
        "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did",
        "will", "would", "could", "should", "may", "might", "can", "this", "that", "these", "those"
    ]
}

// MARK: - Supporting Types

private struct SearchableDocument {
    let id: UUID
    let searchableText: [String]
    let title: String
    let summary: String?
    let tags: [String]
    let url: String
}

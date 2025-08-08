# Agent 3: AI Search & Intelligence Implementation

## Agent Focus: AI-Powered Search, Web Integration, and Intelligent Content Discovery

### System Main Prompt
You are the **AI Search Specialist Agent** responsible for implementing DocShop's AI-powered search capabilities, web search integration, and intelligent content discovery systems. Your role is to transform the placeholder AI search into a production-ready intelligent search platform.

### Core Mission
Transform the non-functional AI search system into a comprehensive search platform that combines local document search, web search integration, AI-powered relevance ranking, and intelligent content recommendations.

## Implementation Tasks

### 1. Implement Real AI Search Engine (CRITICAL - Week 1)

#### Current Issue
```swift
// From AISearchView.swift:
try await aiAnalyzer.analyze(query: searchQuery)  // Does nothing
webResults = try await WebSearchService.shared.search(query: searchQuery)  // Doesn't exist!
```

#### Implementation Required

#### Files to Create/Modify
- `DocShop/Core/WebSearchService.swift` (CREATE)
- `DocShop/Core/AISearchEngine.swift` (CREATE)
- `DocShop/Views/AISearchView.swift` (ENHANCE)

#### Implementation Details
```swift
class WebSearchService: ObservableObject {
    static let shared = WebSearchService()
    
    @Published var isSearching = false
    @Published var searchResults: [WebSearchResult] = []
    
    func search(query: String) async throws -> [WebSearchResult] {
        await MainActor.run { isSearching = true }
        defer { Task { await MainActor.run { isSearching = false } } }
        
        // Implement multiple search providers
        let results = try await searchMultipleProviders(query)
        
        await MainActor.run {
            searchResults = results
        }
        
        return results
    }
    
    private func searchMultipleProviders(_ query: String) async throws -> [WebSearchResult] {
        var allResults: [WebSearchResult] = []
        
        // Search developer documentation sites
        allResults += try await searchAppleDocs(query)
        allResults += try await searchMDNDocs(query)
        allResults += try await searchGitHubDocs(query)
        allResults += try await searchStackOverflow(query)
        
        // Rank and deduplicate results
        return rankAndDeduplicateResults(allResults, for: query)
    }
    
    private func searchAppleDocs(_ query: String) async throws -> [WebSearchResult] {
        let baseURL = "https://developer.apple.com/search/"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "\(baseURL)?q=\(encodedQuery)"
        
        // Implement actual web scraping or API integration
        return try await performWebSearch(url: searchURL, source: .appleDeveloper)
    }
    
    private func searchMDNDocs(_ query: String) async throws -> [WebSearchResult] {
        let baseURL = "https://developer.mozilla.org/en-US/search"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "\(baseURL)?q=\(encodedQuery)"
        
        return try await performWebSearch(url: searchURL, source: .mozillaDeveloper)
    }
}

class AISearchEngine: ObservableObject {
    static let shared = AISearchEngine()
    
    @Published var isAnalyzing = false
    @Published var searchInsights: SearchInsights?
    
    func performIntelligentSearch(_ query: String) async throws -> IntelligentSearchResults {
        await MainActor.run { isAnalyzing = true }
        defer { Task { await MainActor.run { isAnalyzing = false } } }
        
        // Analyze query intent
        let intent = try await analyzeQueryIntent(query)
        
        // Search local documents with AI ranking
        let localResults = try await searchLocalDocuments(query, intent: intent)
        
        // Search web with contextual filtering
        let webResults = try await searchWebWithContext(query, intent: intent)
        
        // Generate search insights
        let insights = try await generateSearchInsights(query, localResults, webResults)
        
        await MainActor.run {
            searchInsights = insights
        }
        
        return IntelligentSearchResults(
            localResults: localResults,
            webResults: webResults,
            insights: insights,
            intent: intent
        )
    }
    
    private func analyzeQueryIntent(_ query: String) async throws -> SearchIntent {
        // Use local AI to understand what user is looking for
        let prompt = """
        Analyze this search query and determine the user's intent:
        Query: "\(query)"
        
        Classify the intent as one of:
        - tutorial: User wants to learn how to do something
        - reference: User wants API documentation or reference material
        - troubleshooting: User has a problem to solve
        - example: User wants code examples or samples
        - concept: User wants to understand a concept or theory
        
        Also extract:
        - Programming language (if any)
        - Framework or technology
        - Difficulty level (beginner, intermediate, advanced)
        - Specific topics or keywords
        """
        
        let response = try await GeminiAPI.generateText(prompt: prompt)
        return parseIntentResponse(response)
    }
}
```

### 2. Implement Semantic Document Search (Week 1-2)

#### Files to Create/Modify
- `DocShop/Core/SemanticSearch.swift` (CREATE)
- `DocShop/Data/DocLibraryIndex.swift` (ENHANCE)

#### Implementation Details
```swift
class SemanticSearch {
    static let shared = SemanticSearch()
    
    private var documentEmbeddings: [UUID: [Float]] = [:]
    private let embeddingCache = EmbeddingCache()
    
    func searchDocuments(_ query: String, in documents: [DocumentMetaData]) async throws -> [SearchResult] {
        // Generate query embedding
        let queryEmbedding = try await generateEmbedding(for: query)
        
        // Calculate similarity scores
        var results: [SearchResult] = []
        
        for document in documents {
            let documentEmbedding = try await getDocumentEmbedding(document)
            let similarity = calculateCosineSimilarity(queryEmbedding, documentEmbedding)
            
            if similarity > 0.3 { // Threshold for relevance
                let result = SearchResult(
                    document: document,
                    relevanceScore: similarity,
                    matchType: .semantic,
                    matchedContent: extractRelevantContent(document, query)
                )
                results.append(result)
            }
        }
        
        // Sort by relevance and apply additional ranking factors
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func generateEmbedding(for text: String) async throws -> [Float] {
        // Use local Apple Intelligence if available
        if AIDocumentAnalyzer.shared.isAIAvailable {
            return try await generateLocalEmbedding(text)
        } else {
            // Fallback to Gemini API
            return try await GeminiAPI.getEmbedding(for: text)
        }
    }
    
    private func calculateCosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
```

### 3. Implement Advanced Search Filters (Week 2)

#### Files to Create/Modify
- `DocShop/Views/SearchFilterView.swift` (CREATE)
- `DocShop/Models/SearchModels.swift` (CREATE)

#### Implementation Details
```swift
struct SearchFilters: Codable {
    var languages: Set<ProgrammingLanguage> = []
    var frameworks: Set<DocumentFramework> = []
    var companies: Set<String> = []
    var contentTypes: Set<DocumentContentType> = []
    var difficultyLevels: Set<DifficultyLevel> = []
    var dateRange: DateRange?
    var hasCodeExamples: Bool = false
    var hasAPIReference: Bool = false
    var minimumQualityScore: Double = 0.0
}

struct SearchFilterView: View {
    @Binding var filters: SearchFilters
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("Filters")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Language filters
                    FilterSection(title: "Languages") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                            ForEach(ProgrammingLanguage.allCases, id: \.self) { language in
                                FilterToggle(
                                    title: language.rawValue.capitalized,
                                    isSelected: filters.languages.contains(language)
                                ) {
                                    if filters.languages.contains(language) {
                                        filters.languages.remove(language)
                                    } else {
                                        filters.languages.insert(language)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Framework filters
                    FilterSection(title: "Frameworks") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                            ForEach(DocumentFramework.allCases, id: \.self) { framework in
                                FilterToggle(
                                    title: framework.rawValue.capitalized,
                                    isSelected: filters.frameworks.contains(framework)
                                ) {
                                    if filters.frameworks.contains(framework) {
                                        filters.frameworks.remove(framework)
                                    } else {
                                        filters.frameworks.insert(framework)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Content type filters
                    FilterSection(title: "Content Type") {
                        VStack(alignment: .leading) {
                            Toggle("Has Code Examples", isOn: $filters.hasCodeExamples)
                            Toggle("Has API Reference", isOn: $filters.hasAPIReference)
                        }
                    }
                    
                    // Quality filter
                    FilterSection(title: "Quality") {
                        VStack(alignment: .leading) {
                            Text("Minimum Quality Score: \(Int(filters.minimumQualityScore * 100))%")
                            Slider(value: $filters.minimumQualityScore, in: 0...1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}
```

### 4. Implement Search Result Ranking (Week 2-3)

#### Files to Create/Modify
- `DocShop/Core/SearchRanking.swift` (CREATE)
- `DocShop/Core/RelevanceScoring.swift` (CREATE)

#### Implementation Details
```swift
class SearchRanking {
    static let shared = SearchRanking()
    
    func rankResults(_ results: [SearchResult], for query: String, with filters: SearchFilters) -> [SearchResult] {
        return results.map { result in
            var rankedResult = result
            rankedResult.finalScore = calculateFinalScore(result, query: query, filters: filters)
            return rankedResult
        }.sorted { $0.finalScore > $1.finalScore }
    }
    
    private func calculateFinalScore(_ result: SearchResult, query: String, filters: SearchFilters) -> Double {
        var score = result.relevanceScore
        
        // Boost for exact title matches
        if result.document.title.localizedCaseInsensitiveContains(query) {
            score *= 1.5
        }
        
        // Boost for recent documents
        let daysSinceImport = Date().timeIntervalSince(result.document.dateImported) / (24 * 60 * 60)
        if daysSinceImport < 30 {
            score *= 1.2
        }
        
        // Boost for high-quality documents
        if let qualityScore = result.document.qualityScore {
            score *= (0.5 + qualityScore * 0.5)
        }
        
        // Boost for documents with code examples (if relevant)
        if query.contains("example") || query.contains("code") {
            if result.document.hasCodeExamples {
                score *= 1.3
            }
        }
        
        // Boost for matching filters
        if !filters.languages.isEmpty {
            if let docLanguage = result.document.detectedLanguage,
               filters.languages.contains(docLanguage) {
                score *= 1.4
            }
        }
        
        if !filters.frameworks.isEmpty {
            if let docFramework = result.document.detectedFramework,
               filters.frameworks.contains(docFramework) {
                score *= 1.4
            }
        }
        
        return score
    }
}
```

### 5. Implement Search Analytics & Learning (Week 3)

#### Files to Create/Modify
- `DocShop/Core/SearchAnalytics.swift` (CREATE)
- `DocShop/Core/SearchLearning.swift` (CREATE)

#### Implementation Details
```swift
class SearchAnalytics: ObservableObject {
    static let shared = SearchAnalytics()
    
    @Published var searchHistory: [SearchQuery] = []
    @Published var popularQueries: [String] = []
    @Published var searchInsights: SearchInsights?
    
    func recordSearch(_ query: String, results: [SearchResult], selectedResult: SearchResult?) {
        let searchQuery = SearchQuery(
            query: query,
            timestamp: Date(),
            resultCount: results.count,
            selectedResult: selectedResult,
            userSatisfaction: nil
        )
        
        searchHistory.append(searchQuery)
        updatePopularQueries()
        learnFromSearch(searchQuery)
    }
    
    func recordUserFeedback(_ query: String, satisfaction: UserSatisfaction) {
        if let index = searchHistory.firstIndex(where: { $0.query == query }) {
            searchHistory[index].userSatisfaction = satisfaction
        }
        
        // Use feedback to improve future searches
        SearchLearning.shared.incorporateFeedback(query, satisfaction)
    }
    
    private func updatePopularQueries() {
        let queryFrequency = Dictionary(grouping: searchHistory) { $0.query }
            .mapValues { $0.count }
        
        popularQueries = queryFrequency
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
}

class SearchLearning {
    static let shared = SearchLearning()
    
    private var queryExpansions: [String: [String]] = [:]
    private var resultPreferences: [String: [String]] = [:]
    
    func suggestQueryExpansions(for query: String) -> [String] {
        var suggestions: [String] = []
        
        // Add learned expansions
        suggestions += queryExpansions[query] ?? []
        
        // Add semantic expansions
        suggestions += generateSemanticExpansions(query)
        
        // Add popular related queries
        suggestions += findRelatedPopularQueries(query)
        
        return Array(Set(suggestions)).prefix(5).map { String($0) }
    }
    
    private func generateSemanticExpansions(_ query: String) -> [String] {
        let expansionMap = [
            "swift": ["swiftui", "ios", "macos", "xcode"],
            "react": ["javascript", "jsx", "component", "hooks"],
            "api": ["rest", "endpoint", "documentation", "reference"],
            "tutorial": ["guide", "example", "getting started", "how to"]
        ]
        
        var expansions: [String] = []
        for (key, values) in expansionMap {
            if query.localizedCaseInsensitiveContains(key) {
                expansions += values
            }
        }
        
        return expansions
    }
}
```

### 6. Implement Search Result Visualization (Week 3-4)

#### Files to Create/Modify
- `DocShop/Views/SearchResultsView.swift` (CREATE)
- `DocShop/Views/SearchInsightsView.swift` (CREATE)

#### Implementation Details
```swift
struct SearchResultsView: View {
    let results: [SearchResult]
    let query: String
    @State private var selectedResult: SearchResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search summary
            HStack {
                Text("\(results.count) results for \"\(query)\"")
                    .font(.headline)
                Spacer()
                Button("Export Results") {
                    exportSearchResults()
                }
            }
            .padding()
            
            // Results list
            List(results, id: \.id) { result in
                SearchResultRow(result: result) {
                    selectedResult = result
                    SearchAnalytics.shared.recordSearch(query, results: results, selectedResult: result)
                }
            }
        }
        .sheet(item: $selectedResult) { result in
            DocumentDetailView(document: result.document)
        }
    }
    
    private func exportSearchResults() {
        // Implement search results export
        let exportData = SearchExport(
            query: query,
            timestamp: Date(),
            results: results
        )
        
        // Save to file or share
        ShareManager.shared.shareSearchResults(exportData)
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.document.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                Text("\(Int(result.relevanceScore * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if let summary = result.matchedContent {
                Text(summary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                if let framework = result.document.detectedFramework {
                    Label(framework.rawValue, systemImage: "hammer")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let language = result.document.detectedLanguage {
                    Label(language.rawValue, systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text(result.document.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
```

## Technical Context

### Existing Framework Assets
- **AIDocumentAnalyzer**: Foundation for AI integration
- **GeminiAPI**: External AI service integration
- **DocLibraryIndex**: Document storage and basic search
- **DocumentProcessor**: Content processing pipeline

### Integration Points
- **Document Processing**: Enhanced metadata feeds better search
- **Project System**: Search results can be added to projects
- **Knowledge Graph**: Search relationships power graph connections
- **UI Components**: Search integrates with all major views

### Success Criteria
1. **Functional AI Search**: Real search results from multiple sources
2. **Semantic Understanding**: AI-powered relevance and intent analysis
3. **Advanced Filtering**: Rich metadata-based filtering options
4. **Learning System**: Search improves based on user behavior
5. **Performance**: Fast search across large document collections

### Code Quality Requirements
- Implement proper async/await patterns
- Add comprehensive error handling and retry logic
- Create efficient caching for embeddings and results
- Write unit tests for all search components
- Monitor and optimize search performance

### Dependencies on Other Agents
- **Agent 1**: Project integration for search-to-project workflow
- **Agent 2**: Enhanced metadata for better search results
- **Agent 4**: Library integration for comprehensive search
- **Agent 5**: UI components for search visualization

## Deliverables

### Week 1
- [ ] Functional web search integration
- [ ] Real AI search engine implementation
- [ ] Basic semantic document search

### Week 2
- [ ] Advanced search filters
- [ ] Search result ranking system
- [ ] Query intent analysis

### Week 3
- [ ] Search analytics and learning
- [ ] Query suggestions and expansions
- [ ] Search performance optimization

### Week 4
- [ ] Search result visualization
- [ ] Integration testing
- [ ] Documentation and handoff

## Branch Strategy
- **Main branch**: `feature/ai-search-implementation`
- **Sub-branches**:
  - `feature/web-search-service`
  - `feature/semantic-search`
  - `feature/search-filters`
  - `feature/search-ranking`

## Testing Strategy
- Unit tests for all search components
- Integration tests with document library
- Performance tests with large result sets
- User experience tests for search workflows
- Accuracy tests for search relevance
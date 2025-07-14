import Foundation
import FoundationModels
import Combine

@MainActor
class AIDocumentAnalyzer: ObservableObject {
    static let shared = AIDocumentAnalyzer()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentAnalysisTask = ""
    @Published var modelAvailability: SystemLanguageModel.Availability = .unavailable(.modelNotReady)
    
    private let model = SystemLanguageModel.default
    private let logger = DocumentLogger.shared
    private let config = DocumentProcessorConfig.shared
    
    private init() {
        updateModelAvailability()
    }
    
    private func updateModelAvailability() {
        modelAvailability = model.availability
        logger.info("AI Model availability: \(modelAvailability)")
    }
    
    var isAIAvailable: Bool {
        model.isAvailable
    }
    
    func analyzeDocument(content: String, sourceURL: String, title: String) async -> DocumentAnalysis? {
        guard isAIAvailable else {
            logger.warning("AI model not available for document analysis")
            return nil
        }
        
        isAnalyzing = true
        currentAnalysisTask = "Analyzing document content..."
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            currentAnalysisTask = ""
            analysisProgress = 0.0
        }
        
        do {
            let session = LanguageModelSession(
                instructions: Instructions("""
                You are an expert documentation analyst. Your role is to analyze technical documentation and extract key information to help developers organize and understand the content.
                
                Always respond with structured data that includes:
                - A concise, descriptive title if the current one is generic
                - A brief 2-3 sentence summary of the main content
                - 3-5 relevant tags that categorize the content
                - A quality score from 1-10 based on completeness and clarity
                - The primary programming language or technology discussed
                
                Focus on technical accuracy and be concise in your responses.
                """)
            )
            
            analysisProgress = 0.3
            currentAnalysisTask = "Generating analysis..."
            
            let analysis = try await session.respond(
                to: """
                Analyze this documentation content:
                
                Title: \(title)
                Source: \(sourceURL)
                Content: \(String(content.prefix(3000)))
                
                Provide a comprehensive analysis focusing on the technical content and its value to developers.
                """,
                generating: DocumentAnalysis.self
            )
            
            analysisProgress = 1.0
            logger.info("Successfully analyzed document: \(title)")
            
            return analysis.content
            
        } catch {
            logger.error("AI document analysis failed: \(error)")
            return nil
        }
    }
    
    func generateSearchSuggestions(for query: String, context: [DocumentMetaData]) async -> [String] {
        guard isAIAvailable else { return [] }
        
        do {
            let contextTitles = context.prefix(10).map { $0.displayTitle }.joined(separator: ", ")
            
            let session = LanguageModelSession(
                instructions: Instructions("""
                You are a search assistant for a documentation library. Generate 5 relevant search suggestions that would help developers find related documentation.
                
                Make suggestions that are:
                - Specific and actionable
                - Related to the user's query
                - Likely to exist in a technical documentation library
                - Progressively more specific or alternative approaches
                """)
            )
            
            let suggestions = try await session.respond(
                to: """
                User query: "\(query)"
                Available documentation includes: \(contextTitles)
                
                Generate 5 search suggestions that would help find relevant documentation.
                """,
                generating: SearchSuggestions.self
            )
            
            return suggestions.content.suggestions
            
        } catch {
            logger.error("Failed to generate search suggestions: \(error)")
            return []
        }
    }
    
    func identifyRelevantLinks(from links: [String], documentContent: String, documentTitle: String) async -> [RelevantLink] {
        guard isAIAvailable else { return [] }
        
        do {
            let linksList = links.prefix(20).joined(separator: "\n")
            
            let session = LanguageModelSession(
                instructions: Instructions("""
                You are a documentation curator. Analyze a list of links found in a document and identify which ones are most relevant for a comprehensive documentation archive.
                
                Prioritize links that are:
                - Technical documentation, guides, or references
                - Related to the main topic of the source document
                - From reputable sources (official docs, established projects)
                - Likely to contain substantial, useful content
                
                Avoid links that are:
                - Navigation elements, footers, or UI components
                - Social media, marketing, or promotional content
                - Downloads, installers, or binary files
                - Broken or placeholder links
                """)
            )
            
            let analysis = try await session.respond(
                to: """
                Source document: "\(documentTitle)"
                Content summary: \(String(documentContent.prefix(500)))
                
                Found links:
                \(linksList)
                
                Identify the most relevant links for documentation archiving and explain why each is valuable.
                """,
                generating: LinkRelevanceAnalysis.self
            )
            
            return analysis.content.relevantLinks
            
        } catch {
            logger.error("Failed to analyze link relevance: \(error)")
            return []
        }
    }
    
    func enhanceDocumentMetadata(_ document: DocumentMetaData, content: String) async -> DocumentMetaData? {
        guard isAIAvailable else { return nil }
        
        do {
            let session = LanguageModelSession(
                instructions: Instructions("""
                You are a metadata enhancement specialist. Improve document metadata by analyzing the content and generating better titles, summaries, and tags.
                
                Focus on:
                - Creating clear, descriptive titles that indicate the content's purpose
                - Writing concise summaries that highlight key information
                - Generating relevant tags that help with categorization and search
                - Identifying the primary technology or programming language
                """)
            )
            
            let enhancement = try await session.respond(
                to: """
                Current title: \(document.displayTitle)
                Current summary: \(document.summary ?? "None")
                Current tags: \(document.tagsArray.joined(separator: ", "))
                
                Content: \(String(content.prefix(2000)))
                
                Enhance this metadata to make the document more discoverable and useful.
                """,
                generating: MetadataEnhancement.self
            )
            
            var enhancedDoc = document
            let result = enhancement.content
            
            if !result.enhancedTitle.isEmpty && result.enhancedTitle != document.title {
                enhancedDoc.title = result.enhancedTitle
            }
            
            if !result.enhancedSummary.isEmpty {
                enhancedDoc.summary = result.enhancedSummary
            }
            
            if !result.suggestedTags.isEmpty {
                enhancedDoc.tags = Set(result.suggestedTags)
            }
            
            if !result.primaryLanguage.isEmpty {
                enhancedDoc.language = result.primaryLanguage
            }
            
            return enhancedDoc
            
        } catch {
            logger.error("Failed to enhance document metadata: \(error)")
            return nil
        }
    }
    
    /// AI-driven decision: Should we continue deep crawling?
    func shouldContinueDeepCrawl(currentLinks: [RelevantLink], crawledURLs: [String], currentContent: String, documentTitle: String) async -> Bool {
        guard isAIAvailable else { return false }
        do {
            let linksList = currentLinks.prefix(20).map { $0.url }.joined(separator: "\n")
            let crawledList = crawledURLs.prefix(50).joined(separator: ", ")
            let session = LanguageModelSession(
                instructions: Instructions("")
            )
            let prompt = """
            You are an expert documentation crawler. Given the following context, decide if there is more valuable documentation to collect by crawling deeper:
            - Current document title: \(documentTitle)
            - Current content summary: \(String(currentContent.prefix(500)))
            - Links found on this page (filtered for relevance):\n\(linksList)
            - URLs already crawled: \(crawledList)
            
            If there are more links that likely lead to additional, uncrawled, and valuable documentation (not just navigation, repeated, or irrelevant pages), respond with YES. If the documentation is already complete or further crawling would be redundant or low-value, respond with NO. Only respond with YES or NO.
            """
            let response = try await session.respond(to: prompt, generating: String.self)
            let answer = response.content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            return answer.hasPrefix("Y")
        } catch {
            logger.error("Failed to determine deep crawl continuation: \(error)")
            return false
        }
    }
}

// MARK: - AI Data Models

@Generable(description: "Analysis of a technical document including quality assessment and categorization")
struct DocumentAnalysis {
    @Guide(description: "An improved, descriptive title for the document")
    var enhancedTitle: String
    
    @Guide(description: "A concise 2-3 sentence summary of the main content and its purpose")
    var summary: String
    
    @Guide(description: "3-5 relevant tags that categorize the technical content")
    var tags: [String]
    
    @Guide(description: "Quality score from 1-10 based on completeness, clarity, and usefulness", .range(1...10))
    var qualityScore: Int
    
    @Guide(description: "Primary programming language or technology discussed")
    var primaryTechnology: String
    
    @Guide(description: "Brief assessment of what makes this documentation valuable")
    var valueAssessment: String
}

@Generable(description: "Search suggestions for finding related documentation")
struct SearchSuggestions {
    @Guide(description: "5 relevant search suggestions that would help find related documentation")
    var suggestions: [String]
}

@Generable(description: "Analysis of link relevance for documentation archiving")
struct LinkRelevanceAnalysis {
    @Guide(description: "Links that are most relevant for documentation archiving")
    var relevantLinks: [RelevantLink]
}

@Generable(description: "A relevant link with explanation of its value")
struct RelevantLink {
    @Guide(description: "The URL of the relevant link")
    var url: String
    
    @Guide(description: "Brief explanation of why this link is valuable for documentation")
    var relevanceReason: String
    
    @Guide(description: "Priority score from 1-10 for crawling this link", .range(1...10))
    var priority: Int
}

@Generable(description: "Enhanced metadata for a document")
struct MetadataEnhancement {
    @Guide(description: "An improved, more descriptive title")
    var enhancedTitle: String
    
    @Guide(description: "A better summary that highlights key information")
    var enhancedSummary: String
    
    @Guide(description: "Relevant tags for categorization and search")
    var suggestedTags: [String]
    
    @Guide(description: "Primary programming language or technology")
    var primaryLanguage: String
}
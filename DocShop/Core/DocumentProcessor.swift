import Foundation
import SwiftSoup
import FoundationModels
import Combine

class DocumentProcessor: ObservableObject {
    static let shared = DocumentProcessor()
    
    @Published var isProcessing = false
    @Published var currentStatus = "Ready"
    @Published var processingProgress: Double = 0.0
    @Published var lastError: String?
    @Published var processingQueue: [ProcessingTask] = []
    
    private let storage = DocumentStorage.shared
    private let library = DocLibraryIndex.shared
    private let config = DocumentProcessorConfig.shared
    private let logger = DocumentLogger.shared
    private let security = SecurityManager.shared
    private let memory = MemoryManager.shared
    private let jsRenderer = JavaScriptRenderer.shared
    private let duplicateHandler = SmartDuplicateHandler.shared
    private let aiAnalyzer = AIDocumentAnalyzer.shared
    
    private var currentTask: Task<Void, Never>?
    private let processingQueue_internal = DispatchQueue(label: "document.processing", qos: .userInitiated)
    private var crawledURLs = Set<String>()
    
    private init() {}
    
    func importDocuments(from urls: [String]) async {
        let tasks = urls.compactMap { urlString -> ProcessingTask? in
            guard let url = URL(string: urlString) else { return nil }
            return ProcessingTask(id: UUID(), url: url, status: .pending)
        }
        
        await MainActor.run {
            processingQueue.append(contentsOf: tasks)
        }
        
        await processQueue()
    }
    
    func importDocument(from urlString: String, forceReimport: Bool = false, importMethod: ImportMethod = .manual) async throws -> DocumentMetaData {
        guard let url = URL(string: urlString) else {
            throw DocumentError.invalidURL(urlString)
        }
        crawledURLs = [] // Reset for each top-level import
        let doc = try await importDocumentWithCrawl(url: url, depth: 0, forceReimport: forceReimport, importMethod: importMethod)
        return doc
    }

    private func importDocumentWithCrawl(url: URL, depth: Int, forceReimport: Bool, importMethod: ImportMethod) async throws -> DocumentMetaData {
        guard !crawledURLs.contains(url.absoluteString) else { throw DocumentError.parsingError("Already crawled: \(url)") }
        crawledURLs.insert(url.absoluteString)
        // Duplicate handling as before
        if !forceReimport {
            let decision = await duplicateHandler.shouldAllowImport(
                url: url,
                importMethod: importMethod,
                jsRenderingEnabled: config.enableJavaScriptRendering
            )
            switch decision {
            case .block(let reason):
                logger.info("Import blocked: \(reason.message)")
                throw DocumentError.duplicateDocument(reason.message)
            case .allow(let reason):
                logger.info("Import allowed: \(reason.message)")
            case .prompt:
                logger.info("Import requires user confirmation but proceeding")
            }
        }
        let document = try await processDocument(url: url, importMethod: importMethod)
        // --- AI-driven deep crawl logic ---
        if let links = document.extractedLinks, !links.isEmpty {
            let filteredLinks = await aiAnalyzer.identifyRelevantLinks(from: links, documentContent: document.summary ?? "", documentTitle: document.title)
            // Ask AI if we should continue crawling deeper
            let shouldContinue = await aiAnalyzer.shouldContinueDeepCrawl(currentLinks: filteredLinks, crawledURLs: Array(crawledURLs), currentContent: document.summary ?? "", documentTitle: document.title)
            if shouldContinue {
                for link in filteredLinks.prefix(15) { // Limit breadth per level
                    guard let nextURL = URL(string: link.url), nextURL.host == url.host else { continue }
                    do {
                        _ = try await importDocumentWithCrawl(url: nextURL, depth: depth + 1, forceReimport: false, importMethod: .update)
                    } catch {
                        logger.warning("Deep crawl failed for \(nextURL): \(error)")
                    }
                }
            }
        }
        return document
    }
    
    private func processQueue() async {
        await MainActor.run { self.isProcessing = true }
        defer { Task { await MainActor.run { self.isProcessing = false } } }
        
        while true {
            var nextTask: ProcessingTask?
            await MainActor.run {
                nextTask = processingQueue.first(where: { $0.status == .pending })
            }
            guard let task = nextTask else { break }
            
            await updateTaskStatus(taskId: task.id, status: .processing)
            
            do {
                let document = try await processDocument(url: task.url, importMethod: .manual)
                await updateTaskStatus(taskId: task.id, status: .completed)
                logger.info("Successfully processed document: \(document.title)")
            } catch {
                await updateTaskStatus(taskId: task.id, status: .failed(error))
                logger.error("Failed to process document from \(task.url): \(error)")
            }
        }
        
        await MainActor.run {
            self.currentStatus = "Ready"
            self.processingProgress = 0.0
        }
    }
    
    private func processDocument(url: URL, importMethod: ImportMethod = .manual) async throws -> DocumentMetaData {
        await MainActor.run {
            self.currentStatus = "Validating URL..."
            self.processingProgress = 0.1
        }
        
        try validateURL(url)
        
        await MainActor.run {
            self.currentStatus = "Fetching content..."
            self.processingProgress = 0.2
        }
        
        let (data, response) = try await fetchContent(from: url)
        
        // Check if we need JavaScript rendering
        let initialContent = String(data: data, encoding: .utf8) ?? ""
        let needsJSRendering = config.enableJavaScriptRendering &&
                              (config.autoDetectJSRequirement ?
                               jsRenderer.shouldUseJavaScriptRendering(for: url, content: initialContent) :
                               jsRenderer.isJavaScriptRequired(for: url))
        
        var finalData = data
        if needsJSRendering {
            await MainActor.run {
                self.currentStatus = "Rendering JavaScript content..."
                self.processingProgress = 0.3
            }
            
            do {
                let renderedHTML = try await jsRenderer.renderPage(url: url)
                finalData = renderedHTML.data(using: .utf8) ?? data
                logger.info("Successfully rendered JavaScript content for \(url.absoluteString)")
            } catch {
                logger.warning("JavaScript rendering failed, using static content: \(error)")
                // Fall back to static content
            }
        }
        
        await MainActor.run {
            self.currentStatus = "Parsing HTML..."
            self.processingProgress = 0.4
        }
        
        let (title, content, extractedLinks) = try await parseHTMLEnhanced(data: finalData, url: url)
        
        await MainActor.run {
            self.currentStatus = "Converting to Markdown..."
            self.processingProgress = 0.6
        }
        
        let markdown = try await convertToMarkdown(
            html: content,
            title: title,
            sourceURL: url
        )
        
        await MainActor.run {
            self.currentStatus = "Saving document..."
            self.processingProgress = 0.8
        }
        
        var document = try await saveDocument(
            title: title,
            content: markdown,
            sourceURL: url,
            response: response,
            extractedLinks: extractedLinks,
            importMethod: importMethod,
            jsRenderingUsed: needsJSRendering
        )
        
        // AI-powered document enhancement
        if aiAnalyzer.isAIAvailable {
            await MainActor.run {
                self.currentStatus = "Enhancing with AI analysis..."
                self.processingProgress = 0.9
            }
            
            if let enhancedDoc = await aiAnalyzer.enhanceDocumentMetadata(document, content: markdown) {
                document = enhancedDoc
                library.updateDocument(document)
                logger.info("Document enhanced with AI analysis")
            }
        }
        
        await MainActor.run {
            self.currentStatus = "Complete"
            self.processingProgress = 1.0
        }
        
        await resetStatusAfterDelay()
        
        return document
    }
    
    private func validateURL(_ url: URL) throws {
        try security.validateURL(url)
        
        let blockedDomains = config.blockedDomains
        if blockedDomains.contains(where: { url.host?.contains($0) == true }) {
            throw DocumentError.blockedDomain(url.host ?? "")
        }
    }
    
    private func fetchContent(from url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = config.networkTimeout
        request.setValue("DocShop/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        // Add retry logic
        var lastError: Error?
        
        for attempt in 1...config.maxRetryAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw DocumentError.httpError(httpResponse.statusCode)
                    }
                }
                
                guard !data.isEmpty else {
                    throw DocumentError.emptyResponse
                }
                
                try security.validateContentSize(data.count)
                
                return (data, response)
                
            } catch let error as URLError where attempt < config.maxRetryAttempts {
                lastError = error
                logger.warning("Fetch attempt \(attempt) failed: \(error.localizedDescription), retrying...")
                
                // Exponential backoff
                let delay = config.retryDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                throw error
            }
        }
        
        throw lastError ?? DocumentError.networkError(URLError(.unknown))
    }
    
    // MARK: - Enhanced HTML Parsing
    private func parseHTML(data: Data, url: URL) async throws -> (title: String, content: String, extractedLinks: [String]) {
        let html = String(decoding: data, as: UTF8.self)
        let doc = try SwiftSoup.parse(html)
        
        // Extract title
        let title = try extractTitle(from: doc, url: url)
        
        // Extract and clean main content
        let contentElement = try extractMainContent(from: doc)
        try removeNavigationElements(from: contentElement)
        try cleanupContent(contentElement)
        
        // Extract links from the entire document (not only main content)
        let extractedLinks = try extractLinks(from: doc, baseURL: url)
        
        return (title, try contentElement.outerHtml(), extractedLinks)
    }
    
    private func extractTitle(from doc: Document, url: URL) throws -> String {
        // Prefer <title> tag
        let title = try doc.title()
        if !title.isEmpty {
            return title
        }
        // Try meta og:title or twitter:title
        if let ogTitle = try doc.select("meta[property='og:title']").first()?.attr("content"), !ogTitle.isEmpty {
            return ogTitle
        }
        if let twitterTitle = try doc.select("meta[name='twitter:title']").first()?.attr("content"), !twitterTitle.isEmpty {
            return twitterTitle
        }
        // Fallback to host
        return url.host ?? "Unknown Document"
    }
    
    private func extractMainContent(from doc: Document) throws -> Element {
        // Try common main content selectors
        let selectors = ["main", "article", "#main", "#content", ".main-content", ".content", ".post", "[role='main']"]
        for selector in selectors {
            if let element = try doc.select(selector).first() {
                return element
            }
        }
        
        // Fallback to body
        guard let body = doc.body() else {
            throw DocumentError.contentExtractionFailed("No body element found in HTML")
        }
        return body
    }
    
    private func removeNavigationElements(from element: Element) throws {
        // Remove common navigation and sidebar elements within the main content
        let navSelectors = [
            "nav", ".nav", ".navigation", ".sidebar", ".aside",
            "[role='navigation']", ".breadcrumb", ".breadcrumbs",
            ".advertisement", ".ads", ".footer", ".header"
        ]
        
        for selector in navSelectors {
            try element.select(selector).remove()
        }
    }
    
    private func cleanupContent(_ content: Element) throws {
        // Remove empty elements and elements with only whitespace
        try content.select(":empty").forEach { element in
            let html = try element.html()
            if html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try element.remove()
            }
        }
        
        // Remove scripts and styles
        try content.select("script, style, noscript").remove()
        
        // Remove elements with loading or placeholder classes
        try content.select("[class*='loading'], [class*='placeholder']").remove()
        
        // Remove comments
        let nodes = content.getChildNodes()
        for node in nodes {
            if node.nodeName() == "#comment" {
                try node.remove()
            }
        }
    }
    
    // MARK: - Enhanced Markdown Conversion
    private func convertToMarkdown(html: String, title: String, sourceURL: URL) async throws -> String {
        // Security scan the HTML content (skip for trusted domains)
        let isTrusted = security.isTrustedDomain(sourceURL)
        try security.scanContentForThreats(html, fromTrustedDomain: isTrusted)
        
        var markdown = "# \(title)\n\n"
        
        // Check if we should use streaming for large content
        if memory.shouldStreamContent(size: html.count) {
            return try await convertToMarkdownStreaming(html: html, title: title, sourceURL: sourceURL)
        }
        
        do {
            let doc = try SwiftSoup.parse(html)
            
            try processDocumentStructure(doc: doc, markdown: &markdown, title: title)
            
        } catch {
            let doc = try SwiftSoup.parse(html)
            let text = try doc.text()
            markdown += "\n\(text)"
        }
        
        let result = cleanupMarkdown(markdown)
        
        // Final security scan
        try security.scanContentForThreats(result)
        
        return result
    }
    
    private func processDocumentStructure(doc: Document, markdown: inout String, title: String) throws {
        // Process headings
        let headings = try doc.select("h1, h2, h3, h4, h5, h6")
        for heading in headings {
            let tagName = heading.tagName()
            let level = Int(tagName.dropFirst()) ?? 1
            let text = try heading.text()
            if !text.isEmpty && text != title {
                markdown += "\(String(repeating: "#", count: level)) \(text)\n\n"
            }
        }
        
        // Process paragraphs
        let paragraphs = try doc.select("p")
        for paragraph in paragraphs {
            let markdownText = try convertElementToMarkdown(paragraph)
            if !markdownText.isEmpty {
                markdown += "\(markdownText)\n\n"
            }
        }
        
        // Process lists
        let lists = try doc.select("ul, ol")
        for list in lists {
            try processListElement(list, markdown: &markdown, level: 1, ordered: list.tagName() == "ol")
        }
        
        // Process tables
        let tables = try doc.select("table")
        for table in tables {
            try processTableElement(table, markdown: &markdown)
        }
        
        // Process blockquotes
        let blockquotes = try doc.select("blockquote")
        for blockquote in blockquotes {
            let text = try blockquote.text()
            if !text.isEmpty {
                markdown += "> \(text)\n\n"
            }
        }
        
        // Process code blocks
        let codeBlocks = try doc.select("pre, code[class*='language-'], .highlight, .code-block")
        for codeBlock in codeBlocks {
            let code = try codeBlock.text()
            if !code.isEmpty && code.count > 10 { // Only substantial code blocks
                let className = try? codeBlock.attr("class")
                let language = extractLanguageFromClass(className ?? "")
                
                if !language.isEmpty {
                    markdown += "```\(language)\n\(code)\n```\n\n"
                } else {
                    markdown += "```\n\(code)\n```\n\n"
                }
            }
        }
        
        // Process inline code
        let inlineCode = try doc.select("code")
        for code in inlineCode {
            let codeText = try code.text()
            if !codeText.isEmpty {
                markdown += "`\(codeText)` "
            }
        }
    }
    
    private func processListElement(_ listElement: Element, markdown: inout String, level: Int, ordered: Bool) throws {
        let items = try listElement.select("> li")
        var counter = 1
        
        for item in items {
            let itemText = try item.text()
            let indent = String(repeating: "  ", count: level - 1)
            
            if ordered {
                markdown += "\(indent)\(counter). \(itemText)\n"
                counter += 1
            } else {
                markdown += "\(indent)- \(itemText)\n"
            }
        }
        markdown += "\n"
    }
    
    private func processTableElement(_ table: Element, markdown: inout String) throws {
        // Extract headers
        let headers = try table.select("th")
        var headerTexts: [String] = []
        for header in headers {
            let text = try header.text()
            headerTexts.append(text.isEmpty ? " " : text)
        }
        
        // Extract rows
        let rows = try table.select("tr")
        var rowTexts: [[String]] = []
        for row in rows {
            var rowCells: [String] = []
            let cells = try row.select("td")
            for cell in cells {
                let text = try cell.text()
                rowCells.append(text.isEmpty ? " " : text)
            }
            if !rowCells.isEmpty {
                rowTexts.append(rowCells)
            }
        }
        
        // Compose markdown table
        if !headerTexts.isEmpty {
            markdown += "| " + headerTexts.joined(separator: " | ") + " |\n"
            markdown += "| " + headerTexts.map { _ in "---" }.joined(separator: " | ") + " |\n"
        }
        
        for row in rowTexts {
            markdown += "| " + row.joined(separator: " | ") + " |\n"
        }
        
        markdown += "\n"
    }
    
    private func cleanupMarkdown(_ markdown: String) -> String {
        var cleaned = markdown
        
        // Remove JavaScript-related messages
        cleaned = cleaned.replacingOccurrences(of: "This page requires JavaScript.*?\n", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "Please turn on JavaScript.*?\n", with: "", options: .regularExpression)
        
        // Remove excessive newlines
        cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Clean up navigation text
        cleaned = cleaned.replacingOccurrences(of: "Global Nav.*?Menu\n", with: "", options: .regularExpression)
        
        // Trim whitespace
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Helper to extract links from a document given a base URL
    private func extractLinks(from doc: Document, baseURL: URL) throws -> [String] {
        var extractedLinks: [String] = []
        let linkElements = try doc.select("a[href]")
        
        for linkElement in linkElements {
            if let href = try? linkElement.attr("href"),
               !href.isEmpty,
               let resolvedURL = URL(string: href, relativeTo: baseURL) {
                extractedLinks.append(resolvedURL.absoluteString)
            }
        }
        
        extractedLinks = Array(Set(extractedLinks))
        return extractedLinks
    }
    
    private func convertToMarkdownStreaming(html: String, title: String, sourceURL: URL) async throws -> String {
        // For very large content, process in chunks to avoid memory issues
        var markdown = "# \(title)\n\n"
        
        // Simple text extraction for streaming mode
        do {
            let doc = try SwiftSoup.parse(html)
            let text = try doc.text()
            
            // Process in chunks
            let chunkSize = 4096
            let chunks = stride(from: 0, to: text.count, by: chunkSize).map {
                let start = text.index(text.startIndex, offsetBy: $0)
                let end = text.index(start, offsetBy: min(chunkSize, text.count - $0))
                return String(text[start..<end])
            }
            
            for chunk in chunks {
                markdown += "\(chunk)\n\n"
                
                // Yield control to prevent blocking
                await Task.yield()
            }
            
        } catch {
            throw DocumentError.parsingError(error.localizedDescription)
        }
        
        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func convertElementToMarkdown(_ element: Element) throws -> String {
        var result = ""
        
        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                result += textNode.text()
            } else if let childElement = node as? Element {
                switch childElement.tagName().lowercased() {
                case "a":
                    if let href = try? childElement.attr("href"), !href.isEmpty {
                        let linkText = try childElement.text()
                        result += "[\(linkText)](\(href))"
                    } else {
                        result += try childElement.text()
                    }
                case "code":
                    let codeText = try childElement.text()
                    result += "`\(codeText)`"
                case "strong", "b":
                    let boldText = try childElement.text()
                    result += "**\(boldText)**"
                case "em", "i":
                    let italicText = try childElement.text()
                    result += "*\(italicText)*"
                default:
                    result += try convertElementToMarkdown(childElement)
                }
            }
        }
        
        return result
    }
    
    private func extractLanguageFromClass(_ className: String) -> String {
        let commonLanguages = ["swift", "javascript", "python", "java", "kotlin", "rust", "go", "cpp", "c", "objc", "ruby", "php", "html", "css", "json", "xml", "yaml", "bash", "shell", "sql"]
        
        let lowercaseClass = className.lowercased()
        for language in commonLanguages {
            if lowercaseClass.contains(language) {
                return language
            }
        }
        
        // Check for language- prefix
        if lowercaseClass.contains("language-") {
            let components = lowercaseClass.components(separatedBy: "language-")
            if components.count > 1 {
                let lang = components[1].components(separatedBy: " ").first ?? ""
                return lang
            }
        }
        
        return ""
    }
    
    private func saveDocument(
        title: String,
        content: String,
        sourceURL: URL,
        response: URLResponse,
        extractedLinks: [String] = [],
        importMethod: ImportMethod = .manual,
        jsRenderingUsed: Bool = false
    ) async throws -> DocumentMetaData {
        
        let existingDoc = library.documents.first { $0.sourceURL == sourceURL.absoluteString }
        
        let filename = storage.generateUniqueFilename(for: sourceURL)
        let fileURL = try storage.saveDocument(content: content, filename: filename)
        let fileSize = storage.getFileSize(at: fileURL)
        
        let summary = String(content.prefix(200))
        
        var metadata = DocumentMetaData(
            title: title,
            sourceURL: sourceURL.absoluteString,
            filePath: fileURL.path,
            fileSize: fileSize,
            summary: summary.isEmpty ? nil : summary
        )
        
        // Store extracted links and import metadata
        metadata.extractedLinks = extractedLinks.isEmpty ? nil : extractedLinks
        metadata.importMethod = importMethod
        metadata.wasRenderedWithJS = jsRenderingUsed
        metadata.contentHash = duplicateHandler.generateContentHash(content)
        metadata.lastUpdateCheck = Date()
        
        // If updating existing document, remove the old one
        if let existing = existingDoc {
            library.removeDocument(existing)
            // Try to delete old file
            try? DocumentStorage.shared.deleteDocument(at: URL(fileURLWithPath: existing.filePath))
        }
        
        library.addDocument(metadata)
        
        return metadata
    }
    
    private func updateTaskStatus(taskId: UUID, status: ProcessingStatus) async {
        await MainActor.run {
            if let index = processingQueue.firstIndex(where: { $0.id == taskId }) {
                processingQueue[index].status = status
            }
        }
    }
    
    private func resetStatusAfterDelay() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            self.currentStatus = "Ready"
            self.processingProgress = 0.0
        }
    }
    
    func cancelProcessing() {
        currentTask?.cancel()
        Task {
            await MainActor.run {
                self.isProcessing = false
                self.currentStatus = "Cancelled"
                self.processingProgress = 0.0
            }
        }
    }
    
    func clearCompletedTasks() {
        Task {
            await MainActor.run {
                processingQueue.removeAll { task in
                    switch task.status {
                    case .completed, .failed:
                        return true
                    default:
                        return false
                    }
                }
            }
        }
    }
}

struct ProcessingTask: Identifiable {
    let id: UUID
    let url: URL
    var status: ProcessingStatus
}

enum ProcessingStatus: Equatable {
    case pending
    case processing
    case completed
    case failed(Error)
    
    static func ==(lhs: ProcessingStatus, rhs: ProcessingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending), (.processing, .processing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

enum DocumentError: LocalizedError {
    case invalidURL(String)
    case unsupportedURLScheme(String)
    case blockedDomain(String)
    case networkError(URLError)
    case httpError(Int)
    case emptyResponse
    case documentTooLarge(Int)
    case duplicateDocument(String)
    case parsingError(String)
    case storageError(String)
    case contentExtractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .unsupportedURLScheme(let scheme):
            return "Unsupported URL scheme: \(scheme)"
        case .blockedDomain(let domain):
            return "Domain is blocked: \(domain)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .emptyResponse:
            return "Empty response from server"
        case .documentTooLarge(let size):
            return "Document too large: \(size) bytes"
        case .duplicateDocument(let title):
            return "Document already exists: \(title)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .contentExtractionFailed(let message):
            return "Content extraction failed: \(message)"
        }
    }
}

// MARK: - Apple Developer Documentation Specialist
class AppleDocsSpecialist {
    static let shared = AppleDocsSpecialist()
    
    private init() {}
    
    func isAppleDeveloperDocs(_ url: URL) -> Bool {
        return url.host?.contains("developer.apple.com") == true
    }
    
    func enhanceJavaScriptRendering(for url: URL) -> String {
        // Custom JavaScript to execute after page load for Apple docs
        return """
        // Wait for content to load
        function waitForContent() {
            return new Promise((resolve) => {
                const checkContent = () => {
                    const main = document.querySelector('main[role="main"]') || 
                                 document.querySelector('.main-content') ||
                                 document.querySelector('.documentation-content');
                    
                    if (main && main.textContent.trim().length > 100) {
                        resolve();
                    } else {
                        setTimeout(checkContent, 500);
                    }
                };
                checkContent();
            });
        }
        
        // Remove navigation and enhance content
        function cleanAppleDocsContent() {
            // Remove navigation elements
            const navElements = document.querySelectorAll(`
                nav, 
                .nav, 
                .global-nav, 
                .local-nav,
                .documentation-nav,
                header,
                footer,
                .sidebar,
                .complementary,
                [role="navigation"],
                [role="banner"],
                [role="complementary"]
            `);
            
            navElements.forEach(el => el.remove());
            
            // Find and enhance main content
            const main = document.querySelector('main[role="main"]') || 
                        document.querySelector('.main-content') ||
                        document.querySelector('.documentation-content') ||
                        document.querySelector('main');
            
            if (main) {
                // Add clear content markers
                main.setAttribute('data-main-content', 'true');
                
                // Enhance code blocks
                const codeBlocks = main.querySelectorAll('pre, code');
                codeBlocks.forEach(block => {
                    block.setAttribute('data-code-block', 'true');
                });
                
                // Mark important sections
                const sections = main.querySelectorAll('section, .section, article');
                sections.forEach(section => {
                    section.setAttribute('data-content-section', 'true');
                });
            }
            
            return main ? main.outerHTML : document.body.innerHTML;
        }
        
        // Execute enhancement
        waitForContent().then(() => {
            return cleanAppleDocsContent();
        });
        """
    }
    
    func extractAppleDocsContent(from html: String, url: URL) throws -> String {
        let doc = try SwiftSoup.parse(html)
        
        // Apple-specific content selectors (in order of preference)
        let appleContentSelectors = [
            "main[role='main']",
            ".main-content",
            ".documentation-content",
            ".hero + .container .row",
            ".content-wrapper main",
            "[data-main-content='true']",
            "main"
        ]
        
        var mainContent: Element?
        
        for selector in appleContentSelectors {
            if let element = try doc.select(selector).first() {
                mainContent = element
                break
            }
        }
        
        guard let content = mainContent else {
            throw DocumentError.contentExtractionFailed("No main content found in Apple Developer docs")
        }
        
        // Apple-specific cleanup
        try cleanupAppleDocsContent(content)
        
        return try content.outerHtml()
    }
    
    // Extract overview content with better filtering
    private func extractOverviewSection(from doc: Document) -> String? {
        // Look for overview patterns in Apple docs
        let overviewSelectors = [
            ".hero .content p",
            ".overview p:first-of-type",
            ".introduction p",
            "main > p:first-of-type",
            ".content > p:first-of-type"
        ]
        
        for selector in overviewSelectors {
            if let overview = try? doc.select(selector).first()?.text(),
               !overview.isEmpty,
               !overview.contains("This page requires JavaScript"),
               overview.count > 50 { // Ensure substantial content
                return overview
            }
        }
        return nil
    }
    
    // Extract structured content with hierarchy
    private func extractContentStructure(from doc: Document) throws -> ContentStructure {
        var sections: [ContentSection] = []
        var codeBlocks: [CodeBlock] = []
        
        // Find main content sections
        let headings = try doc.select("h2, h3, h4")
        
        for heading in headings {
            let title = try heading.text()
            guard !title.isEmpty else { continue }
            
            let anchor = generateAnchor(from: title)
            let level = Int(heading.tagName().dropFirst()) ?? 2
            
            // Find content following this heading
            var content = ""
            var nextSibling = try heading.nextElementSibling()
            
            while let sibling = nextSibling,
                  !["h1", "h2", "h3", "h4", "h5", "h6"].contains(sibling.tagName().lowercased()) {
                
                if sibling.tagName().lowercased() == "pre" {
                    // Handle code blocks separately
                    let code = try sibling.text()
                    let language = extractLanguageFromElement(sibling)
                    codeBlocks.append(CodeBlock(content: code, language: language, context: title))
                } else {
                    let text = try sibling.text()
                    if !text.isEmpty {
                        content += text + "\n\n"
                    }
                }
                
                nextSibling = try sibling.nextElementSibling()
            }
            
            if !content.isEmpty || !title.isEmpty {
                sections.append(ContentSection(
                    title: title,
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    level: level,
                    anchor: anchor
                ))
            }
        }
        
        return ContentStructure(sections: sections, codeBlocks: codeBlocks)
    }
    
    // Enhanced property wrapper extraction for SwiftUI docs
    private func extractPropertyWrappers(from doc: Document) -> String? {
        let wrapperPatterns = ["@State", "@Binding", "@ObservedObject", "@StateObject", "@Environment", "@Bindable"]
        var wrapperContent = ""
        
        for pattern in wrapperPatterns {
            if let elements = try? doc.select("*:contains(\(pattern))") {
                for element in elements {
                    if let text = try? element.text(),
                       text.contains(pattern),
                       text.count > 20,
                       text.count < 500 {
                        let cleanText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        wrapperContent += "- **\(pattern)**: \(cleanText)\n"
                        break // Only take the first good match for each pattern
                    }
                }
            }
        }
        
        return wrapperContent.isEmpty ? nil : wrapperContent
    }
    
    // Extract event types for comprehensive coverage
    private func extractEventTypes(from doc: Document) -> String? {
        let eventPatterns = ["events", "gesture", "interaction", "touch", "click", "drag", "drop"]
        var eventContent = ""
        var seenEvents: Set<String> = []
        
        for pattern in eventPatterns {
            if let elements = try? doc.select("*:contains(\(pattern)) li, *:contains(\(pattern)) p") {
                for element in elements {
                    if let text = try? element.text(),
                       text.lowercased().contains(pattern),
                       text.count > 20,
                       text.count < 300,
                       !seenEvents.contains(text) {
                        let cleanText = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        eventContent += "- \(cleanText)\n"
                        seenEvents.insert(text)
                    }
                }
            }
        }
        
        return eventContent.isEmpty ? nil : eventContent
    }
    
    // Enhanced code block formatting
    private func formatCodeBlock(_ codeBlock: CodeBlock) throws -> String {
        var result = ""
        
        if !codeBlock.context.isEmpty {
            result += "### \(codeBlock.context)\n\n"
        }
        
        let language = codeBlock.language.isEmpty ? "swift" : codeBlock.language
        result += "```\(language)\n"
        result += codeBlock.content.trimmingCharacters(in: .whitespacesAndNewlines)
        result += "\n```\n\n"
        
        return result
    }
    
    // Process content sections with proper formatting
    private func processContentSection(_ section: ContentSection, doc: Document) throws -> String {
        var result = ""
        
        let headerPrefix = String(repeating: "#", count: section.level)
        result += "\(headerPrefix) \(section.title) {#\(section.anchor)}\n\n"
        
        if !section.content.isEmpty {
            result += section.content + "\n\n"
        }
        
        return result
    }
    
    // Helper functions
    private func generateAnchor(from title: String) -> String {
        return title
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
    
    private func extractLanguageFromElement(_ element: Element) -> String {
        if let className = try? element.attr("class") {
            let commonLanguages = ["swift", "javascript", "objc", "json", "xml", "html", "css"]
            for language in commonLanguages {
                if className.lowercased().contains(language) {
                    return language
                }
            }
        }
        return "swift" // Default for Apple docs
    }
    
    // Enhanced markdown cleanup
    private static func cleanupMarkdownEnhanced(_ markdown: String) -> String {
        var cleaned = markdown
        
        // Remove JavaScript-related messages
        cleaned = cleaned.replacingOccurrences(of: "This page requires JavaScript.*?\\n", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "Please turn on JavaScript.*?\\n", with: "", options: .regularExpression)
        
        // Remove navigation artifacts
        let navigationPatterns = [
            "Global Nav.*?Menu\\n",
            "Local Nav.*?\\n",
            "Documentation Archive.*?\\n",
            "Developer.*?Search.*?\\n"
        ]
        
        for pattern in navigationPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        // Fix excessive whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\n{4,}", with: "\n\n\n", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\n{3}", with: "\n\n", options: .regularExpression)
        
        // Remove duplicate content (common issue)
        let lines = cleaned.components(separatedBy: "\n")
        var uniqueLines: [String] = []
        var seenContent: Set<String> = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || !seenContent.contains(trimmed) {
                uniqueLines.append(line)
                if trimmed.count > 10 { // Only track substantial content
                    seenContent.insert(trimmed)
                }
            }
        }
        
        return uniqueLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private func cleanupAppleDocsContent(_ content: Element) throws {
        // Remove Apple-specific navigation and UI elements
        let appleUISelectors = [
            ".global-nav", ".local-nav", ".nav",
            ".breadcrumb", ".breadcrumbs",
            ".doc-nav", ".documentation-nav",
            ".sidebar", ".aside",
            "header", "footer",
            ".hero-nav", ".sub-nav",
            "[class*='nav-']", "[id*='nav-']",
            ".complementary", "[role='complementary']",
            ".banner", "[role='banner']",
            ".contentinfo", "[role='contentinfo']"
        ]
        
        for selector in appleUISelectors {
            try content.select(selector).remove()
        }
        
        // Remove empty containers that often remain after JS rendering
        try content.select("div:empty, section:empty, article:empty").remove()
        
        // Clean up Apple-specific artifacts
        try content.select("[class*='loading']").remove()
        try content.select("[class*='placeholder']").remove()
        try content.select("noscript").remove()
    }
    
    func convertAppleDocsToMarkdown(_ html: String, title: String, url: URL) throws -> String {
        let doc = try SwiftSoup.parse(html)
        var markdown = "# \(title)\n\n"
        markdown += "> **Source:** [Apple Developer Documentation](\(url.absoluteString))\n\n"
        
        // Extract overview/description first
        if let overview = extractOverviewSection(from: doc) {
            markdown += overview + "\n\n"
        }
        
        // Process main navigation structure
        let contentStructure = try extractContentStructure(from: doc)
        
        // Build table of contents if we have multiple sections
        if contentStructure.sections.count > 1 {
            markdown += "## Table of Contents\n\n"
            for section in contentStructure.sections {
                markdown += "- [\(section.title)](#\(section.anchor))\n"
            }
            markdown += "\n"
        }
        
        // Process each content section
        for section in contentStructure.sections {
            markdown += try processContentSection(section, doc: doc)
        }
        
        // Process code examples section
        if !contentStructure.codeBlocks.isEmpty {
            markdown += "## Code Examples\n\n"
            for codeBlock in contentStructure.codeBlocks {
                markdown += try formatCodeBlock(codeBlock)
            }
        }
        
        // Process property wrappers section (SwiftUI specific)
        if let propertyWrappers = extractPropertyWrappers(from: doc) {
            markdown += "## Property Wrappers Reference\n\n"
            markdown += propertyWrappers + "\n\n"
        }
        
        // Process event types section
        if let eventTypes = extractEventTypes(from: doc) {
            markdown += "## Event Types\n\n"
            markdown += eventTypes + "\n\n"
        }
        
        return Self.cleanupMarkdownEnhanced(markdown)
    }
    
    private static func processAppleDocsStructure(doc: Document, markdown: inout String, title: String) throws {
        // Apple docs often have specific structure patterns
        
        // 1. Process hero/intro sections
        if let hero = try doc.select(".hero, .intro, .overview").first() {
            let heroText = try hero.text()
            if !heroText.isEmpty && !heroText.contains("This page requires JavaScript") {
                markdown += "\(heroText)\n\n---\n\n"
            }
        }
        
        // 2. Process main content sections
        let sections = try doc.select("section[data-content-section], .content-section, article")
        
        for section in sections {
            try Self.processSectionContent(section, markdown: &markdown, title: title)
        }
        
        // 3. Fallback: process all headings and paragraphs
        if sections.isEmpty {
            try Self.processStandardContent(doc, markdown: &markdown, title: title)
        }
        
        // 4. Process code examples
        let codeBlocks = try doc.select("pre[data-code-block], .code-listing, .code-sample")
        for codeBlock in codeBlocks {
            try Self.processCodeBlock(codeBlock, markdown: &markdown)
        }
    }
    
    private static func processSectionContent(_ section: Element, markdown: inout String, title: String) throws {
        // Extract section heading
        if let heading = try section.select("h1, h2, h3, h4, h5, h6").first() {
            let level = Int(heading.tagName().dropFirst()) ?? 2
            let headingText = try heading.text()
            if !headingText.isEmpty && headingText != title {
                markdown += "\(String(repeating: "#", count: level)) \(headingText)\n\n"
            }
        }
        
        // Extract paragraphs
        let paragraphs = try section.select("p")
        for paragraph in paragraphs {
            let text = try paragraph.text()
            if !text.isEmpty {
                markdown += "\(text)\n\n"
            }
        }
        
        // Extract lists
        let lists = try section.select("ul, ol")
        for list in lists {
            try processListElement(list, markdown: &markdown, level: 1, ordered: list.tagName() == "ol")
        }
    }
    
    private static func processStandardContent(_ doc: Document, markdown: inout String, title: String) throws {
        let elements = try doc.select("h1, h2, h3, h4, h5, h6, p, ul, ol, blockquote, pre")
        
        for element in elements {
            let tagName = element.tagName().lowercased()
            
            switch tagName {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                let level = Int(tagName.dropFirst()) ?? 1
                let headingText = try element.text()
                if !headingText.isEmpty && headingText != title {
                    markdown += "\(String(repeating: "#", count: level)) \(headingText)\n\n"
                }
                
            case "p":
                let text = try element.text()
                if !text.isEmpty && !text.contains("This page requires JavaScript") {
                    markdown += "\(text)\n\n"
                }
                
            case "ul", "ol":
                try processListElement(element, markdown: &markdown, level: 1, ordered: tagName == "ol")
                
            case "blockquote":
                let text = try element.text()
                if !text.isEmpty {
                    markdown += "> \(text)\n\n"
                }
                
            case "pre":
                try processCodeBlock(element, markdown: &markdown)
            default:
                break
            }
        }
    }
    
    private static func processCodeBlock(_ codeBlock: Element, markdown: inout String) throws {
        let codeText = try codeBlock.text()
        if !codeText.isEmpty {
            // Try to detect language from class names
            let className = try codeBlock.attr("class")
            let language = extractLanguageFromClassName(className)
            
            markdown += "```\(language)\n\(codeText)\n```\n\n"
        }
    }
    
    private static func extractLanguageFromClassName(_ className: String) -> String {
        let languages = ["swift", "objective-c", "javascript", "css", "html", "json", "xml", "bash", "shell"]
        
        for language in languages {
            if className.lowercased().contains(language) {
                return language
            }
        }
        
        return ""
    }
    
    private static func cleanupMarkdown(_ markdown: String) -> String {
        var cleaned = markdown
        
        // Remove JavaScript-related messages
        cleaned = cleaned.replacingOccurrences(of: "This page requires JavaScript.*?\n", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "Please turn on JavaScript.*?\n", with: "", options: .regularExpression)
        
        // Remove excessive newlines
        cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Clean up navigation text
        cleaned = cleaned.replacingOccurrences(of: "Global Nav.*?Menu\n", with: "", options: .regularExpression)
        
        // Trim whitespace
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Added static helper as per instruction
    private static func processListElement(_ listElement: Element, markdown: inout String, level: Int, ordered: Bool) throws {
        let items = try listElement.select("> li")
        var counter = 1

        for item in items {
            let itemText = try item.text()
            let indent = String(repeating: "  ", count: level - 1)

            if ordered {
                markdown += "\(indent)\(counter). \(itemText)\n"
                counter += 1
            } else {
                markdown += "\(indent)- \(itemText)\n"
            }
        }
        markdown += "\n"
    }
    
}

// MARK: - Integration with DocumentProcessor
extension DocumentProcessor {
    
    // Enhanced Apple Developer document processing
    func processAppleDeveloperDocumentEnhanced(url: URL, data: Data) async throws -> (title: String, content: String, extractedLinks: [String]) {
        let specialist = AppleDocsSpecialist.shared
        
        await MainActor.run {
            self.currentStatus = "Processing Apple Developer documentation..."
            self.processingProgress = 0.3
        }
        
        // Use JavaScript rendering for Apple docs (they're heavily JS-dependent)
        var finalData = data
        if config.enableJavaScriptRendering || specialist.isAppleDeveloperDocs(url) {
            do {
                let jsCode = specialist.enhanceJavaScriptRendering(for: url)
                let renderedHTML = try await jsRenderer.renderPageWithCustomJS(url: url, jsCode: jsCode)
                finalData = renderedHTML.data(using: .utf8) ?? data
                logger.info("Successfully rendered Apple Developer docs with enhanced JavaScript")
            } catch {
                logger.warning("JavaScript rendering failed for Apple docs, using static content: \(error)")
            }
        }
        
        await MainActor.run {
            self.currentStatus = "Extracting Apple-specific content..."
            self.processingProgress = 0.5
        }
        
        // Parse with Apple-specific logic
        let html = String(decoding: finalData, as: UTF8.self)
        let doc = try SwiftSoup.parse(html)
        
        // Extract title with Apple-specific patterns
        let title = try extractAppleDocsTitle(from: doc, url: url)
        
        // Extract content with enhanced Apple-specific processing
        let content = try specialist.extractAppleDocsContent(from: html, url: url)
        
        // Extract links
        let extractedLinks = try extractLinks(from: doc, baseURL: url)
        
        await MainActor.run {
            self.currentStatus = "Converting to enhanced markdown..."
            self.processingProgress = 0.7
        }
        
        // Convert to enhanced markdown format
        let enhancedMarkdown = try specialist.convertAppleDocsToMarkdown(content, title: title, url: url)
        
        return (title, enhancedMarkdown, extractedLinks)
    }
    
    // Enhanced title extraction for Apple docs
    private func extractAppleDocsTitle(from doc: Document, url: URL) throws -> String {
        // Apple docs title hierarchy
        let titleSelectors = [
            "h1.documentation-title",
            "h1.hero-title", 
            ".hero h1",
            "main h1",
            "h1",
            "title"
        ]
        
        for selector in titleSelectors {
            if let titleElement = try doc.select(selector).first() {
                let title = try titleElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty && title != "Apple Developer Documentation" {
                    return title
                }
            }
        }
        
        // Fallback to page title
        let pageTitle = try doc.title()
        if !pageTitle.isEmpty {
            // Clean up Apple's title format "Title | Apple Developer Documentation"
            let cleanTitle = pageTitle.components(separatedBy: " | ").first ?? pageTitle
            return cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Final fallback
        return url.lastPathComponent.capitalized.replacingOccurrences(of: "-", with: " ")
    }
    
    // Update the main parseHTML method to use enhanced Apple processing
    private func parseHTMLEnhanced(data: Data, url: URL) async throws -> (title: String, content: String, extractedLinks: [String]) {
        // Check if this is Apple Developer documentation
        if AppleDocsSpecialist.shared.isAppleDeveloperDocs(url) {
            return try await processAppleDeveloperDocumentEnhanced(url: url, data: data)
        }
        
        // Use existing logic for non-Apple docs
        return try await parseHTML(data: data, url: url)
    }

}

// MARK: - Supporting Data Structures for Enhanced Apple Docs Processing
struct ContentStructure {
    let sections: [ContentSection]
    let codeBlocks: [CodeBlock]
}

struct ContentSection {
    let title: String
    let content: String
    let level: Int
    let anchor: String
}

struct CodeBlock {
    let content: String
    let language: String
    let context: String
}


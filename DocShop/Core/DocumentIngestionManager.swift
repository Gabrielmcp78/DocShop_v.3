import Foundation
import PDFKit
// import Down, SwiftSoup, Yams, Vision, etc. as needed

class DocumentIngestionManager {
    static let shared = DocumentIngestionManager()
    private init() {}
    
    // MARK: - Entry Points
    func ingestFile(at url: URL) async throws -> IngestedDocument {
        let type = detectType(for: url)
        switch type {
        case .pdf:
            return try await ingestPDF(at: url)
        case .markdown:
            return try await ingestMarkdown(at: url)
        case .html:
            return try await ingestHTML(at: url)
        case .word:
            return try await ingestWord(at: url)
        case .plaintext:
            return try await ingestPlaintext(at: url)
        case .code:
            return try await ingestCode(at: url)
        case .openapi:
            return try await ingestOpenAPI(at: url)
        case .image:
            return try await ingestImage(at: url)
        case .unknown:
            throw NSError(domain: "DocShop", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown document type"])
        }
    }
    
    func ingestFromURL(_ url: URL) async throws -> IngestedDocument {
        // Download file from URL, then ingest
        let (tempURL, response) = try await downloadFile(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "DocShop", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to download file from URL"] )
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }
        return try await ingestFile(at: tempURL)
    }
    
    func ingestFromGitRepo(_ repoURL: URL) async throws -> [IngestedDocument] {
        // Clone repo to temp dir, enumerate files, call ingestFile for each
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        try await cloneGitRepo(from: repoURL, to: tempDir)
        let fileURLs = try enumerateFiles(in: tempDir)
        var docs: [IngestedDocument] = []
        for fileURL in fileURLs {
            do {
                let doc = try await ingestFile(at: fileURL)
                docs.append(doc)
            } catch {
                print("Failed to ingest file: \(fileURL.lastPathComponent): \(error)")
            }
        }
        return docs
    }
    
    func ingestFromCloud(_ cloudURL: URL) async throws -> [IngestedDocument] {
        // Download from cloud, call ingestFile
        let fileURLs = try await downloadCloudFiles(from: cloudURL)
        var docs: [IngestedDocument] = []
        for fileURL in fileURLs {
            do {
                let doc = try await ingestFile(at: fileURL)
                docs.append(doc)
            } catch {
                print("Failed to ingest cloud file: \(fileURL.lastPathComponent): \(error)")
            }
        }
        return docs
    }
    
    // MARK: - Format-Specific Ingestion (with Neo4j persistence)
    private func ingestPDF(at url: URL) async throws -> IngestedDocument {
        guard let pdfDoc = PDFDocument(url: url) else {
            throw NSError(domain: "DocShop", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to parse PDF"])
        }
        let title = pdfDoc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
        let author = pdfDoc.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        let tags = extractPDFTags(pdfDoc)
        let doc = IngestedDocument(id: UUID(), type: .pdf, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        // Extract text for chunking
        let text = (0..<pdfDoc.pageCount).compactMap { pdfDoc.page(at: $0)?.string }.joined(separator: "\n\n")
        let chunks = DocumentChunker.chunkPDF(document: doc, text: text)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestMarkdown(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let (title, tags) = extractMarkdownMeta(content: content, url: url)
        let author = "Unknown"
        let doc = IngestedDocument(id: UUID(), type: .markdown, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkMarkdown(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestHTML(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let (title, author, tags) = extractHTMLMeta(html: html, url: url)
        let doc = IngestedDocument(id: UUID(), type: .html, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkHTML(document: doc, html: html)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestWord(at url: URL) async throws -> IngestedDocument {
        // Use a third-party library for .docx parsing if available, else fallback
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = []
        let content = try extractWordText(url: url)
        let doc = IngestedDocument(id: UUID(), type: .word, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkPlaintext(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestPlaintext(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags = extractPlaintextTags(content: content)
        let doc = IngestedDocument(id: UUID(), type: .plaintext, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkPlaintext(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestCode(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let language = detectCodeLanguage(url: url, content: content)
        let tags = [language]
        let doc = IngestedDocument(id: UUID(), type: .code, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkCode(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestOpenAPI(at url: URL) async throws -> IngestedDocument {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags = extractOpenAPITags(content: content)
        let doc = IngestedDocument(id: UUID(), type: .openapi, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkPlaintext(document: doc, content: content)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    private func ingestImage(at url: URL) async throws -> IngestedDocument {
        let title = url.deletingPathExtension().lastPathComponent
        let author = "Unknown"
        let tags: [String] = []
        let ocrText = try performOCR(on: url)
        let doc = IngestedDocument(id: UUID(), type: .image, url: url, originalFilename: url.lastPathComponent, importedAt: Date(), title: title, author: author, tags: tags)
        let chunks = DocumentChunker.chunkPlaintext(document: doc, content: ocrText)
        persistDocumentAndChunksToNeo4j(document: doc, chunks: chunks)
        return doc
    }
    
    // MARK: - Neo4j Persistence
    private func persistDocumentAndChunksToNeo4j(document: IngestedDocument, chunks: [DocumentChunk]) {
        Neo4jManager.shared.createDocumentNode(document) { result in
            switch result {
            case .success():
                for chunk in chunks {
                    Task {
                        do {
                            // Generate embedding
                            let embedding = try await GeminiAPI.getEmbedding(for: chunk.content)
                            // Generate tags
                            let tagsPrompt = "Analyze the following text and provide 5 relevant tags as a comma-separated list. Text: \(chunk.content)"
                            let tagsString = try await GeminiAPI.generateText(prompt: tagsPrompt, temperature: 0.2, maxTokens: 64)
                            let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            // Create chunk node with embedding and tags
                            var chunkWithAI = chunk
                            // You may want to add embedding/tags to the chunk struct and Neo4j schema
                            // For now, store tags in tags property, embedding in metadata
                            chunkWithAI.tags = tags
                            chunkWithAI.metadata["embedding"] = embedding.map { String($0) }.joined(separator: ",")
                            Neo4jManager.shared.createChunkNode(chunkWithAI) { chunkResult in
                                switch chunkResult {
                                case .success():
                                    Neo4jManager.shared.createHasChunkRelationship(documentID: document.id, chunkID: chunk.id) { relResult in
                                        if case .failure(let error) = relResult {
                                            print("Failed to create HAS_CHUNK: \(error)")
                                        }
                                    }
                                case .failure(let error):
                                    print("Failed to create chunk node: \(error)")
                                }
                            }
                        } catch {
                            print("AI enrichment failed for chunk: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("Failed to create document node: \(error)")
            }
        }
    }
    
    // MARK: - Type Detection
    private func detectType(for url: URL) -> DocumentType {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return .pdf
        case "md", "markdown": return .markdown
        case "html", "htm": return .html
        case "docx", "doc": return .word
        case "txt": return .plaintext
        case "swift", "py", "js", "java", "kt", "cpp", "c", "h": return .code
        case "yaml", "yml", "json": return .openapi
        case "png", "jpg", "jpeg", "gif", "bmp", "tiff": return .image
        default: return .unknown
        }
    }

    // MARK: - Download/Clone Helpers (to be implemented next)
    private func downloadFile(from url: URL) async throws -> (URL, URLResponse) {
        let (tempURL, response): (URL, URLResponse)
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
        let (data, resp) = try await URLSession.shared.data(from: url)
        try data.write(to: tempFile)
        tempURL = tempFile
        response = resp
        return (tempURL, response)
    }
    private func cloneGitRepo(from repoURL: URL, to destination: URL) async throws {
        // Use shell out to git
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "clone", repoURL.absoluteString, destination.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(domain: "DocShop", code: 101, userInfo: [NSLocalizedDescriptionKey: "Git clone failed: \(output)"])
        }
    }
    private func enumerateFiles(in directory: URL) throws -> [URL] {
        var files: [URL] = []
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: resourceKeys)!
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isDirectory == false {
                files.append(fileURL)
            }
        }
        return files
    }
    private func downloadCloudFiles(from cloudURL: URL) async throws -> [URL] {
        // TODO: Implement real cloud provider logic (S3, GCS, etc.)
        // For now, treat as a directory URL and enumerate files
        if cloudURL.isFileURL {
            return try enumerateFiles(in: cloudURL)
        }
        throw NSError(domain: "DocShop", code: 103, userInfo: [NSLocalizedDescriptionKey: "Cloud provider not implemented for URL: \(cloudURL)"])
    }

    // MARK: - Extraction Helpers
    private func extractPDFTags(_ pdfDoc: PDFDocument) -> [String] {
        // Extract keywords from PDF metadata if available
        if let keywords = pdfDoc.documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? String {
            return keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        return []
    }
    private func extractMarkdownMeta(content: String, url: URL) -> (String, [String]) {
        // Simple YAML frontmatter extraction
        if content.hasPrefix("---") {
            if let end = content.range(of: "---", options: [], range: content.index(content.startIndex, offsetBy: 3)..<content.endIndex) {
                let meta = String(content[content.index(content.startIndex, offsetBy: 3)..<end.lowerBound])
                let lines = meta.split(separator: "\n")
                var title = url.deletingPathExtension().lastPathComponent
                var tags: [String] = []
                for line in lines {
                    if line.lowercased().starts(with: "title:") {
                        title = line.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? title
                    } else if line.lowercased().starts(with: "tags:") {
                        tags = line.split(separator: ":", maxSplits: 1).last?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
                    }
                }
                return (title, tags)
            }
        }
        return (url.deletingPathExtension().lastPathComponent, [])
    }
    private func extractHTMLMeta(html: String, url: URL) -> (String, String, [String]) {
        // Naive extraction for <title>, <meta name="author">, <meta name="keywords">
        let title = html.slice(from: "<title>", to: "</title>") ?? url.deletingPathExtension().lastPathComponent
        let author = html.slice(from: "<meta name=\"author\" content=\"", to: "\"") ?? "Unknown"
        let keywords = html.slice(from: "<meta name=\"keywords\" content=\"", to: "\"") ?? ""
        let tags = keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return (title, author, tags)
    }
    private func extractPlaintextTags(content: String) -> [String] {
        // Use simple heuristics or AI to extract tags from plaintext
        // For now, return empty
        return []
    }
    private func detectCodeLanguage(url: URL, content: String) -> String {
        // Use file extension or simple heuristics
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "Swift"
        case "py": return "Python"
        case "js": return "JavaScript"
        case "java": return "Java"
        case "kt": return "Kotlin"
        case "cpp": return "C++"
        case "c": return "C"
        case "h": return "C/C++ Header"
        default: return "Unknown"
        }
    }
    private func extractOpenAPITags(content: String) -> [String] {
        // Naive: look for "openapi" or "swagger" in content
        if content.contains("openapi") { return ["OpenAPI"] }
        if content.contains("swagger") { return ["Swagger"] }
        return []
    }
    private func extractWordText(url: URL) throws -> String {
        // TODO: Use a real .docx parser (e.g., DocXKit, OfficeOpenXML)
        // For now, return empty string
        return ""
    }
    private func performOCR(on url: URL) throws -> String {
        // TODO: Use Vision or Tesseract for OCR
        // For now, return empty string
        return ""
    }
} 

// MARK: - String Slicing Helper
private extension String {
    func slice(from: String, to: String) -> String? {
        guard let fromRange = range(of: from) else { return nil }
        guard let toRange = range(of: to, range: fromRange.upperBound..<endIndex) else { return nil }
        return String(self[fromRange.upperBound..<toRange.lowerBound])
    }
} 

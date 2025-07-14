import Foundation

enum DocumentChunkType: String, Codable, CaseIterable {
    case paragraph, heading, codeBlock, table, image, list, section, unknown
}

struct DocumentChunk: Identifiable, Codable {
    let id: UUID
    let documentID: UUID
    let type: DocumentChunkType
    let content: String
    let position: Int
    var metadata: [String: String] // e.g., heading level, language, etc.
    var tags: [String]
}

class DocumentChunker {
    // PDF chunking: split by page, then by paragraphs
    static func chunkPDF(document: IngestedDocument, text: String) -> [DocumentChunk] {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return paragraphs.enumerated().map { idx, para in
            DocumentChunk(id: UUID(), documentID: document.id, type: .paragraph, content: para, position: idx, metadata: [:], tags: [])
        }
    }
    // Markdown chunking: split by headings and code blocks
    static func chunkMarkdown(document: IngestedDocument, content: String) -> [DocumentChunk] {
        var chunks: [DocumentChunk] = []
        let lines = content.components(separatedBy: .newlines)
        var buffer = ""
        var position = 0
        var currentType: DocumentChunkType = .paragraph
        for line in lines {
            if line.hasPrefix("#") {
                if !buffer.isEmpty {
                    chunks.append(DocumentChunk(id: UUID(), documentID: document.id, type: currentType, content: buffer, position: position, metadata: [:], tags: []))
                    position += 1
                    buffer = ""
                }
                currentType = .heading
                buffer = line
            } else if line.hasPrefix("```") {
                if !buffer.isEmpty {
                    chunks.append(DocumentChunk(id: UUID(), documentID: document.id, type: currentType, content: buffer, position: position, metadata: [:], tags: []))
                    position += 1
                    buffer = ""
                }
                currentType = .codeBlock
                buffer = line
            } else {
                buffer += "\n" + line
            }
        }
        if !buffer.isEmpty {
            chunks.append(DocumentChunk(id: UUID(), documentID: document.id, type: currentType, content: buffer, position: position, metadata: [:], tags: []))
        }
        return chunks
    }
    // HTML chunking: split by headings, paragraphs, code blocks
    static func chunkHTML(document: IngestedDocument, html: String) -> [DocumentChunk] {
        // TODO: Use SwiftSoup for real parsing
        let paragraphs = html.components(separatedBy: "<p>").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return paragraphs.enumerated().map { idx, para in
            DocumentChunk(id: UUID(), documentID: document.id, type: .paragraph, content: para, position: idx, metadata: [:], tags: [])
        }
    }
    // Plaintext chunking: split by paragraphs
    static func chunkPlaintext(document: IngestedDocument, content: String) -> [DocumentChunk] {
        let paragraphs = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return paragraphs.enumerated().map { idx, para in
            DocumentChunk(id: UUID(), documentID: document.id, type: .paragraph, content: para, position: idx, metadata: [:], tags: [])
        }
    }
    // Code chunking: split by function/class definitions (stub)
    static func chunkCode(document: IngestedDocument, content: String) -> [DocumentChunk] {
        let lines = content.components(separatedBy: .newlines)
        var chunks: [DocumentChunk] = []
        var buffer = ""
        var position = 0
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("func ") || line.trimmingCharacters(in: .whitespaces).hasPrefix("class ") {
                if !buffer.isEmpty {
                    chunks.append(DocumentChunk(id: UUID(), documentID: document.id, type: .codeBlock, content: buffer, position: position, metadata: [:], tags: []))
                    position += 1
                    buffer = ""
                }
            }
            buffer += "\n" + line
        }
        if !buffer.isEmpty {
            chunks.append(DocumentChunk(id: UUID(), documentID: document.id, type: .codeBlock, content: buffer, position: position, metadata: [:], tags: []))
        }
        return chunks
    }
} 

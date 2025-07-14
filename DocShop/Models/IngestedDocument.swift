import Foundation

enum DocumentType: String, Codable, CaseIterable {
    case pdf, markdown, html, word, plaintext, code, openapi, image, unknown
}

struct IngestedDocument: Identifiable, Codable {
    let id: UUID
    let type: DocumentType
    let url: URL
    let originalFilename: String
    let importedAt: Date
    let title: String
    let author: String
    let tags: [String]
    // Add more metadata as needed
} 
//
//  DocumentMetaData.swift
//  DocShop
//
//  Created by Gabriel McPherson on 6/28/25.
//

import Foundation

struct DocumentMetaData: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var title: String
    let sourceURL: String
    let filePath: String
    let dateImported: Date
    var dateLastAccessed: Date?
    var dateModified: Date?
    let fileSize: Int64
    var summary: String?
    var tags: Set<String>?
    var isFavorite: Bool
    var accessCount: Int
    var contentType: DocumentContentType
    var language: String?
    
    // Enhanced metadata fields for improved categorization
    var programmingLanguages: Set<String>? // Programming languages identified in the document
    var frameworks: Set<String>? // Frameworks identified in the document
    var companies: Set<String>? // Companies mentioned in the document
    var categories: Set<String>? // General categories for the document
    var complexity: DocumentComplexity? // Estimated complexity level
    var audience: DocumentAudience? // Target audience
    var documentVersion: String? // Version of the document itself
    var apiVersion: String? // API version if applicable
    var keywords: [String]? // Key terms extracted from the document
    var readingTime: TimeInterval? // Estimated reading time in seconds
    var wordCount: Int? // Number of words in the document
    var pageCount: Int? // Number of pages if applicable
    
    // Document structure preservation
    var headings: [DocumentHeading]? // Extracted headings for navigation
    var codeBlocks: [CodeBlock]? // Extracted code blocks
    var tableOfContents: [TOCEntry]? // Generated table of contents
    var internalLinks: [InternalLink]? // Links within the document
    
    // Original fields
    var extractedLinks: [String]? // URLs of links found in this document
    var parentDocument: String? // URL of the document that led to this one
    var crawlDepth: Int? // Depth in the crawl hierarchy
    var importMethod: ImportMethod // How this document was imported
    var lastUpdateCheck: Date? // When we last checked for updates
    var contentHash: String? // Hash of content for change detection
    var wasRenderedWithJS: Bool // Whether JavaScript rendering was used
    
    // Extensibility support
    var customAttributes: [String: String]? // Flexible key-value pairs for future extensions
    
    init(
        title: String,
        sourceURL: String,
        filePath: String,
        fileSize: Int64,
        summary: String? = nil,
        tags: Set<String>? = nil,
        contentType: DocumentContentType = .markdown,
        language: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.sourceURL = sourceURL
        self.filePath = filePath
        self.dateImported = Date()
        self.dateLastAccessed = nil
        self.dateModified = nil
        self.fileSize = fileSize
        self.summary = summary
        self.tags = tags
        self.isFavorite = false
        self.accessCount = 0
        self.contentType = contentType
        self.language = language
        self.extractedLinks = nil
        self.parentDocument = nil
        self.crawlDepth = nil
        self.importMethod = .manual
        self.lastUpdateCheck = nil
        self.contentHash = nil
        self.wasRenderedWithJS = false
    }
    
    var displayTitle: String {
        return title.isEmpty ? URL(string: sourceURL)?.host ?? "Unknown Document" : title
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateImported)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedLastAccessed: String {
        guard let lastAccessed = dateLastAccessed else {
            return "Never"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastAccessed)
    }
    
    var isRecentlyAccessed: Bool {
        guard let lastAccessed = dateLastAccessed else {
            return false
        }
        
        let daysSinceAccess = Calendar.current.dateComponents([.day], from: lastAccessed, to: Date()).day ?? 0
        return daysSinceAccess <= 7
    }
    
    var tagsArray: [String] {
        return Array(tags ?? []).sorted()
    }
    
    mutating func recordAccess() {
        dateLastAccessed = Date()
        accessCount += 1
    }
    
    mutating func addTag(_ tag: String) {
        if tags == nil {
            tags = []
        }
        tags?.insert(tag.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    mutating func removeTag(_ tag: String) {
        tags?.remove(tag)
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
    
    func needsUpdateCheck(interval: TimeInterval) -> Bool {
        guard let lastCheck = lastUpdateCheck else { return true }
        return Date().timeIntervalSince(lastCheck) > interval
    }
    
    func shouldAllowReimport(newMethod: ImportMethod, enableDeepCrawl: Bool, jsRenderingEnabled: Bool) -> Bool {
        // Always allow if different import method
        if importMethod != newMethod { return true }
        
        // Allow if enabling JS rendering and we haven't used it before
        if jsRenderingEnabled && !wasRenderedWithJS { return true }
        
        return false
    }
}

extension DocumentMetaData {
    static func == (lhs: DocumentMetaData, rhs: DocumentMetaData) -> Bool {
        return lhs.id == rhs.id &&
               lhs.sourceURL == rhs.sourceURL &&
               lhs.filePath == rhs.filePath &&
               lhs.dateImported == rhs.dateImported &&
               lhs.contentHash == rhs.contentHash
    }
}

enum DocumentContentType: String, Codable, CaseIterable {
    case markdown = "markdown"
    case html = "html"
    case text = "text"
    case pdf = "pdf"
    case rtf = "rtf"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .markdown:
            return "Markdown"
        case .html:
            return "HTML"
        case .text:
            return "Plain Text"
        case .pdf:
            return "PDF"
        case .rtf:
            return "Rich Text"
        case .unknown:
            return "Unknown"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .markdown:
            return "md"
        case .html:
            return "html"
        case .text:
            return "txt"
        case .pdf:
            return "pdf"
        case .rtf:
            return "rtf"
        case .unknown:
            return ""
        }
    }
}

enum ImportMethod: String, Codable, CaseIterable {
    case manual = "manual"
    case update = "update"
    case jsRendering = "jsRendering"
    
    var displayName: String {
        switch self {
        case .manual:
            return "Manual Import"
        case .update:
            return "Content Update"
        case .jsRendering:
            return "JavaScript Rendering"
        }
    }
}
// New enums and structs for enhanced metadata

enum DocumentComplexity: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .expert:
            return "Expert"
        }
    }
}

enum DocumentAudience: String, Codable, CaseIterable {
    case developer = "developer"
    case designer = "designer"
    case manager = "manager"
    case endUser = "endUser"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .developer:
            return "Developer"
        case .designer:
            return "Designer"
        case .manager:
            return "Manager"
        case .endUser:
            return "End User"
        case .general:
            return "General"
        }
    }
}


// Document structure preservation models

struct DocumentHeading: Codable, Hashable, Identifiable {
    let id: UUID
    let level: Int
    let title: String
    let anchor: String
}

struct CodeBlock: Codable, Hashable, Identifiable {
    let id: UUID
    let language: String
    let code: String
}

struct TOCEntry: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let level: Int
    let anchor: String
}

struct InternalLink: Codable, Hashable, Identifiable {
    let id: UUID
    let target: String
    let label: String
}

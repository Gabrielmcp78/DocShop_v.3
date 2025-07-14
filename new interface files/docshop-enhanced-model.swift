import Foundation
import SwiftUI

// MARK: - Enhanced Document Model
struct Document: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let content: String
    let filePath: String
    let dateAdded: Date
    let dateModified: Date
    let fileSize: Int64
    
    // Enhanced metadata for organization
    var language: DocumentLanguage
    var framework: DocumentFramework
    var documentType: DocumentType
    var tags: Set<String>
    var tableOfContents: [TOCItem]
    var isBookmarked: Bool
    var accessCount: Int
    var lastAccessed: Date?
    
    // Computed properties for UI
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDateAdded: String {
        RelativeDateTimeFormatter().localizedString(for: dateAdded, relativeTo: Date())
    }
    
    var contentPreview: String {
        String(content.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var searchableText: String {
        "\(title) \(content) \(tags.joined(separator: " ")) \(language.rawValue) \(framework.rawValue)"
    }
}

// MARK: - Document Categories
enum DocumentLanguage: String, CaseIterable, Codable {
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case go = "Go"
    case rust = "Rust"
    case java = "Java"
    case csharp = "C#"
    case cpp = "C++"
    case ruby = "Ruby"
    case php = "PHP"
    case html = "HTML"
    case css = "CSS"
    case markdown = "Markdown"
    case shell = "Shell"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .swift: return .orange
        case .python: return .blue
        case .javascript: return .yellow
        case .typescript: return .blue
        case .go: return .cyan
        case .rust: return .orange
        case .java: return .red
        case .csharp: return .purple
        case .cpp: return .blue
        case .ruby: return .red
        case .php: return .purple
        case .html: return .orange
        case .css: return .blue
        case .markdown: return .gray
        case .shell: return .green
        case .unknown: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .python: return "snake.fill"
        case .javascript: return "curlybraces"
        case .typescript: return "curlybraces.square"
        case .go: return "go.forward"
        case .rust: return "gear"
        case .java: return "cup.and.saucer"
        case .csharp: return "number.square"
        case .cpp: return "plus.plus"
        case .ruby: return "gem"
        case .php: return "p.square"
        case .html: return "globe"
        case .css: return "paintbrush"
        case .markdown: return "text.alignleft"
        case .shell: return "terminal"
        case .unknown: return "doc"
        }
    }
}

enum DocumentFramework: String, CaseIterable, Codable {
    case swiftui = "SwiftUI"
    case uikit = "UIKit"
    case react = "React"
    case angular = "Angular"
    case vue = "Vue"
    case django = "Django"
    case flask = "Flask"
    case express = "Express"
    case spring = "Spring"
    case rails = "Rails"
    case laravel = "Laravel"
    case nextjs = "Next.js"
    case nuxtjs = "Nuxt.js"
    case flutter = "Flutter"
    case reactNative = "React Native"
    case xamarin = "Xamarin"
    case none = "None"
    
    var color: Color {
        switch self {
        case .swiftui: return .blue
        case .uikit: return .orange
        case .react: return .cyan
        case .angular: return .red
        case .vue: return .green
        case .django: return .green
        case .flask: return .gray
        case .express: return .yellow
        case .spring: return .green
        case .rails: return .red
        case .laravel: return .orange
        case .nextjs: return .black
        case .nuxtjs: return .green
        case .flutter: return .blue
        case .reactNative: return .cyan
        case .xamarin: return .purple
        case .none: return .gray
        }
    }
}

enum DocumentType: String, CaseIterable, Codable {
    case apiReference = "API Reference"
    case tutorial = "Tutorial"
    case guide = "Guide"
    case documentation = "Documentation"
    case codeExample = "Code Example"
    case cheatSheet = "Cheat Sheet"
    case specification = "Specification"
    case troubleshooting = "Troubleshooting"
    case changelog = "Changelog"
    case readme = "README"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .apiReference: return "books.vertical"
        case .tutorial: return "graduationcap"
        case .guide: return "map"
        case .documentation: return "doc.text"
        case .codeExample: return "chevron.left.forwardslash.chevron.right"
        case .cheatSheet: return "list.bullet.rectangle"
        case .specification: return "doc.plaintext"
        case .troubleshooting: return "wrench.and.screwdriver"
        case .changelog: return "clock.arrow.circlepath"
        case .readme: return "info.circle"
        case .unknown: return "questionmark.diamond"
        }
    }
}

// MARK: - Table of Contents
struct TOCItem: Codable, Hashable {
    let title: String
    let level: Int
    let lineNumber: Int?
    
    var indentedTitle: String {
        String(repeating: "  ", count: max(0, level - 1)) + title
    }
}

// MARK: - View Modes
enum LibraryViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    case categories = "Categories"
    case recent = "Recent"
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .categories: return "folder"
        case .recent: return "clock"
        }
    }
}

// MARK: - Filter Options
struct DocumentFilters {
    var searchText: String = ""
    var selectedLanguages: Set<DocumentLanguage> = []
    var selectedFrameworks: Set<DocumentFramework> = []
    var selectedTypes: Set<DocumentType> = []
    var showBookmarkedOnly: Bool = false
    var sortBy: SortOption = .dateAdded
    var sortOrder: SortOrder = .descending
    
    enum SortOption: String, CaseIterable {
        case title = "Title"
        case dateAdded = "Date Added"
        case dateModified = "Date Modified"
        case accessCount = "Access Count"
        case fileSize = "File Size"
        case relevance = "Relevance"
        
        var icon: String {
            switch self {
            case .title: return "textformat.abc"
            case .dateAdded: return "calendar.badge.plus"
            case .dateModified: return "calendar.badge.clock"
            case .accessCount: return "eye"
            case .fileSize: return "doc"
            case .relevance: return "star"
            }
        }
    }
    
    enum SortOrder {
        case ascending, descending
        
        var icon: String {
            switch self {
            case .ascending: return "arrow.up"
            case .descending: return "arrow.down"
            }
        }
    }
}

// MARK: - Document Analytics
struct DocumentAnalytics {
    var totalDocuments: Int
    var languageDistribution: [DocumentLanguage: Int]
    var frameworkDistribution: [DocumentFramework: Int]
    var typeDistribution: [DocumentType: Int]
    var recentlyAdded: [Document]
    var mostAccessed: [Document]
    var bookmarkedCount: Int
    
    static func from(documents: [Document]) -> DocumentAnalytics {
        let languageDist = Dictionary(grouping: documents, by: \.language)
            .mapValues { $0.count }
        let frameworkDist = Dictionary(grouping: documents, by: \.framework)
            .mapValues { $0.count }
        let typeDist = Dictionary(grouping: documents, by: \.documentType)
            .mapValues { $0.count }
        
        let recentDocs = documents
            .sorted { $0.dateAdded > $1.dateAdded }
            .prefix(10)
            .map { $0 }
        
        let mostAccessedDocs = documents
            .sorted { $0.accessCount > $1.accessCount }
            .prefix(10)
            .map { $0 }
        
        return DocumentAnalytics(
            totalDocuments: documents.count,
            languageDistribution: languageDist,
            frameworkDistribution: frameworkDist,
            typeDistribution: typeDist,
            recentlyAdded: recentDocs,
            mostAccessed: mostAccessedDocs,
            bookmarkedCount: documents.filter(\.isBookmarked).count
        )
    }
}
import Foundation
import SwiftSoup

/// Smart document processor that preserves document structure and creates functional navigation
class SmartDocumentProcessor {
    static let shared = SmartDocumentProcessor()
    
    private init() {}
    
    func processDocumentationPage(html: String, sourceURL: URL) async throws -> ProcessedDocument {
        let doc = try SwiftSoup.parse(html)
        
        // Extract the main documentation content
        let mainContent = try extractDocumentationContent(from: doc)
        
        // Build the document structure
        let structure = try buildDocumentStructure(from: mainContent, sourceURL: sourceURL)
        
        // Create clean markdown with functional navigation
        let markdown = try createStructuredMarkdown(from: structure)
        
        return ProcessedDocument(
            title: structure.title,
            markdown: markdown,
            structure: structure,
            navigationItems: structure.sections.map { NavigationItem(title: $0.title, anchor: $0.anchor, level: $0.level) }
        )
    }
    
    private func extractDocumentationContent(from doc: Document) throws -> Element {
        // Try documentation-specific selectors first
        let docSelectors = [
            "main[role='main']",
            ".documentation-content",
            ".doc-content",
            ".content-wrapper",
            "article",
            "main",
            "#content",
            ".main-content"
        ]
        
        for selector in docSelectors {
            if let element = try doc.select(selector).first() {
                try cleanDocumentationContent(element)
                return element
            }
        }
        
        // Fallback to body but clean it heavily
        guard let body = doc.body() else {
            throw DocumentError.contentExtractionFailed("No content found")
        }
        
        try cleanDocumentationContent(body)
        return body
    }
    
    private func cleanDocumentationContent(_ element: Element) throws {
        // Remove navigation, headers, footers
        let unwantedSelectors = [
            "nav", ".nav", ".navigation", ".navbar",
            "header", ".header", "footer", ".footer",
            ".sidebar", ".aside", ".toc-sidebar",
            ".breadcrumb", ".breadcrumbs",
            ".advertisement", ".ads", ".banner",
            ".search-box", ".search-form",
            "script", "style", "noscript"
        ]
        
        for selector in unwantedSelectors {
            try element.select(selector).remove()
        }
        
        // Remove excessive code blocks (installation scripts, etc.)
        let codeBlocks = try element.select("pre, .highlight, .code-block")
        for codeBlock in codeBlocks {
            let codeText = try codeBlock.text()
            
            // Remove if it's a long installation script or command dump
            if shouldRemoveCodeBlock(codeText) {
                try codeBlock.remove()
            }
        }
        
        // Clean up links - preserve internal navigation but mark external
        let links = try element.select("a[href]")
        for link in links {
            let href = try link.attr("href")
            let linkText = try link.text()
            
            if href.hasPrefix("#") {
                // Internal navigation link - preserve but mark
                try link.attr("data-internal", "true")
            } else if !href.hasPrefix("http") && !href.isEmpty {
                // Relative link - could be internal navigation
                try link.attr("data-relative", "true")
            }
        }
    }
    
    private func shouldRemoveCodeBlock(_ codeText: String) -> Bool {
        let text = codeText.lowercased()
        
        // Remove if it's a long installation script
        if codeText.count > 300 && (
            text.contains("curl") && text.contains("install") ||
            text.contains("wget") && text.contains("download") ||
            text.contains("pip install") && text.contains("--upgrade") ||
            text.contains("npm install") && text.contains("global") ||
            text.contains("brew install") ||
            text.contains("apt-get install") ||
            text.contains("rm -rf") && text.contains("$HOME") ||
            text.contains("echo") && text.contains(">>") && text.contains("bashrc")
        ) {
            return true
        }
        
        // Remove if it's just a bunch of shell commands without context
        let lines = codeText.components(separatedBy: .newlines)
        let commandLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.hasPrefix("$") || trimmed.hasPrefix("PS>") || trimmed.hasPrefix("curl") || trimmed.hasPrefix("wget")
        }
        
        // If more than 70% of lines are commands, it's probably a command dump
        if lines.count > 5 && Double(commandLines.count) / Double(lines.count) > 0.7 {
            return true
        }
        
        return false
    }
    
    private func buildDocumentStructure(from element: Element, sourceURL: URL) throws -> DocumentStructure {
        let title = try extractDocumentTitle(from: element, sourceURL: sourceURL)
        var sections: [DocumentSection] = []
        
        // Extract headings and build structure
        let headings = try element.select("h1, h2, h3, h4, h5, h6")
        var currentSection: DocumentSection?
        var sectionContent = ""
        
        for heading in headings {
            let level = Int(heading.tagName().dropFirst()) ?? 1
            let headingText = try heading.text().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip if it's the main title or empty
            if headingText.isEmpty || headingText.lowercased() == title.lowercased() {
                continue
            }
            
            // Save previous section if exists
            if let current = currentSection {
                sections.append(DocumentSection(
                    title: current.title,
                    level: current.level,
                    anchor: current.anchor,
                    content: sectionContent.trimmingCharacters(in: .whitespacesAndNewlines)
                ))
            }
            
            // Start new section
            let anchor = createAnchor(from: headingText)
            currentSection = DocumentSection(
                title: headingText,
                level: level,
                anchor: anchor,
                content: ""
            )
            sectionContent = ""
            
            // Extract content for this section
            var nextElement = heading.nextElementSibling()
            while let element = nextElement {
                let tagName = element.tagName().lowercased()
                
                // Stop if we hit another heading of same or higher level
                if tagName.hasPrefix("h") {
                    let nextLevel = Int(tagName.dropFirst()) ?? 6
                    if nextLevel <= level {
                        break
                    }
                }
                
                // Add content
                let elementText = try element.text()
                if !elementText.isEmpty {
                    sectionContent += elementText + "\n\n"
                }
                
                nextElement = element.nextElementSibling()
            }
        }
        
        // Add final section
        if let current = currentSection {
            sections.append(DocumentSection(
                title: current.title,
                level: current.level,
                anchor: current.anchor,
                content: sectionContent.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        
        return DocumentStructure(
            title: title,
            sourceURL: sourceURL.absoluteString,
            sections: sections
        )
    }
    
    private func extractDocumentTitle(from element: Element, sourceURL: URL) throws -> String {
        // Try to find the main title
        if let h1 = try element.select("h1").first() {
            let title = try h1.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                return title
            }
        }
        
        // Fallback to URL-based title
        let pathComponents = sourceURL.pathComponents
        if pathComponents.count > 1 {
            let lastComponent = pathComponents.last ?? ""
            return lastComponent.replacingOccurrences(of: "-", with: " ").capitalized
        }
        
        return sourceURL.host?.capitalized ?? "Documentation"
    }
    
    private func createAnchor(from text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
    }
    
    private func createStructuredMarkdown(from structure: DocumentStructure) throws -> String {
        var markdown = "# \(structure.title)\n\n"
        
        // Add table of contents if there are multiple sections
        if structure.sections.count > 1 {
            markdown += "## Table of Contents\n\n"
            for section in structure.sections {
                let indent = String(repeating: "  ", count: max(0, section.level - 2))
                markdown += "\(indent)- [\(section.title)](#\(section.anchor))\n"
            }
            markdown += "\n"
        }
        
        // Add sections
        for section in structure.sections {
            let headerLevel = String(repeating: "#", count: section.level)
            markdown += "\(headerLevel) \(section.title) {#\(section.anchor)}\n\n"
            
            if !section.content.isEmpty {
                markdown += "\(section.content)\n\n"
            }
        }
        
        return markdown
    }
}

// MARK: - Supporting Types

struct ProcessedDocument {
    let title: String
    let markdown: String
    let structure: DocumentStructure
    let navigationItems: [NavigationItem]
}

struct DocumentStructure {
    let title: String
    let sourceURL: String
    let sections: [DocumentSection]
}

struct DocumentSection {
    let title: String
    let level: Int
    let anchor: String
    let content: String
}

struct NavigationItem {
    let title: String
    let anchor: String
    let level: Int
}
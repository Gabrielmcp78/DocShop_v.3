import Foundation
import CryptoKit

class SmartDuplicateHandler {
    static let shared = SmartDuplicateHandler()
    
    private let config = DocumentProcessorConfig.shared
    private let library = DocLibraryIndex.shared
    private let logger = DocumentLogger.shared
    
    private init() {}
    
    func shouldAllowImport(
        url: URL,
        importMethod: ImportMethod,
        content: String? = nil,
        jsRenderingEnabled: Bool = false
    ) async -> DuplicateDecision {
        
        let urlString = url.absoluteString
        
        // Check if document already exists
        guard let existingDoc = library.documents.first(where: { $0.sourceURL == urlString }) else {
            // No existing document, allow import
            return .allow(.newDocument)
        }
        
        // If duplicates are explicitly allowed, always allow
        if config.allowDuplicates {
            return .allow(.duplicatesEnabled)
        }
        
        // If smart duplicate handling is disabled, block
        if !config.smartDuplicateHandling {
            return .block(.duplicateExists(existingDoc))
        }
        
        // Smart duplicate handling logic
        return await evaluateSmartDuplicate(
            existingDoc: existingDoc,
            newImportMethod: importMethod,
            newContent: content,
            jsRenderingEnabled: jsRenderingEnabled
        )
    }
    
    private func evaluateSmartDuplicate(
        existingDoc: DocumentMetaData,
        newImportMethod: ImportMethod,
        newContent: String?,
        jsRenderingEnabled: Bool
    ) async -> DuplicateDecision {
        
        var reasons: [AllowReason] = []
        
        // Check if import method is different
        if existingDoc.importMethod != newImportMethod {
            reasons.append(.differentImportMethod(from: existingDoc.importMethod, to: newImportMethod))
        }
        
        // Check if enabling JavaScript rendering for the first time
        if jsRenderingEnabled && !existingDoc.wasRenderedWithJS {
            reasons.append(.enabledJavaScriptRendering)
        }
        
        // Check if content has been updated (if we have new content to compare)
        if let newContent = newContent,
           config.checkForUpdates,
           let existingHash = existingDoc.contentHash {
            
            let newHash = generateContentHash(newContent)
            if newHash != existingHash {
                reasons.append(.contentUpdated)
            }
        }
        
        // Check if it's time for an update check
        if config.checkForUpdates && existingDoc.needsUpdateCheck(interval: config.updateCheckInterval) {
            reasons.append(.scheduledUpdateCheck)
        }
        
        if !reasons.isEmpty {
            return .allow(.smartDuplicateReasons(reasons))
        } else {
            return .block(.duplicateExists(existingDoc))
        }
    }
    
    func generateContentHash(_ content: String) -> String {
        let data = content.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func updateDocumentForReimport(
        _ document: inout DocumentMetaData,
        newMethod: ImportMethod,
        newContent: String,
        jsRenderingUsed: Bool
    ) {
        document.importMethod = newMethod
        document.lastUpdateCheck = Date()
        document.contentHash = generateContentHash(newContent)
        document.wasRenderedWithJS = jsRenderingUsed
        document.dateModified = Date()
    }
}

// MARK: - Decision Types

enum DuplicateDecision {
    case allow(AllowReason)
    case block(BlockReason)
    case prompt(PromptReason)
    
    var shouldAllow: Bool {
        switch self {
        case .allow:
            return true
        case .block, .prompt:
            return false
        }
    }
    
    var message: String {
        switch self {
        case .allow(let reason):
            return reason.message
        case .block(let reason):
            return reason.message
        case .prompt(let reason):
            return reason.message
        }
    }
}

enum AllowReason {
    case newDocument
    case duplicatesEnabled
    case differentImportMethod(from: ImportMethod, to: ImportMethod)
    case enabledJavaScriptRendering
    case contentUpdated
    case scheduledUpdateCheck
    case smartDuplicateReasons([AllowReason])
    
    var message: String {
        switch self {
        case .newDocument:
            return "New document - importing"
        case .duplicatesEnabled:
            return "Duplicates allowed in settings"
        case .differentImportMethod(let from, let to):
            return "Import method changed from \(from.displayName) to \(to.displayName)"
        case .enabledJavaScriptRendering:
            return "JavaScript rendering enabled - re-importing for complete content"
        case .contentUpdated:
            return "Content has been updated since last import"
        case .scheduledUpdateCheck:
            return "Scheduled update check - checking for new content"
        case .smartDuplicateReasons(let reasons):
            return "Smart duplicate handling: \(reasons.map { $0.message }.joined(separator: ", "))"
        }
    }
}

enum BlockReason {
    case duplicateExists(DocumentMetaData)
    
    var message: String {
        switch self {
        case .duplicateExists(let doc):
            return "Document already exists (imported \(doc.formattedDate))"
        }
    }
}

enum PromptReason {
    case userConfirmationNeeded(DocumentMetaData, [AllowReason])
    
    var message: String {
        switch self {
        case .userConfirmationNeeded(_, let reasons):
            return "Document exists. Re-import? Reasons: \(reasons.map { $0.message }.joined(separator: ", "))"
        }
    }
}


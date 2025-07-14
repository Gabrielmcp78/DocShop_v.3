import Foundation
import SwiftUI
import Combine
import CryptoKit

class DocLibraryIndex: ObservableObject {
    static let shared = DocLibraryIndex()
    
    @Published var documents: [DocumentMetaData] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var searchResults: [DocumentMetaData] = []
    
    private let indexFileURL: URL
    private let backupIndexURL: URL
    private let logger = DocumentLogger.shared
    private let indexQueue = DispatchQueue(label: "library.index", qos: .userInitiated)
    
    private init() {
        let documentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("DocShop/Resources")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        
        self.indexFileURL = documentsPath.appendingPathComponent("DocLibraryIndex.json")
        self.backupIndexURL = documentsPath.appendingPathComponent("DocLibraryIndex_backup.json")
        
        loadDocuments()
    }
    
    func addDocument(_ document: DocumentMetaData) {
        // Check for duplicates
        if let existingIndex = documents.firstIndex(where: { $0.sourceURL == document.sourceURL }) {
            DispatchQueue.main.async {
                if existingIndex < self.documents.count {
                    self.documents[existingIndex] = document
                } else {
                    self.documents.append(document)
                }
            }
            logger.info("Updated existing document: \(document.title)")
        } else {
            DispatchQueue.main.async {
                self.documents.append(document)
            }
            logger.info("Added new document: \(document.title)")
        }
        saveDocuments()
    }
    
    func removeDocument(_ document: DocumentMetaData) {
        DispatchQueue.main.async {
            self.documents.removeAll { $0.id == document.id }
        }
        logger.info("Removed document: \(document.title)")
        saveDocuments()
    }
    
    func updateDocument(_ document: DocumentMetaData) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            DispatchQueue.main.async {
                self.documents[index] = document
            }
            logger.info("Updated document: \(document.title)")
            saveDocuments()
        }
    }
    
    private func loadDocuments() {
        guard FileManager.default.fileExists(atPath: indexFileURL.path) else {
            logger.info("No existing document index found, starting fresh")
            return
        }
        
        do {
            let data = try Data(contentsOf: indexFileURL)
            
            // Verify index integrity
            if isIndexCorrupted(data) {
                logger.warning("Main index appears corrupted, attempting recovery")
                try recoverFromBackup()
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedDocuments = try decoder.decode([DocumentMetaData].self, from: data)
            
            // Validate document files still exist
            var validDocuments = loadedDocuments
            var invalidDocuments: [DocumentMetaData] = []
            for document in loadedDocuments {
                let fileURL = URL(fileURLWithPath: document.filePath)
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    invalidDocuments.append(document)
                    logger.warning("Document file missing: \(document.title) at \(document.filePath)")
                }
            }
            if !invalidDocuments.isEmpty {
                validDocuments.removeAll { doc in
                    invalidDocuments.contains { $0.id == doc.id }
                }
                saveDocuments()
                logger.info("Removed \(invalidDocuments.count) documents with missing files")
            }
            
            DispatchQueue.main.async {
                self.documents = validDocuments
            }
            
            logger.info("Loaded \(validDocuments.count) documents from index")
        } catch {
            logger.error("Failed to load document index: \(error)")
            DispatchQueue.main.async {
                self.lastError = "Failed to load document library: \(error.localizedDescription)"
            }
            
            // Attempt recovery
            do {
                try recoverFromBackup()
            } catch {
                logger.error("Failed to recover from backup: \(error)")
            }
        }
    }
    
    private func saveDocuments() {
        indexQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let data = try encoder.encode(self.documents)
                
                // Create backup before saving
                if FileManager.default.fileExists(atPath: self.indexFileURL.path) {
                    try? FileManager.default.copyItem(at: self.indexFileURL, to: self.backupIndexURL)
                }
                
                // Atomic write
                let tempURL = self.indexFileURL.appendingPathExtension("tmp")
                try data.write(to: tempURL)
                
                // Replace original with temp file
                if FileManager.default.fileExists(atPath: self.indexFileURL.path) {
                    try FileManager.default.removeItem(at: self.indexFileURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: self.indexFileURL)
                
                DispatchQueue.main.async {
                    self.logger.info("Saved \(self.documents.count) documents to index")
                }
            } catch {
                DispatchQueue.main.async {
                    self.logger.error("Failed to save document index: \(error)")
                    self.lastError = "Failed to save document library: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshLibrary() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        loadDocuments()
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func searchDocuments(query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        let lowercaseQuery = query.lowercased()
        let filtered = documents.filter { document in
            document.title.lowercased().contains(lowercaseQuery) ||
            document.sourceURL.lowercased().contains(lowercaseQuery) ||
            (document.summary?.lowercased().contains(lowercaseQuery) ?? false)
        }
        DispatchQueue.main.async {
            self.searchResults = filtered
        }
    }
    
    func getDocumentsByTag(_ tag: String) -> [DocumentMetaData] {
        return documents.filter { document in
            document.tags?.contains(tag) ?? false
        }
    }
    
    func addTagToDocument(_ documentId: UUID, tag: String) {
        if let index = documents.firstIndex(where: { $0.id == documentId }) {
            var updatedDocument = documents[index]
            if updatedDocument.tags == nil {
                updatedDocument.tags = []
            }
            updatedDocument.tags?.insert(tag)
            DispatchQueue.main.async {
                self.documents[index] = updatedDocument
            }
            saveDocuments()
        }
    }
    
    func removeTagFromDocument(_ documentId: UUID, tag: String) {
        if let index = documents.firstIndex(where: { $0.id == documentId }) {
            var updatedDocument = documents[index]
            updatedDocument.tags?.remove(tag)
            DispatchQueue.main.async {
                self.documents[index] = updatedDocument
            }
            saveDocuments()
        }
    }
    
    private func isIndexCorrupted(_ data: Data) -> Bool {
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return false
        } catch {
            return true
        }
    }
    
    private func recoverFromBackup() throws {
        guard FileManager.default.fileExists(atPath: backupIndexURL.path) else {
            throw LibraryError.noBackupAvailable
        }
        
        let backupData = try Data(contentsOf: backupIndexURL)
        
        if isIndexCorrupted(backupData) {
            throw LibraryError.backupCorrupted
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let recoveredDocuments = try decoder.decode([DocumentMetaData].self, from: backupData)
        
        try backupData.write(to: indexFileURL)
        
        DispatchQueue.main.async {
            self.documents = recoveredDocuments
        }
        
        logger.info("Recovered \(recoveredDocuments.count) documents from backup")
    }
    
    private func validateDocumentFiles() {
        var invalidDocuments: [DocumentMetaData] = []
        
        for document in documents {
            let fileURL = URL(fileURLWithPath: document.filePath)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                invalidDocuments.append(document)
                logger.warning("Document file missing: \(document.title) at \(document.filePath)")
            }
        }
        
        if !invalidDocuments.isEmpty {
            DispatchQueue.main.async {
                self.documents.removeAll { document in
                    invalidDocuments.contains { $0.id == document.id }
                }
            }
            saveDocuments()
            logger.info("Removed \(invalidDocuments.count) documents with missing files")
        }
    }
    
    func exportLibrary() throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(documents)
        
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DocShop_Library_Export_\(Int(Date().timeIntervalSince1970)).json")
        
        try data.write(to: exportURL)
        
        logger.info("Exported library to: \(exportURL.path)")
        return exportURL
    }
    
    func importLibrary(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedDocuments = try decoder.decode([DocumentMetaData].self, from: data)
        
        for document in importedDocuments {
            addDocument(document)
        }
        
        logger.info("Imported \(importedDocuments.count) documents from \(url.lastPathComponent)")
    }
}

enum LibraryError: LocalizedError {
    case noBackupAvailable
    case backupCorrupted
    case exportFailed
    case importFailed
    
    var errorDescription: String? {
        switch self {
        case .noBackupAvailable:
            return "No backup index available for recovery"
        case .backupCorrupted:
            return "Backup index is also corrupted"
        case .exportFailed:
            return "Failed to export library"
        case .importFailed:
            return "Failed to import library"
        }
    }
}

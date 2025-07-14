import Foundation
import CryptoKit

class DocumentStorage {
    static let shared = DocumentStorage()
    
    private let documentsFolder: URL
    private let backupFolder: URL
    private let logger = DocumentLogger.shared
    private let storageQueue = DispatchQueue(label: "document.storage", qos: .userInitiated)
    
    private init() {
        self.documentsFolder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("DocShop/Docs/Imported")
        
        self.backupFolder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("DocShop/Backups")
        
        // Ensure directories exist
        try? FileManager.default.createDirectory(at: documentsFolder, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)
    }
    
    func saveDocument(content: String, filename: String) throws -> URL {
        let fileURL = documentsFolder.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Create backup
            let backupURL = backupFolder.appendingPathComponent(filename)
            try content.write(to: backupURL, atomically: true, encoding: .utf8)
            
            // Generate and store checksum
            let checksum = generateChecksum(for: content)
            try storeChecksum(checksum, for: fileURL)
            
            logger.info("Document saved successfully: \(filename)")
            return fileURL
        } catch {
            logger.error("Failed to save document \(filename): \(error)")
            throw DocumentStorageError.saveFailed(error)
        }
    }
    
    func loadDocument(at url: URL) throws -> String {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // Verify checksum if available
            if let storedChecksum = getStoredChecksum(for: url) {
                let currentChecksum = generateChecksum(for: content)
                if storedChecksum != currentChecksum {
                    logger.warning("Checksum mismatch for \(url.lastPathComponent), attempting recovery")
                    return try recoverDocument(at: url)
                }
            }
            
            return content
        } catch {
            logger.error("Failed to load document \(url.lastPathComponent): \(error)")
            
            // Attempt recovery from backup
            return try recoverDocument(at: url)
        }
    }
    
    func deleteDocument(at url: URL) throws {
        do {
            let filename = url.lastPathComponent
            
            // Remove main document
            try FileManager.default.removeItem(at: url)
            
            // Remove backup
            let backupURL = backupFolder.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }
            
            // Remove checksum
            removeChecksum(for: url)
            
            logger.info("Document deleted successfully: \(filename)")
        } catch {
            logger.error("Failed to delete document \(url.lastPathComponent): \(error)")
            throw DocumentStorageError.deleteFailed(error)
        }
    }
    
    func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func generateUniqueFilename(for sourceURL: URL, extension: String = "md") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let host = sourceURL.host ?? "unknown"
        let sanitizedHost = host.replacingOccurrences(of: "[^a-zA-Z0-9.-]", with: "_", options: .regularExpression)
        
        var filename = "\(timestamp)_\(sanitizedHost).\(`extension`)"
        var counter = 1
        
        while FileManager.default.fileExists(atPath: documentsFolder.appendingPathComponent(filename).path) {
            filename = "\(timestamp)_\(sanitizedHost)_\(counter).\(`extension`)"
            counter += 1
        }
        
        return filename
    }
    
    func listAllDocuments() -> [URL] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsFolder, includingPropertiesForKeys: nil)
            return contents.filter { $0.pathExtension == "md" }
        } catch {
            logger.error("Failed to list documents: \(error)")
            return []
        }
    }
    
    private func generateChecksum(for content: String) -> String {
        let data = content.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func storeChecksum(_ checksum: String, for fileURL: URL) throws {
        let checksumURL = getChecksumURL(for: fileURL)
        try checksum.write(to: checksumURL, atomically: true, encoding: .utf8)
    }
    
    private func getStoredChecksum(for fileURL: URL) -> String? {
        let checksumURL = getChecksumURL(for: fileURL)
        return try? String(contentsOf: checksumURL, encoding: .utf8)
    }
    
    private func removeChecksum(for fileURL: URL) {
        let checksumURL = getChecksumURL(for: fileURL)
        try? FileManager.default.removeItem(at: checksumURL)
    }
    
    private func getChecksumURL(for fileURL: URL) -> URL {
        let checksumFolder = documentsFolder.appendingPathComponent(".checksums")
        try? FileManager.default.createDirectory(at: checksumFolder, withIntermediateDirectories: true)
        return checksumFolder.appendingPathComponent(fileURL.lastPathComponent + ".checksum")
    }
    
    private func recoverDocument(at url: URL) throws -> String {
        let backupURL = backupFolder.appendingPathComponent(url.lastPathComponent)
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw DocumentStorageError.recoveryFailed("No backup available")
        }
        
        do {
            let content = try String(contentsOf: backupURL, encoding: .utf8)
            
            // Restore main document from backup
            try content.write(to: url, atomically: true, encoding: .utf8)
            
            // Update checksum
            let checksum = generateChecksum(for: content)
            try storeChecksum(checksum, for: url)
            
            logger.info("Document recovered from backup: \(url.lastPathComponent)")
            return content
        } catch {
            throw DocumentStorageError.recoveryFailed(error.localizedDescription)
        }
    }
    
    func cleanupOrphanedFiles() {
        storageQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                _ = try FileManager.default
                    .contentsOfDirectory(
                        at: self.documentsFolder,
                        includingPropertiesForKeys: nil
                    )
                let backupFiles = try FileManager.default.contentsOfDirectory(at: self.backupFolder, includingPropertiesForKeys: nil)
                
                // Remove backup files that don't have corresponding main files
                for backupFile in backupFiles {
                    let correspondingMainFile = self.documentsFolder.appendingPathComponent(backupFile.lastPathComponent)
                    if !FileManager.default.fileExists(atPath: correspondingMainFile.path) {
                        try? FileManager.default.removeItem(at: backupFile)
                        self.logger.info("Removed orphaned backup: \(backupFile.lastPathComponent)")
                    }
                }
            } catch {
                self.logger.error("Failed to cleanup orphaned files: \(error)")
            }
        }
    }
}

enum DocumentStorageError: LocalizedError {
    case saveFailed(Error)
    case deleteFailed(Error)
    case recoveryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save document: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete document: \(error.localizedDescription)"
        case .recoveryFailed(let message):
            return "Failed to recover document: \(message)"
        }
    }
}

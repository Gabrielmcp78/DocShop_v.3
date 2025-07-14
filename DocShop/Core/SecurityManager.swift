import Foundation
import CryptoKit

class SecurityManager {
    static let shared = SecurityManager()
    
    private let logger = DocumentLogger.shared
    private let allowedFileExtensions: Set<String> = ["md", "txt", "html", "rtf", "pdf"]
    private let maxPathLength = 1024
    private let maxFilenameLength = 255
    private let trustedDomains: Set<String> = [
        "github.com",
        "docs.github.com",
        "developer.apple.com",
        "developer.mozilla.org",
        "docs.microsoft.com",
        "docs.python.org",
        "nodejs.org",
        "rust-lang.org",
        "kotlinlang.org",
        "swift.org",
        "stackoverflow.com",
        "medium.com",
        "wikipedia.org",
        "en.wikipedia.org"
    ]
    
    private init() {}
    
    func validateURL(_ url: URL) throws {
        guard url.scheme == "http" || url.scheme == "https" else {
            throw SecurityError.unsupportedScheme(url.scheme ?? "none")
        }
        
        guard let host = url.host, !host.isEmpty else {
            throw SecurityError.invalidHost
        }
        
        // Check if this is a trusted domain - if so, skip most security checks
        let isTrustedDomain = trustedDomains.contains { trusted in
            host.hasSuffix(trusted) || host == trusted
        }
        
        if isTrustedDomain {
            logger.debug("URL validation passed for trusted domain: \(host)")
            return
        }
        
        // Check for suspicious patterns (only block truly dangerous URLs)
        let suspiciousPatterns = [
            "file://",
            "ftp://",
            "data:text/html",
            "javascript:",
            "vbscript:"
        ]
        
        let urlString = url.absoluteString.lowercased()
        for pattern in suspiciousPatterns {
            if urlString.contains(pattern) {
                throw SecurityError.suspiciousURL(pattern)
            }
        }
        
        // Allow localhost for development but warn about it
        if urlString.contains("localhost") || urlString.contains("127.0.0.1") || urlString.contains("0.0.0.0") {
            logger.warning("Allowing localhost URL for development: \(host)")
        }
        
        // Check URL length
        if urlString.count > 2048 {
            throw SecurityError.urlTooLong
        }
        
        logger.debug("URL validation passed for: \(host)")
    }
    
    func isTrustedDomain(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return trustedDomains.contains { trusted in
            host.hasSuffix(trusted) || host == trusted
        }
    }
    
    func validateFilePath(_ path: String) throws {
        guard !path.isEmpty else {
            throw SecurityError.emptyPath
        }
        
        guard path.count <= maxPathLength else {
            throw SecurityError.pathTooLong
        }
        
        let url = URL(fileURLWithPath: path)
        let filename = url.lastPathComponent
        
        guard filename.count <= maxFilenameLength else {
            throw SecurityError.filenameTooLong
        }
        
        // Check for path traversal attempts
        let dangerousPatterns = ["../", "..\\", "~/", "%2e%2e", "//"]
        for pattern in dangerousPatterns {
            if path.lowercased().contains(pattern) {
                throw SecurityError.pathTraversalAttempt
            }
        }
        
        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        if !fileExtension.isEmpty && !allowedFileExtensions.contains(fileExtension) {
            throw SecurityError.unsupportedFileType(fileExtension)
        }
        
        // Ensure path is within app sandbox
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let docShopPath = homePath + "/DocShop"
        
        if !path.hasPrefix(docShopPath) {
            throw SecurityError.pathOutsideSandbox
        }
        
        logger.debug("File path validation passed for: \(filename)")
    }
    
    func sanitizeFilename(_ filename: String) -> String {
        var sanitized = filename
        
        // Remove or replace dangerous characters
        let dangerousChars = CharacterSet(charactersIn: "<>:\"/\\|?*")
        sanitized = sanitized.components(separatedBy: dangerousChars).joined(separator: "_")
        
        // Remove control characters
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        
        // Limit length
        if sanitized.count > maxFilenameLength {
            let ext = URL(fileURLWithPath: sanitized).pathExtension
            let nameWithoutExt = URL(fileURLWithPath: sanitized).deletingPathExtension().lastPathComponent
            let maxNameLength = maxFilenameLength - ext.count - 1
            
            if maxNameLength > 0 {
                let truncatedName = String(nameWithoutExt.prefix(maxNameLength))
                sanitized = ext.isEmpty ? truncatedName : "\(truncatedName).\(ext)"
            } else {
                sanitized = "document.\(ext.isEmpty ? "txt" : ext)"
            }
        }
        
        // Ensure filename is not empty or just dots
        if sanitized.isEmpty || sanitized.allSatisfy({ $0 == "." }) {
            sanitized = "document.txt"
        }
        
        return sanitized
    }
    
    func validateContentSize(_ size: Int) throws {
        let config = DocumentProcessorConfig.shared
        
        guard size > 0 else {
            throw SecurityError.emptyContent
        }
        
        guard size <= config.maxDocumentSize else {
            throw SecurityError.contentTooLarge(size)
        }
        
        logger.debug("Content size validation passed: \(size) bytes")
    }
    
    func scanContentForThreats(_ content: String, fromTrustedDomain: Bool = false) throws {
        // Skip most security checks for trusted domains
        if fromTrustedDomain {
            logger.debug("Content threat scan skipped for trusted domain")
            return
        }
        
        // Only scan for truly dangerous patterns that shouldn't appear in documentation
        let dangerousPatterns = [
            "javascript:alert(",
            "javascript:eval(",
            "document.cookie",
            "window.location.href",
            "<script>alert(",
            "<script>eval(",
            "vbscript:",
            "data:text/html,<script",
            "file:///etc/passwd",
            "file:///windows/system32"
        ]
        
        let lowercaseContent = content.lowercased()
        for pattern in dangerousPatterns {
            if lowercaseContent.contains(pattern) {
                logger.warning("Dangerous content pattern detected: \(pattern)")
                throw SecurityError.suspiciousContent(pattern)
            }
        }
        
        // Check for excessive repetition (potential DoS)
        if content.count > 1000 {
            let sampleSize = min(100, content.count)
            let sample = String(content.prefix(sampleSize))
            let uniqueChars = Set(sample)
            
            if uniqueChars.count < 5 { // Too few unique characters
                throw SecurityError.suspiciousContent("excessive repetition")
            }
        }
        
        logger.debug("Content threat scan passed")
    }
    
    func generateSecureToken() -> String {
        let tokenData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return tokenData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    func hashContent(_ content: String) -> String {
        let data = content.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func isPathSafe(_ path: String) -> Bool {
        do {
            try validateFilePath(path)
            return true
        } catch {
            return false
        }
    }
    
    func createSecureDirectory(at path: String) throws {
        try validateFilePath(path)
        
        let url = URL(fileURLWithPath: path)
        
        // Create directory with restricted permissions
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o755]
        )
        
        logger.info("Created secure directory: \(path)")
    }
    
    func writeSecurely(content: String, to path: String) throws {
        try validateFilePath(path)
        try validateContentSize(content.count)
        try scanContentForThreats(content)
        
        let url = URL(fileURLWithPath: path)
        
        // Write with atomic operation and restricted permissions
        try content.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
        
        // Set file permissions
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: path
        )
        
        logger.info("Secure write completed: \(url.lastPathComponent)")
    }
}

enum SecurityError: LocalizedError {
    case unsupportedScheme(String)
    case invalidHost
    case suspiciousURL(String)
    case urlTooLong
    case emptyPath
    case pathTooLong
    case filenameTooLong
    case pathTraversalAttempt
    case unsupportedFileType(String)
    case pathOutsideSandbox
    case emptyContent
    case contentTooLarge(Int)
    case suspiciousContent(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .unsupportedScheme(let scheme):
            return "Unsupported URL scheme: \(scheme)"
        case .invalidHost:
            return "Invalid or missing host in URL"
        case .suspiciousURL(let pattern):
            return "Suspicious URL pattern detected: \(pattern)"
        case .urlTooLong:
            return "URL exceeds maximum allowed length"
        case .emptyPath:
            return "File path cannot be empty"
        case .pathTooLong:
            return "File path exceeds maximum allowed length"
        case .filenameTooLong:
            return "Filename exceeds maximum allowed length"
        case .pathTraversalAttempt:
            return "Path traversal attempt detected"
        case .unsupportedFileType(let ext):
            return "Unsupported file type: .\(ext)"
        case .pathOutsideSandbox:
            return "File path outside application sandbox"
        case .emptyContent:
            return "Content cannot be empty"
        case .contentTooLarge(let size):
            return "Content too large: \(size) bytes"
        case .suspiciousContent(let pattern):
            return "Suspicious content pattern: \(pattern)"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
import Foundation

class SystemValidator {
    static let shared = SystemValidator()
    
    private let logger = DocumentLogger.shared
    
    private init() {}
    
    func performSystemValidation() async -> ValidationResult {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        
        // Validate file system structure
        let (fsIssues, fsWarnings) = await validateFileSystemStructure()
        issues += fsIssues
        warnings += fsWarnings
        
        // Validate configurations
        let (configIssues, configWarnings) = await validateConfigurations()
        issues += configIssues
        warnings += configWarnings
        
        // Validate document library integrity
        let (libIssues, libWarnings) = await validateLibraryIntegrity()
        issues += libIssues
        warnings += libWarnings
        
        // Validate security settings
        let (securityIssues, securityWarnings) = await validateSecuritySettings()
        issues += securityIssues
        warnings += securityWarnings
        
        // Validate memory and performance
        let (perfIssues, perfWarnings) = await validateSystemPerformance()
        issues += perfIssues
        warnings += perfWarnings
        
        let severity: ValidationSeverity
        if !issues.isEmpty {
            severity = .error
        } else if !warnings.isEmpty {
            severity = .warning
        } else {
            severity = .passed
        }
        
        return ValidationResult(
            severity: severity,
            issues: issues,
            warnings: warnings,
            timestamp: Date()
        )
    }
    
    private func validateFileSystemStructure() async -> ([ValidationIssue], [ValidationIssue]) {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        
        let requiredPaths = [
            "~/DocShop",
            "~/DocShop/Docs",
            "~/DocShop/Docs/Imported",
            "~/DocShop/Resources",
            "~/DocShop/Config",
            "~/DocShop/Logs",
            "~/DocShop/Backups"
        ]
        
        for path in requiredPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            
            if !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    warnings.append(ValidationIssue(
                        type: .fileSystem,
                        message: "Created missing directory: \(path)",
                        details: "Directory was missing and has been created automatically."
                    ))
                } catch {
                    issues.append(ValidationIssue(
                        type: .fileSystem,
                        message: "Failed to create directory: \(path)",
                        details: error.localizedDescription
                    ))
                }
            }
        }
        
        // Check permissions
        let storage = DocumentStorage.shared
        let testContent = "Test file for validation"
        let testFilename = "validation_test.txt"
        
        do {
            let testURL = try storage.saveDocument(content: testContent, filename: testFilename)
            try storage.deleteDocument(at: testURL)
            
            logger.debug("File system write/delete test passed")
        } catch {
            issues.append(ValidationIssue(
                type: .fileSystem,
                message: "File system write/delete test failed",
                details: error.localizedDescription
            ))
        }
        
        return (issues, warnings)
    }
    
    private func validateConfigurations() async -> ([ValidationIssue], [ValidationIssue]) {
        let issues: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        
        let config = DocumentProcessorConfig.shared
        
        // Validate network timeout
        if config.networkTimeout < 5.0 {
            warnings.append(ValidationIssue(
                type: .configuration,
                message: "Network timeout is very low",
                details: "Timeout of \(config.networkTimeout)s may cause frequent failures"
            ))
        } else if config.networkTimeout > 120.0 {
            warnings.append(ValidationIssue(
                type: .configuration,
                message: "Network timeout is very high",
                details: "Timeout of \(config.networkTimeout)s may cause long waits"
            ))
        }
        
        // Validate document size limits
        if config.maxDocumentSize > 100 * 1024 * 1024 { // 100MB
            warnings.append(ValidationIssue(
                type: .configuration,
                message: "Maximum document size is very large",
                details: "Size limit of \(config.maxDocumentSize) bytes may cause memory issues"
            ))
        }
        
        // Validate retry settings
        if config.maxRetryAttempts == 0 {
            warnings.append(ValidationIssue(
                type: .configuration,
                message: "No retry attempts configured",
                details: "Network requests will fail immediately on error"
            ))
        } else if config.maxRetryAttempts > 10 {
            warnings.append(ValidationIssue(
                type: .configuration,
                message: "Too many retry attempts configured",
                details: "May cause excessive delays on network failures"
            ))
        }
        
        return (issues, warnings)
    }
    
    private func validateLibraryIntegrity() async -> ([ValidationIssue], [ValidationIssue]) {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        
        let library = DocLibraryIndex.shared
        let storage = DocumentStorage.shared
        
        var corruptedDocuments: [DocumentMetaData] = []
        var missingFiles: [DocumentMetaData] = []
        
        for document in library.documents {
            let fileURL = URL(fileURLWithPath: document.filePath)
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                missingFiles.append(document)
                continue
            }
            
            // Check if file can be read
            do {
                _ = try storage.loadDocument(at: fileURL)
            } catch {
                corruptedDocuments.append(document)
            }
        }
        
        if !missingFiles.isEmpty {
            issues.append(ValidationIssue(
                type: .library,
                message: "\(missingFiles.count) documents have missing files",
                details: "Files may have been moved or deleted outside the application"
            ))
        }
        
        if !corruptedDocuments.isEmpty {
            issues.append(ValidationIssue(
                type: .library,
                message: "\(corruptedDocuments.count) documents are corrupted",
                details: "Files exist but cannot be read properly"
            ))
        }
        
        // Check for duplicate entries
        let sourceURLs = library.documents.map { $0.sourceURL }
        let uniqueURLs = Set(sourceURLs)
        
        if sourceURLs.count != uniqueURLs.count {
            let duplicateCount = sourceURLs.count - uniqueURLs.count
            warnings.append(ValidationIssue(
                type: .library,
                message: "\(duplicateCount) duplicate source URLs found",
                details: "Multiple documents may reference the same source"
            ))
        }
        
        return (issues, warnings)
    }
    
    private func validateSecuritySettings() async -> ([ValidationIssue], [ValidationIssue]) {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        
        let config = DocumentProcessorConfig.shared
        let security = SecurityManager.shared
        
        // Check for weak security settings
        if config.blockedDomains.isEmpty {
            warnings.append(ValidationIssue(
                type: .security,
                message: "No blocked domains configured",
                details: "Consider blocking known malicious or inappropriate domains"
            ))
        }
        
        // Test security validation
        let testURLs = [
            "javascript:alert('test')",
            "file:///etc/passwd",
            "http://localhost/test",
            "data:text/html,<script>alert('test')</script>"
        ]
        
        for testURL in testURLs {
            if let url = URL(string: testURL) {
                do {
                    try security.validateURL(url)
                    issues.append(ValidationIssue(
                        type: .security,
                        message: "Security validation failed for dangerous URL",
                        details: "URL \(testURL) should have been blocked"
                    ))
                } catch {
                    // This is expected - the URL should be blocked
                    logger.debug("Security test passed for blocked URL: \(testURL)")
                }
            }
        }
        
        // Test content scanning
        let dangerousContent = "<script>alert('test')</script>"
        do {
            try security.scanContentForThreats(dangerousContent)
            issues.append(ValidationIssue(
                type: .security,
                message: "Content threat scanning failed",
                details: "Dangerous script content was not detected"
            ))
        } catch {
            // This is expected - the content should be blocked
            logger.debug("Security test passed for blocked content")
        }
        
        return (issues, warnings)
    }
    
    private func validateSystemPerformance() async -> ([ValidationIssue], [ValidationIssue]) {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        
        let memory = MemoryManager.shared
        let memoryUsage = memory.getMemoryUsage()
        
        // Check memory usage
        if memory.memoryPressure == .critical {
            issues.append(ValidationIssue(
                type: .performance,
                message: "Critical memory pressure detected",
                details: "System is under severe memory pressure"
            ))
        } else if memory.memoryPressure == .warning {
            warnings.append(ValidationIssue(
                type: .performance,
                message: "Memory pressure warning",
                details: "System memory usage is elevated"
            ))
        }
        
        // Check cache size
        if memoryUsage.cacheMB > 100 { // 100MB cache warning
            warnings.append(ValidationIssue(
                type: .performance,
                message: "Large cache size detected",
                details: "Cache is using \(String(format: "%.1f", memoryUsage.cacheMB))MB of memory"
            ))
        }
        
        // Check for low memory mode
        if memory.isLowMemoryMode {
            warnings.append(ValidationIssue(
                type: .performance,
                message: "Low memory mode is active",
                details: "System is operating in reduced performance mode"
            ))
        }
        
        return (issues, warnings)
    }
    
    func performQuickHealthCheck() -> SystemHealth {
        let processor = DocumentProcessor.shared
        let library = DocLibraryIndex.shared
        let memory = MemoryManager.shared
        
        var healthLevel = SystemHealth.HealthLevel.healthy
        var issues: [String] = []
        
        // Check for critical issues
        if processor.lastError != nil {
            healthLevel = .critical
            issues.append("Processing error detected")
        }
        
        if library.lastError != nil {
            healthLevel = .critical
            issues.append("Library error detected")
        }
        
        if memory.memoryPressure == .critical {
            healthLevel = .critical
            issues.append("Critical memory pressure")
        }
        
        // Check for warnings
        if healthLevel == .healthy {
            if processor.isProcessing && processor.processingQueue.count > 10 {
                healthLevel = .warning
                issues.append("Large processing queue")
            }
            
            if memory.memoryPressure == .warning {
                healthLevel = .warning
                issues.append("Memory pressure warning")
            }
            
            if memory.isLowMemoryMode {
                healthLevel = .warning
                issues.append("Low memory mode active")
            }
        }
        
        return SystemHealth(level: healthLevel, issues: issues)
    }
}

struct ValidationResult {
    let severity: ValidationSeverity
    let issues: [ValidationIssue]
    let warnings: [ValidationIssue]
    let timestamp: Date
    
    var isHealthy: Bool {
        return severity == .passed
    }
    
    var totalIssues: Int {
        return issues.count + warnings.count
    }
}

struct ValidationIssue {
    let type: ValidationType
    let message: String
    let details: String
}

enum ValidationSeverity {
    case passed
    case warning
    case error
    
    var displayName: String {
        switch self {
        case .passed:
            return "Passed"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }
    
    var color: String {
        switch self {
        case .passed:
            return "green"
        case .warning:
            return "orange"
        case .error:
            return "red"
        }
    }
}

enum ValidationType {
    case fileSystem
    case configuration
    case library
    case security
    case performance
    
    var displayName: String {
        switch self {
        case .fileSystem:
            return "File System"
        case .configuration:
            return "Configuration"
        case .library:
            return "Library"
        case .security:
            return "Security"
        case .performance:
            return "Performance"
        }
    }
}

struct SystemHealth {
    let level: HealthLevel
    let issues: [String]
    
    enum HealthLevel {
        case healthy
        case warning
        case critical
        
        var displayName: String {
            switch self {
            case .healthy:
                return "Healthy"
            case .warning:
                return "Warning"
            case .critical:
                return "Critical"
            }
        }
        
        var color: String {
            switch self {
            case .healthy:
                return "green"
            case .warning:
                return "orange"
            case .critical:
                return "red"
            }
        }
    }
}

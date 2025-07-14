import Foundation
import Combine

class DocumentProcessorConfig: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()

    static let shared = DocumentProcessorConfig()
    
    @Published var networkTimeout: TimeInterval = 30.0
    @Published var maxDocumentSize: Int = 50 * 1024 * 1024 // 50MB
    @Published var allowDuplicates: Bool = false
    @Published var smartDuplicateHandling: Bool = true
    @Published var checkForUpdates: Bool = true
    @Published var updateCheckInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    @Published var maxRetryAttempts: Int = 3
    @Published var retryDelay: TimeInterval = 2.0
    @Published var blockedDomains: Set<String> = []
    @Published var enableLogging: Bool = true
    @Published var maxLogFileSize: Int = 10 * 1024 * 1024 // 10MB
    
    // JavaScript rendering settings
    @Published var enableJavaScriptRendering: Bool = true
    @Published var jsRenderingTimeout: TimeInterval = 60.0
    @Published var autoDetectJSRequirement: Bool = true
    
    private let configFileURL: URL
    
    private init() {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("DocShop/Config")
        
        try? FileManager.default.createDirectory(at: configPath, withIntermediateDirectories: true)
        
        self.configFileURL = configPath.appendingPathComponent("processor_config.json")
        
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            saveConfiguration()
            return
        }
        
        do {
            let data = try Data(contentsOf: configFileURL)
            let config = try JSONDecoder().decode(ConfigData.self, from: data)
            
            networkTimeout = config.networkTimeout
            maxDocumentSize = config.maxDocumentSize
            allowDuplicates = config.allowDuplicates
            smartDuplicateHandling = config.smartDuplicateHandling
            checkForUpdates = config.checkForUpdates
            updateCheckInterval = config.updateCheckInterval
            maxRetryAttempts = config.maxRetryAttempts
            retryDelay = config.retryDelay
            blockedDomains = Set(config.blockedDomains)
            enableLogging = config.enableLogging
            maxLogFileSize = config.maxLogFileSize
            enableJavaScriptRendering = config.enableJavaScriptRendering
            jsRenderingTimeout = config.jsRenderingTimeout
            autoDetectJSRequirement = config.autoDetectJSRequirement
        } catch {
            print("Failed to load configuration: \(error)")
            saveConfiguration()
        }
    }
    
    func saveConfiguration() {
        let config = ConfigData(
            networkTimeout: networkTimeout,
            maxDocumentSize: maxDocumentSize,
            allowDuplicates: allowDuplicates,
            smartDuplicateHandling: smartDuplicateHandling,
            checkForUpdates: checkForUpdates,
            updateCheckInterval: updateCheckInterval,
            maxRetryAttempts: maxRetryAttempts,
            retryDelay: retryDelay,
            blockedDomains: Array(blockedDomains),
            enableLogging: enableLogging,
            maxLogFileSize: maxLogFileSize,
            enableJavaScriptRendering: enableJavaScriptRendering,
            jsRenderingTimeout: jsRenderingTimeout,
            autoDetectJSRequirement: autoDetectJSRequirement
        )
        
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFileURL)
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    func resetToDefaults() {
        networkTimeout = 30.0
        maxDocumentSize = 50 * 1024 * 1024
        allowDuplicates = false
        smartDuplicateHandling = true
        checkForUpdates = true
        updateCheckInterval = 24 * 60 * 60
        maxRetryAttempts = 3
        retryDelay = 2.0
        blockedDomains = []
        enableLogging = true
        maxLogFileSize = 10 * 1024 * 1024
        enableJavaScriptRendering = true
        jsRenderingTimeout = 30.0
        autoDetectJSRequirement = true
        
        saveConfiguration()
    }
    
    func addBlockedDomain(_ domain: String) {
        blockedDomains.insert(domain.lowercased())
        saveConfiguration()
    }
    
    func removeBlockedDomain(_ domain: String) {
        blockedDomains.remove(domain.lowercased())
        saveConfiguration()
    }
}

private struct ConfigData: Codable {
    let networkTimeout: TimeInterval
    let maxDocumentSize: Int
    let allowDuplicates: Bool
    let smartDuplicateHandling: Bool
    let checkForUpdates: Bool
    let updateCheckInterval: TimeInterval
    let maxRetryAttempts: Int
    let retryDelay: TimeInterval
    let blockedDomains: [String]
    let enableLogging: Bool
    let maxLogFileSize: Int
    let enableJavaScriptRendering: Bool
    let jsRenderingTimeout: TimeInterval
    let autoDetectJSRequirement: Bool
}

import Foundation
import os.log
import Combine

class MemoryManager: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()

    static let shared = MemoryManager()
    
    @Published var memoryPressure: MemoryPressureLevel = .normal
    @Published var cacheSize: Int = 0
    @Published var isLowMemoryMode = false
    
    private let logger = DocumentLogger.shared
    private let dispatchSource: DispatchSourceMemoryPressure
    private let cacheQueue = DispatchQueue(label: "memory.cache", qos: .utility)
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private let lowMemoryThreshold = 100 * 1024 * 1024 // 100MB
    
    // Document content cache
    private var contentCache: [String: CachedContent] = [:]
    private var accessTimes: [String: Date] = [:]
    
    private init() {
        dispatchSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main
        )
        
        setupMemoryPressureMonitoring()
        startPeriodicCleanup()
    }
    
    deinit {
        dispatchSource.cancel()
    }
    
    private func setupMemoryPressureMonitoring() {
        dispatchSource.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        
        dispatchSource.resume()
    }
    
    private func handleMemoryPressure() {
        var memInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &memInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryUsage = Int(memInfo.resident_size)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if memoryUsage > self.lowMemoryThreshold * 2 {
                    self.memoryPressure = .critical
                    self.enableLowMemoryMode()
                } else if memoryUsage > self.lowMemoryThreshold {
                    self.memoryPressure = .warning
                    self.performMemoryCleanup()
                } else {
                    self.memoryPressure = .normal
                    self.disableLowMemoryMode()
                }
                
                self.logger.debug("Memory usage: \(memoryUsage / 1024 / 1024)MB, Pressure: \(self.memoryPressure)")
            }
        }
    }
    
    private func enableLowMemoryMode() {
        guard !isLowMemoryMode else { return }
        
        isLowMemoryMode = true
        clearAllCaches()
        
        logger.warning("Low memory mode enabled")
        
        // Notify other components to reduce memory usage
        NotificationCenter.default.post(
            name: .lowMemoryModeEnabled,
            object: nil
        )
    }
    
    private func disableLowMemoryMode() {
        guard isLowMemoryMode else { return }
        
        isLowMemoryMode = false
        logger.info("Low memory mode disabled")
        
        NotificationCenter.default.post(
            name: .lowMemoryModeDisabled,
            object: nil
        )
    }
    
    private func performMemoryCleanup() {
        cacheQueue.async { [weak self] in
            self?.cleanupOldCacheEntries()
            self?.limitCacheSize()
        }
    }
    
    private func clearAllCaches() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.contentCache.removeAll()
            self.accessTimes.removeAll()
            
            DispatchQueue.main.async {
                self.cacheSize = 0
                self.logger.info("All caches cleared due to memory pressure")
            }
        }
    }
    
    func cacheContent(_ content: String, forKey key: String) {
        guard !isLowMemoryMode else { return }
        
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let cachedContent = CachedContent(
                content: content,
                size: content.utf8.count,
                timestamp: Date()
            )
            
            self.contentCache[key] = cachedContent
            self.accessTimes[key] = Date()
            
            DispatchQueue.main.async {
                self.updateCacheSize()
            }
            
            // Check if we need to clean up
            if self.getCurrentCacheSize() > self.maxCacheSize {
                self.limitCacheSize()
            }
        }
    }
    
    func getCachedContent(forKey key: String) -> String? {
        var result: String?
        
        cacheQueue.sync {
            if let cachedContent = contentCache[key] {
                accessTimes[key] = Date()
                result = cachedContent.content
            }
        }
        
        return result
    }
    
    func removeCachedContent(forKey key: String) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.contentCache.removeValue(forKey: key)
            self.accessTimes.removeValue(forKey: key)
            
            DispatchQueue.main.async {
                self.updateCacheSize()
            }
        }
    }
    
    private func cleanupOldCacheEntries() {
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes
        
        let keysToRemove = accessTimes.compactMap { key, time in
            time < cutoffTime ? key : nil
        }
        
        for key in keysToRemove {
            contentCache.removeValue(forKey: key)
            accessTimes.removeValue(forKey: key)
        }
        
        if !keysToRemove.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.updateCacheSize()
                self?.logger.debug("Cleaned up \(keysToRemove.count) old cache entries")
            }
        }
    }
    
    private func limitCacheSize() {
        guard getCurrentCacheSize() > maxCacheSize else { return }
        
        // Sort by access time (oldest first)
        let sortedEntries = accessTimes.sorted { $0.value < $1.value }
        
        var currentSize = getCurrentCacheSize()
        let targetSize = maxCacheSize / 2 // Reduce to 50% of max
        
        for (key, _) in sortedEntries {
            guard currentSize > targetSize else { break }
            
            if let cachedContent = contentCache.removeValue(forKey: key) {
                accessTimes.removeValue(forKey: key)
                currentSize -= cachedContent.size
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateCacheSize()
            self?.logger.debug("Limited cache size to \(currentSize) bytes")
        }
    }
    
    private func getCurrentCacheSize() -> Int {
        return contentCache.values.reduce(0) { $0 + $1.size }
    }
    
    private func updateCacheSize() {
        cacheSize = getCurrentCacheSize()
    }
    
    private func startPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performMemoryCleanup()
        }
    }
    
    // MARK: - Memory Usage Utilities
    
    func getMemoryUsage() -> MemoryUsageInfo {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return MemoryUsageInfo(
                resident: Int(info.resident_size),
                virtual: Int(info.virtual_size),
                cacheSize: cacheSize
            )
        } else {
            return MemoryUsageInfo(resident: 0, virtual: 0, cacheSize: cacheSize)
        }
    }
    
    func shouldStreamContent(size: Int) -> Bool {
        return isLowMemoryMode || size > 1024 * 1024 // 1MB threshold
    }
    
    func shouldUsePagination() -> Bool {
        return isLowMemoryMode || memoryPressure != .normal
    }
}

struct CachedContent {
    let content: String
    let size: Int
    let timestamp: Date
}

enum MemoryPressureLevel: String, CaseIterable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .normal:
            return "green"
        case .warning:
            return "orange"
        case .critical:
            return "red"
        }
    }
}

struct MemoryUsageInfo {
    let resident: Int
    let virtual: Int
    let cacheSize: Int
    
    var residentMB: Double {
        return Double(resident) / 1024 / 1024
    }
    
    var virtualMB: Double {
        return Double(virtual) / 1024 / 1024
    }
    
    var cacheMB: Double {
        return Double(cacheSize) / 1024 / 1024
    }
}

extension Notification.Name {
    static let lowMemoryModeEnabled = Notification.Name("lowMemoryModeEnabled")
    static let lowMemoryModeDisabled = Notification.Name("lowMemoryModeDisabled")
}

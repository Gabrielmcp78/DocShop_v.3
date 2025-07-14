import SwiftUI

struct SystemStatusView: View {
    @ObservedObject private var memory = MemoryManager.shared
    @ObservedObject private var processor = DocumentProcessor.shared
    @ObservedObject private var library = DocLibraryIndex.shared
    @ObservedObject private var config = DocumentProcessorConfig.shared
    
    @State private var memoryUsage = MemoryUsageInfo(resident: 0, virtual: 0, cacheSize: 0)
    @State private var refreshTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                memorySection
                
                processingSection
                
                librarySection
                
                systemInfoSection
            }
            .padding()
        }
        .glassy()
        .navigationTitle("System Status")
        .onAppear {
            startRefreshTimer()
            updateMemoryUsage()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DocShop System Status")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                systemHealthIndicator
            }
            
            Text("Real-time system performance and health monitoring")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var systemHealthIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(systemHealthColor)
                .frame(width: 12, height: 12)
            
            Text(systemHealthText)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var systemHealthColor: Color {
        if memory.memoryPressure == .critical || processor.lastError != nil {
            return .red
        } else if memory.memoryPressure == .warning || processor.isProcessing {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var systemHealthText: String {
        if memory.memoryPressure == .critical || processor.lastError != nil {
            return "Critical"
        } else if memory.memoryPressure == .warning || processor.isProcessing {
            return "Warning"
        } else {
            return "Healthy"
        }
    }
    
    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Memory pressure indicator
                HStack {
                    Text("Memory Pressure")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(memory.memoryPressure.color))
                            .frame(width: 8, height: 8)
                        Text(memory.memoryPressure.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                // Resident memory
                MemoryUsageRow(
                    title: "Physical Memory",
                    value: String(format: "%.1f MB", memoryUsage.residentMB),
                    percentage: min(memoryUsage.residentMB / 512.0, 1.0) // Assume 512MB as reference
                )
                
                // Cache memory
                MemoryUsageRow(
                    title: "Cache Memory",
                    value: String(format: "%.1f MB", memoryUsage.cacheMB),
                    percentage: Double(memory.cacheSize) / Double(50 * 1024 * 1024) // 50MB max cache
                )
                
                if memory.isLowMemoryMode {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Low Memory Mode Active")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var processingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Processing")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatusRow(
                    title: "Status",
                    value: processor.isProcessing ? "Processing" : "Idle",
                    color: processor.isProcessing ? .orange : .gray
                )
                
                if processor.isProcessing {
                    StatusRow(
                        title: "Current Task",
                        value: processor.currentStatus,
                        color: .blue
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(Int(processor.processingProgress * 100))%")
                                .font(.caption)
                        }
                        
                        ProgressView(value: processor.processingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                StatusRow(
                    title: "Queue Length",
                    value: "\(processor.processingQueue.count)",
                    color: processor.processingQueue.isEmpty ? .gray : .orange
                )
                
                if let lastError = processor.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Error")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text(lastError)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Library")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatusRow(
                    title: "Total Documents",
                    value: "\(library.documents.count)",
                    color: .blue
                )
                
                StatusRow(
                    title: "Total Size",
                    value: totalLibrarySize,
                    color: .blue
                )
                
                StatusRow(
                    title: "Library Status",
                    value: library.isLoading ? "Loading" : "Ready",
                    color: library.isLoading ? .orange : .gray
                )
                
                if let lastError = library.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library Error")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text(lastError)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatusRow(
                    title: "Network Timeout",
                    value: "\(Int(config.networkTimeout))s",
                    color: .gray
                )
                
                StatusRow(
                    title: "Max Document Size",
                    value: ByteCountFormatter.string(fromByteCount: Int64(config.maxDocumentSize), countStyle: .file),
                    color: .gray
                )
                
                StatusRow(
                    title: "Retry Attempts",
                    value: "\(config.maxRetryAttempts)",
                    color: .gray
                )
                
                StatusRow(
                    title: "Blocked Domains",
                    value: "\(config.blockedDomains.count)",
                    color: config.blockedDomains.isEmpty ? .gray : .orange
                )
                
                StatusRow(
                    title: "Logging",
                    value: config.enableLogging ? "Enabled" : "Disabled",
                    color: config.enableLogging ? .gray : .gray
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    private var totalLibrarySize: String {
        let totalBytes = library.documents.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            updateMemoryUsage()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func updateMemoryUsage() {
        memoryUsage = memory.getMemoryUsage()
    }
}

struct MemoryUsageRow: View {
    let title: String
    let value: String
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForPercentage))
        }
    }
    
    private var colorForPercentage: Color {
        if percentage > 0.8 {
            return .red
        } else if percentage > 0.6 {
            return .orange
        } else {
            return .gray
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    SystemStatusView()
}

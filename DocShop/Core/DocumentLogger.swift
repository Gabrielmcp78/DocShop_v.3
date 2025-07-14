import Foundation
import os.log

class DocumentLogger {
    static let shared = DocumentLogger()
    
    private let logger = Logger(subsystem: "com.docshop.app", category: "DocumentProcessor")
    private let config = DocumentProcessorConfig.shared
    private let logFileURL: URL
    private let logQueue = DispatchQueue(label: "document.logger", qos: .utility)
    
    private init() {
        let logsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("DocShop/Logs")
        
        try? FileManager.default.createDirectory(at: logsPath, withIntermediateDirectories: true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        self.logFileURL = logsPath.appendingPathComponent("docshop_\(dateString).log")
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        guard config.enableLogging else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        switch level {
        case .info:
            logger.info("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .debug:
            logger.debug("\(logMessage)")
        }
        
        writeToFile(logMessage)
    }
    
    private func writeToFile(_ message: String) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logEntry = "[\(timestamp)] \(message)\n"
            
            if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                do {
                    let fileHandle = try FileHandle(forWritingTo: self.logFileURL)
                    defer { fileHandle.closeFile() }
                    
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                    
                    self.rotateLogIfNeeded()
                } catch {
                    print("Failed to write to log file: \(error)")
                }
            } else {
                do {
                    try logEntry.write(to: self.logFileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to create log file: \(error)")
                }
            }
        }
    }
    
    private func rotateLogIfNeeded() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            if fileSize > config.maxLogFileSize {
                let rotatedURL = logFileURL.appendingPathExtension("old")
                
                if FileManager.default.fileExists(atPath: rotatedURL.path) {
                    try FileManager.default.removeItem(at: rotatedURL)
                }
                
                try FileManager.default.moveItem(at: logFileURL, to: rotatedURL)
            }
        } catch {
            print("Failed to rotate log file: \(error)")
        }
    }
    
    func clearLogs() {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    try FileManager.default.removeItem(at: self.logFileURL)
                }
                
                let rotatedURL = self.logFileURL.appendingPathExtension("old")
                if FileManager.default.fileExists(atPath: rotatedURL.path) {
                    try FileManager.default.removeItem(at: rotatedURL)
                }
            } catch {
                print("Failed to clear logs: \(error)")
            }
        }
    }
    
    func getLogContent() -> String {
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            return "Failed to read log file: \(error)"
        }
    }
}

private enum LogLevel: String {
    case info = "INFO"
    case error = "ERROR"
    case warning = "WARNING"
    case debug = "DEBUG"
}
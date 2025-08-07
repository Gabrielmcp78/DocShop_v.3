import Foundation
import SwiftUI

// This helper manages retrieving content sent from the Share Extension.
class SharedImportManager: ObservableObject {
    static let appGroupID = "group.com.yourcompany.docshop" // <-- UPDATE if needed

    // Holds what was received from the share extension until processed
    @Published var pendingURL: URL?
    @Published var pendingText: String?
    @Published var pendingFileURL: URL?
    
    // Call this at launch or when app enters foreground
    func checkForSharedContent() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        if let urlString = defaults?.string(forKey: "SharedURL"), let url = URL(string: urlString) {
            pendingURL = url
        }
        if let text = defaults?.string(forKey: "SharedText") {
            pendingText = text
        }
        if let filePath = defaults?.string(forKey: "SharedFile"), !filePath.isEmpty {
            let fileURL = URL(fileURLWithPath: filePath)
            if FileManager.default.fileExists(atPath: filePath) {
                pendingFileURL = fileURL
            }
        }
    }
    
    // Call after successful import to clear out the shared data
    func clearSharedContent() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        defaults?.removeObject(forKey: "SharedURL")
        defaults?.removeObject(forKey: "SharedText")
        defaults?.removeObject(forKey: "SharedFile")
        defaults?.synchronize()
        pendingURL = nil
        pendingText = nil
        pendingFileURL = nil
    }
}

// SharedImportManager.swift
// Purpose: Provides a mechanism for the main app and Share Extension to share imported URLs, files, and text.

import Foundation
import UniformTypeIdentifiers

/// Replace this with your actual App Group identifier
private let appGroupIdentifier = "group.com.yourcompany.yourapp"

public class SharedImportManager {
    public static let shared = SharedImportManager()
    
    private let userDefaults: UserDefaults?
    
    // UserDefaults keys
    private enum Keys: String {
        case pendingURL = "SharedImportManager.pendingURL"
        case pendingFileURL = "SharedImportManager.pendingFileURL"
        case pendingText = "SharedImportManager.pendingText"
    }
    
    public var pendingURL: URL? {
        userDefaults?.url(forKey: Keys.pendingURL.rawValue)
    }
    
    public var pendingFileURL: URL? {
        userDefaults?.url(forKey: Keys.pendingFileURL.rawValue)
    }
    
    public var pendingText: String? {
        userDefaults?.string(forKey: Keys.pendingText.rawValue)
    }
    
    public init() {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Called by the Share Extension to save a shared URL
    public func saveSharedURL(_ url: URL) {
        userDefaults?.set(url, forKey: Keys.pendingURL.rawValue)
    }
    
    /// Called by the Share Extension to save a shared file URL
    public func saveSharedFileURL(_ fileURL: URL) {
        userDefaults?.set(fileURL, forKey: Keys.pendingFileURL.rawValue)
    }
    
    /// Called by the Share Extension to save shared plain text
    public func saveSharedText(_ text: String) {
        userDefaults?.set(text, forKey: Keys.pendingText.rawValue)
    }
    
    /// Should be called after main app imports the shared content
    public func clearSharedContent() {
        userDefaults?.removeObject(forKey: Keys.pendingURL.rawValue)
        userDefaults?.removeObject(forKey: Keys.pendingFileURL.rawValue)
        userDefaults?.removeObject(forKey: Keys.pendingText.rawValue)
    }
}

// Usage:
// In Share Extension code, call SharedImportManager().saveShared... to store shared data.
// In main app, call SharedImportManager().pendingURL/fileURL/text to retrieve, and clearSharedContent() after importing.


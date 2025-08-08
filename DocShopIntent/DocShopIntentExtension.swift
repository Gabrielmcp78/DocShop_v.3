//
//  DocShopIntentExtension.swift
//  DocShopIntent
//
//  Created by Gabriel McPherson on 8/6/25.
//

import AppIntents
import ExtensionFoundation
import UniformTypeIdentifiers
// Make ImportDocumentationIntent available

@main
struct DocShopIntentExtension: AppIntentsExtension {
    static var appIntents: [any AppIntent.Type] {
        [ImportDocumentationIntent.self, DocShopIntent.self]
    }
    // Add more AppIntents here as you create them
}


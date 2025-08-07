//
//  DocShopIntent.swift
//  DocShopIntent
//
//  Created by Gabriel McPherson on 8/6/25.
//

import AppIntents

struct DocShopIntent: AppIntent {
    static var title: LocalizedStringResource { "DocShopIntent" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

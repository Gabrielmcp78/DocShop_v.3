//
//  DocumentImporter.swift
//  DocShop
//
//  Created by Gabriel McPherson on 8/6/25.
//
import Foundation

public struct SimpleDocumentMetaData: Codable {
    public let title: String
    public let summary: String
    public let sourceURL: String
}

public class DocumentImporter {
    
    public init() {}

    public func importMinimalDocument(from urlString: String) async throws -> SimpleDocumentMetaData {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await fetchContent(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }

        let title = extractTitle(from: html) ?? "Untitled Document"
        let summary = extractSummary(from: html)

        return SimpleDocumentMetaData(
            title: title,
            summary: summary,
            sourceURL: url.absoluteString
        )
    }

    private func fetchContent(from url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        return try await URLSession.shared.data(for: request)
    }

    private func extractTitle(from html: String) -> String? {
        guard let range = html.range(of: "<title>(.*?)</title>", options: .regularExpression) else { return nil }
        let rawTitle = html[range]
            .replacingOccurrences(of: "<title>", with: "")
            .replacingOccurrences(of: "</title>", with: "")
        return rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractSummary(from html: String) -> String {
        let plainText = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let summary = plainText.prefix(300).trimmingCharacters(in: .whitespacesAndNewlines)
        return summary
    }
}

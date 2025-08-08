import AppIntents
import UniformTypeIdentifiers
import Foundation
import Combine
import FoundationModels

struct ImportDocumentationIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Documentation to DocShop"
    static var description = IntentDescription("Import and ingest a shared documentation file into the DocShop library.")
    static var openAppWhenRun: Bool = false
    static var suggestedInvocationPhrase: String? { "Import documentation file" }
    static var systemImageName: String? { "doc.text" }
    static var supportedContentTypes: [UTType] = [
        .pdf, .plainText, .text, .content, .rtf, .html, UTType(exportedAs: "net.daringfireball.markdown")
    ]

    @Parameter(title: "File to Import", supportedContentTypes: [
        .item, .text, .content, .pdf, .plainText, .rtf, .html, UTType(exportedAs: "net.daringfireball.markdown")
    ])
    var file: IntentFile

    func perform() async throws -> some IntentResult {
        guard let tempURL = file.fileURL else {
            return .result(dialog: "The provided file could not be accessed.")
        }

        let fileContent = try String(contentsOf: tempURL, encoding: .utf8)
        let summary = fileContent.prefix(300).trimmingCharacters(in: .whitespacesAndNewlines)

        return .result(dialog: "Document imported! Preview: \(summary)")
    }
}

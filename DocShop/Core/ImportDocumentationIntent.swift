import AppIntents
import Foundation

struct ImportDocumentationIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Documentation to DocShop"
    static var description = IntentDescription("Import and ingest a shared documentation file into the DocShop library.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "File to Import", supportedTypeIdentifiers: ["public.item", "public.text", "public.content", "com.adobe.pdf"])
    var file: IntentFile

    func perform() async throws -> some IntentResult {
        // Save file to a temp location
        let tempURL = file.fileURL
        // Call your document ingestion logic
        _ = try await DocumentProcessor.shared.processLocalFile(at: tempURL)
        return .result(dialog: "Document imported to DocShop! You can now view it in the library.")
    }
}

// AppIntents need to be registered. If not already present, add this to your App struct:
// .appIntentsProvider { [ImportDocumentationIntent()] }

// If your App struct is in MyApp.swift, add this in the body:
// .appIntentsProvider { [ImportDocumentationIntent()] }

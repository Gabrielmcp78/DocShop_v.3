import Hummingbird
import HummingbirdCore // For BasicRequestContext

struct DocumentAPI {
    static func addRoutes(to group: RouterGroup<CustomRequestContext>) {
        group.post("/documents/search", use: search)
    }

    struct SearchRequest: Decodable {
        let query: String
    }

    static func search(request: Request, context: CustomRequestContext) async throws -> [DocumentMetaData] {
        let searchRequest = try await request.decode(as: SearchRequest.self, context: context)
        DocLibraryIndex.shared.searchDocuments(query: searchRequest.query)
        return DocLibraryIndex.shared.searchResults
    }
}

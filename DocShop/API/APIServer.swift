import Hummingbird
import Foundation
import Logging // Required for LogRequestsMiddleware
import HTTPTypes // Required for HTTPField.Name and HTTPMethod
import HummingbirdCore // For BasicRequestContext

@main
struct DocShopAPIServer {
    static func main() async throws {
        let router = Router(context: CustomRequestContext.self) // Use CustomRequestContext
        
        // Add middleware
        router.middlewares.add(LogRequestsMiddleware(.info))
        router.middlewares.add(CORSMiddleware(
            allowOrigin: .all,
            allowHeaders: [.contentType, .authorization],
            allowMethods: [.get, .post, .options]
        ))

        // Add routes
        addRoutes(to: router)

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 8080))
        )

        try await app.runService()
    }

    static func addRoutes(to router: Router<CustomRequestContext>) { // Use CustomRequestContext
        router.get("/") { request, context in
            return "DocShop API v1"
        }

        let api = router.group("v1")
        
        // Add handlers for each API group
        DocumentAPI.addRoutes(to: api)
        FilesystemAPI.addRoutes(to: api)
        ShellAPI.addRoutes(to: api)
    }
}


import Hummingbird
import Foundation
import NIOCore // Added for ByteBufferAllocator
import HummingbirdHTTP // Added for Abort

struct FilesystemAPI {
    static func addRoutes(to group: RouterGroup<CustomRequestContext>) {
        group.post("/files/read", use: read)
        group.post("/files/write", use: write)
    }

    struct ReadRequest: Decodable {
        let path: String
    }

    struct ReadResponse: Encodable, ResponseGenerator {
        let content: String

        public func response<Context: RequestContext>(from request: Request, context: Context) throws -> HummingbirdCore.Response {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return HummingbirdCore.Response(status: .ok, body: .init(byteBuffer: (context as! CustomRequestContext).allocator.buffer(data: data)))
        }
    }

    static func read(request: Request, context: CustomRequestContext) async throws -> ReadResponse {
        let readRequest = try await request.decode(as: ReadRequest.self, context: context)
        let content = try DocumentStorage.shared.loadDocument(at: URL(fileURLWithPath: readRequest.path))
        return ReadResponse(content: content)
    }

    struct WriteRequest: Decodable {
        let path: String
        let content: String
    }

    struct WriteResponse: Encodable, ResponseGenerator {
        let success: Bool

        public func response<Context: RequestContext>(from request: Request, context: Context) throws -> HummingbirdCore.Response {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return HummingbirdCore.Response(status: .ok, body: .init(byteBuffer: (context as! CustomRequestContext).allocator.buffer(data: data)))
        }
    }

    static func write(request: Request, context: CustomRequestContext) async throws -> WriteResponse {
        let writeRequest = try await request.decode(as: WriteRequest.self, context: context)
        let url = URL(fileURLWithPath: writeRequest.path)
        _ = try DocumentStorage.shared.saveDocument(content: writeRequest.content, filename: url.lastPathComponent)
        return WriteResponse(success: true)
    }
}


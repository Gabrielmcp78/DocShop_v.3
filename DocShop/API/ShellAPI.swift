import Hummingbird
import Foundation // Added for Process, URL, Pipe
import NIOCore // Added for ByteBufferAllocator

struct ShellAPI {
    static func addRoutes(to group: RouterGroup<CustomRequestContext>) {
        group.post("/shell/execute", use: execute)
    }

    struct ExecuteRequest: Decodable {
        let command: String
    }

    struct ExecuteResponse: Encodable, ResponseGenerator {
        let stdout: String
        let stderr: String
        let exitCode: Int32

        public func response<Context: RequestContext>(from request: Request, context: Context) throws -> HummingbirdCore.Response {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return HummingbirdCore.Response(status: .ok, body: .init(byteBuffer: request.allocator.buffer(data: data)))
        }
    }

    static func execute(request: Request, context: CustomRequestContext) async throws -> ExecuteResponse {
        let executeRequest = try await request.decode(as: ExecuteRequest.self, context: context)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", executeRequest.command]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: outputData, encoding: .utf8) ?? ""
        let stderr = String(data: errorData, encoding: .utf8) ?? ""
        
        return ExecuteResponse(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
    }
}


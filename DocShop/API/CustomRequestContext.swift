import Hummingbird
import HummingbirdCore // For BasicRequestContext
import NIOCore // Required for ByteBufferAllocator

struct CustomRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    
    init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
    }
}

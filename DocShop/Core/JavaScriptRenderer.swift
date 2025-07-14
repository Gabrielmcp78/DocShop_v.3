import Foundation
import WebKit
import Combine

@MainActor
class JavaScriptRenderer: NSObject, ObservableObject {
    static let shared = JavaScriptRenderer()
    
    @Published var isRendering = false
    @Published var renderingProgress: Double = 0.0
    @Published var currentRenderingURL: String = ""
    
    private var webView: WKWebView?
    private var renderingContinuation: CheckedContinuation<String, Error>?
    private let logger = DocumentLogger.shared
    private let config = DocumentProcessorConfig.shared
    
    private override init() {
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Enable JavaScript
        if #available(macOS 11.0, *) {
            let webpagePreferences = WKWebpagePreferences()
            webpagePreferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = webpagePreferences
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        
        // Disable images and media to speed up loading
        configuration.preferences.setValue(false, forKey: "allowsInlineMediaPlayback")
        
        // Create a minimal web view (hidden)
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768), configuration: configuration)
        webView?.navigationDelegate = self
        
        logger.info("JavaScript renderer initialized")
    }
    
    func renderPage(url: URL) async throws -> String {
        guard let webView = webView else {
            throw RenderingError.webViewNotAvailable
        }
        
        isRendering = true
        currentRenderingURL = url.absoluteString
        renderingProgress = 0.0
        
        defer {
            isRendering = false
            currentRenderingURL = ""
            renderingProgress = 0.0
        }
        
        logger.info("Starting JavaScript rendering for: \(url.absoluteString)")
        
        return try await withCheckedThrowingContinuation { continuation in
            renderingContinuation = continuation
            
            // Set a timeout
            Task {
                try await Task.sleep(nanoseconds: UInt64(config.networkTimeout * 1_000_000_000))
                if renderingContinuation != nil {
                    renderingContinuation?.resume(throwing: RenderingError.timeout)
                    renderingContinuation = nil
                }
            }
            
            // Start loading the page
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    private func extractRenderedHTML() async throws -> String {
        guard let webView = webView else {
            throw RenderingError.webViewNotAvailable
        }
        
        renderingProgress = 0.8
        
        // Wait a bit more for any async content to load
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Extract the fully rendered HTML
        let html = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String
        
        guard let renderedHTML = html, !renderedHTML.isEmpty else {
            throw RenderingError.emptyContent
        }
        
        renderingProgress = 1.0
        logger.info("Successfully extracted rendered HTML (\(renderedHTML.count) characters)")
        
        return renderedHTML
    }
    
    func isJavaScriptRequired(for url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        
        // Known sites that require JavaScript for content
        let jsRequiredSites = [
            "developer.apple.com",
            "docs.microsoft.com",
            "angular.io",
            "reactjs.org",
            "vuejs.org",
            "nextjs.org",
            "nuxtjs.org",
            "svelte.dev",
            "flutter.dev",
            "firebase.google.com",
            "cloud.google.com",
            "aws.amazon.com",
            "docs.aws.amazon.com"
        ]
        
        return jsRequiredSites.contains { host.contains($0) }
    }
    
    func renderPageWithCustomJS(url: URL, jsCode: String) async throws -> String {
        guard let webView = webView else {
            throw RenderingError.webViewNotAvailable
        }
        
        isRendering = true
        currentRenderingURL = url.absoluteString
        renderingProgress = 0.0
        
        defer {
            isRendering = false
            currentRenderingURL = ""
            renderingProgress = 0.0
        }
        
        logger.info("Starting enhanced JavaScript rendering for Apple docs: \(url.absoluteString)")
        
        return try await withCheckedThrowingContinuation { continuation in
            renderingContinuation = continuation
            
            // Set a timeout
            Task {
                try await Task.sleep(nanoseconds: UInt64(config.networkTimeout * 1_000_000_000))
                if renderingContinuation != nil {
                    renderingContinuation?.resume(throwing: RenderingError.timeout)
                    renderingContinuation = nil
                }
            }
            
            // Start loading the page
            let request = URLRequest(url: url)
            webView.load(request)
            
            // Store the custom JS code to execute after page load
            self.customJSCode = jsCode
        }
    }
    
    private var customJSCode: String?
    
    private func executeCustomJavaScript() async throws -> String {
        guard let webView = webView, let jsCode = customJSCode else {
            return try await extractRenderedHTML()
        }
        
        logger.info("Executing custom JavaScript for Apple docs enhancement")
        
        // Wait for the page to be ready
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Execute the custom JavaScript
        do {
            _ = try await webView.evaluateJavaScript(jsCode)
            logger.info("Custom JavaScript executed successfully")
        } catch {
            logger.warning("Custom JavaScript execution failed: \(error), continuing with standard extraction")
        }
        
        // Wait a bit more for the custom JS to take effect
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Extract the enhanced HTML
        let html = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String
        
        guard let renderedHTML = html, !renderedHTML.isEmpty else {
            throw RenderingError.emptyContent
        }
        
        renderingProgress = 1.0
        logger.info("Successfully extracted enhanced HTML (\(renderedHTML.count) characters)")
        
        // Clean up
        customJSCode = nil
        
        return renderedHTML
    }
}

// MARK: - WKNavigationDelegate

extension JavaScriptRenderer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logger.debug("WebView finished loading")
        renderingProgress = 0.6
        
        // Give the page time to execute JavaScript and load dynamic content
        Task {
            do {
                let html: String
                if customJSCode != nil {
                    html = try await executeCustomJavaScript()
                } else {
                    html = try await extractRenderedHTML()
                }
                renderingContinuation?.resume(returning: html)
                renderingContinuation = nil
            } catch {
                renderingContinuation?.resume(throwing: error)
                renderingContinuation = nil
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.error("WebView navigation failed: \(error.localizedDescription)")
        renderingContinuation?.resume(throwing: RenderingError.navigationFailed(error))
        renderingContinuation = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logger.error("WebView provisional navigation failed: \(error.localizedDescription)")
        renderingContinuation?.resume(throwing: RenderingError.navigationFailed(error))
        renderingContinuation = nil
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        logger.debug("WebView started loading")
        renderingProgress = 0.2
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        logger.debug("WebView committed navigation")
        renderingProgress = 0.4
    }
    
    func shouldUseJavaScriptRendering(for url: URL, content: String) -> Bool {
        // Check if the content suggests JavaScript is required
        let jsIndicators = [
            "requires javascript",
            "enable javascript",
            "javascript is disabled",
            "please enable javascript",
            "this page requires javascript",
            "javascript must be enabled",
            "noscript"
        ]
        
        let lowercaseContent = content.lowercased()
        let hasJSIndicators = jsIndicators.contains { lowercaseContent.contains($0) }
        
        // Also check if it's a known JS-heavy site
        let isJSRequiredSite = isJavaScriptRequired(for: url)
        
        // Check if content is suspiciously short (likely just a shell)
        let isSuspiciouslyShort = content.count < 1000
        
        return hasJSIndicators || isJSRequiredSite || isSuspiciouslyShort
    }
}

// MARK: - Error Types

enum RenderingError: LocalizedError {
    case webViewNotAvailable
    case timeout
    case emptyContent
    case navigationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .webViewNotAvailable:
            return "WebView is not available for rendering"
        case .timeout:
            return "Rendering timed out"
        case .emptyContent:
            return "No content was rendered"
        case .navigationFailed(let error):
            return "Navigation failed: \(error.localizedDescription)"
        }
    }
}

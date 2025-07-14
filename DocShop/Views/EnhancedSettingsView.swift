import SwiftUI
import UniformTypeIdentifiers

struct EnhancedSettingsView: View {
    @ObservedObject private var config = DocumentProcessorConfig.shared
    @ObservedObject private var library = DocLibraryIndex.shared
    @State private var hoveredSection: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                javascriptRenderingSection
                aiEnhancementSection
                libraryManagementSection
            }
            .padding(16)
        }
        .glassy()
        .background(Color.clear)
        .navigationTitle("Settings")
    }
    
    private var javascriptRenderingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "curlybraces")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("JavaScript Rendering")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable JavaScript Rendering", isOn: Binding(
                    get: { config.enableJavaScriptRendering },
                    set: { config.enableJavaScriptRendering = $0 }
                ))
                .toggleStyle(LiquidGlassToggleStyle())
                
                Text("Render JavaScript-heavy sites for complete content extraction")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if config.enableJavaScriptRendering {
                    Toggle("Auto-detect JS requirement", isOn: Binding(
                        get: { config.autoDetectJSRequirement },
                        set: { config.autoDetectJSRequirement = $0 }
                    ))
                    .toggleStyle(LiquidGlassToggleStyle())
                    .padding(.leading, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("JavaScript Timeout")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(config.jsRenderingTimeout))s")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { config.jsRenderingTimeout },
                            set: { config.jsRenderingTimeout = $0 }
                        ), in: 10...120, step: 5)
                            .accentColor(.gray)
                    }
                    .padding(.leading, 8)
                    
                    Text("Increase timeout if JavaScript executions are failing and reverting to standard script processing")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.leading, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .gray.opacity(0.5), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(hoveredSection == "javascript" ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.8), value: hoveredSection)
        .onHover { isHovered in
            hoveredSection = isHovered ? "javascript" : nil
        }
    }
    
    private var aiEnhancementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("AI Enhancement")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Apple Intelligence Status")
                        .font(.body)
                    
                    Spacer()
                    
                    AIStatusIndicator()
                }
                
                Text("AI features enhance document processing with intelligent analysis and smart link discovery")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                NavigationLink(destination: AISearchView()) {
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.purple)
                        Text("AI-Powered Search")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(hoveredSection == "ai" ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.8), value: hoveredSection)
        .onHover { isHovered in
            hoveredSection = isHovered ? "ai" : nil
        }
    }
    
    private var libraryManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Library Management")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(library.documents.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button("Refresh") {
                    library.refreshLibrary()
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(hoveredSection == "library" ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.8), value: hoveredSection)
        .onHover { isHovered in
            hoveredSection = isHovered ? "library" : nil
        }
    }
}

// MARK: - Custom Styles

struct LiquidGlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(.primary)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.white : Color.gray.opacity(0.1))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.8), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.clear)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}

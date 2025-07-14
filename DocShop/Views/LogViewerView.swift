import SwiftUI

struct LogViewerView: View {
    @State private var logContent: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Application Log")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Refresh") { loadLog() }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            Divider()
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    Text(logContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Color(.textBackgroundColor))
            }
        }
        .glassy()
        .onAppear(perform: loadLog)
    }
    
    private func loadLog() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let content = DocumentLogger.shared.getLogContent()
            DispatchQueue.main.async {
                self.logContent = content
                self.isLoading = false
            }
        }
    }
}

#Preview {
    LogViewerView()
}

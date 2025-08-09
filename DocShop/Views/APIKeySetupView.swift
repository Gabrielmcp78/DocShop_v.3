import SwiftUI

struct APIKeySetupView: View {
    @Binding var isPresented: Bool
    @State private var apiKey: String = KeychainHelper.shared.getAPIKey(for: "gemini") ?? ""
    @ObservedObject private var geminiAPI = EnhancedGeminiAPI.shared
    @State private var showSuccess = false
    @State private var showError: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gemini API Key")) {
                    SecureField("Enter API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if let error = geminiAPI.lastError {
                        Text(error).font(.caption).foregroundColor(.red)
                    }
                }

                Section(header: Text("Connection Status")) {
                    HStack {
                        Circle()
                            .fill(geminiAPI.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(geminiAPI.isConnected ? "Connected" : "Not Connected")
                            .foregroundColor(.secondary)
                    }
                    if let op = geminiAPI.currentOperation {
                        VStack(alignment: .leading) {
                            Text(op).font(.caption)
                            ProgressView(value: geminiAPI.operationProgress)
                        }
                    }
                }

                if let errorMsg = showError {
                    Section {
                        Text(errorMsg).font(.caption).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Configure AI")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveKey() }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("API Key Saved", isPresented: $showSuccess) {
                Button("OK") { isPresented = false }
            } message: {
                Text("Gemini API key has been saved and connection is active.")
            }
        }
    }

    private func saveKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        EnhancedGeminiAPI.shared.setAPIKey(trimmed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if EnhancedGeminiAPI.shared.isConnected {
                showSuccess = true
                showError = nil
            } else {
                showError = "Failed to connect. Please verify the API key."
            }
        }
    }
}

#Preview {
    StatefulPreviewWrapper(true) { binding in
        APIKeySetupView(isPresented: binding)
    }
}

// Helper to preview views with @Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View { content($value) }
}

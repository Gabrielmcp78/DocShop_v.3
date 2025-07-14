import SwiftUI

struct APIKeyInputView: View {
    @State private var apiKey: String = ""
    @State private var saved: Bool = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Gemini API Key")
                .font(.title2)
                .fontWeight(.semibold)
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button("Save Key") {
                if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    error = "API key cannot be empty."
                    saved = false
                } else {
                    KeychainHelper.shared.saveAPIKey(apiKey)
                    saved = true
                    error = nil
                }
            }
            .buttonStyle(.borderedProminent)
            if saved {
                Text("API key saved securely!")
                    .foregroundColor(.green)
            }
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
} 
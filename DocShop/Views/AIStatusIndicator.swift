import SwiftUI
import FoundationModels

struct AIStatusIndicator: View {
    @ObservedObject private var aiAnalyzer = AIDocumentAnalyzer.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusIcon: String {
        switch aiAnalyzer.modelAvailability {
        case .available:
            return "checkmark.circle.fill"
        case .unavailable(.deviceNotEligible):
            return "xmark.circle.fill"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "exclamationmark.triangle.fill"
        case .unavailable(.modelNotReady):
            return "clock.fill"
        case .unavailable:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch aiAnalyzer.modelAvailability {
        case .available:
            return .green
        case .unavailable(.deviceNotEligible):
            return .red
        case .unavailable(.appleIntelligenceNotEnabled):
            return .orange
        case .unavailable(.modelNotReady):
            return .blue
        case .unavailable:
            return .gray
        }
    }
    
    private var statusText: String {
        switch aiAnalyzer.modelAvailability {
        case .available:
            return "Available"
        case .unavailable(.deviceNotEligible):
            return "Not Supported"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Disabled"
        case .unavailable(.modelNotReady):
            return "Loading"
        case .unavailable:
            return "Unavailable"
        }
    }
}

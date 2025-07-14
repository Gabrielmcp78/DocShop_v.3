import SwiftUI

struct SystemValidationView: View {
    @State private var validationResult: ValidationResult?
    @State private var isValidating = false
    @State private var quickHealth = SystemHealth(level: .healthy, issues: [])
    
    private let validator = SystemValidator.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                quickHealthSection
                
                validationSection
                
                if let result = validationResult {
                    resultsSection(result)
                }
            }
            .padding()
        }
        .navigationTitle("System Validation")
        .onAppear {
            updateQuickHealth()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Validation")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Comprehensive system health and integrity checks")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var quickHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Health Check")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Circle()
                    .fill(Color(quickHealth.level.color))
                    .frame(width: 16, height: 16)
                
                Text("System Status: \(quickHealth.level.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Refresh") {
                    updateQuickHealth()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if !quickHealth.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Issues:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(quickHealth.issues, id: \.self) { issue in
                        Text("• \(issue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(quickHealth.level.color).opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Full System Validation")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Performs comprehensive checks of all system components including file system, security, configuration, and performance.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: runFullValidation) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text(isValidating ? "Validating..." : "Run Full Validation")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isValidating)
                
                if let result = validationResult {
                    Text("Last run: \(formatDate(result.timestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func resultsSection(_ result: ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Validation Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(result.severity.color))
                        .frame(width: 8, height: 8)
                    Text(result.severity.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // Summary
            HStack(spacing: 20) {
                VStack {
                    Text("\(result.issues.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Errors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(result.warnings.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Warnings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Issues
            if !result.issues.isEmpty {
                issuesSection(title: "Errors", issues: result.issues, color: .red)
            }
            
            if !result.warnings.isEmpty {
                issuesSection(title: "Warnings", issues: result.warnings, color: .orange)
            }
            
            if result.issues.isEmpty && result.warnings.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("All validation checks passed")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text("Your system is healthy and secure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func issuesSection(title: String, issues: [ValidationIssue], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            ForEach(Array(issues.enumerated()), id: \.offset) { index, issue in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(issue.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    
                    Text(issue.message)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(issue.details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(color.opacity(0.05))
                .cornerRadius(6)
            }
        }
    }
    
    private func updateQuickHealth() {
        quickHealth = validator.performQuickHealthCheck()
    }
    
    private func runFullValidation() {
        isValidating = true
        
        Task {
            let result = await validator.performSystemValidation()
            
            await MainActor.run {
                validationResult = result
                isValidating = false
                updateQuickHealth()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SystemValidationView()
}
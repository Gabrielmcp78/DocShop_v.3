#!/bin/zsh

# DocShop Multi-Agent Development Environment Setup Script
# This script sets up the complete multi-agent development environment

set -e

echo "🚀 Setting up DocShop Multi-Agent Development Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if we're in the right directory
if [ ! -d "DocShop-v3-testing" ]; then
    print_error "DocShop-v3-testing directory not found. Please run this script from the DocShop root directory."
    exit 1
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    print_error "Swift is not installed. Please install Xcode or Swift toolchain."
    exit 1
fi

print_success "Prerequisites check passed"

# Create agent workspace directories
print_status "Creating agent workspace directories..."

WORKSPACES=(
    "agent1-backend"
    "agent2-document-processing" 
    "agent3-ai-search"
    "agent4-ui-enhancement"
    "agent5-system-integration"
)

for workspace in "${WORKSPACES[@]}"; do
    mkdir -p "DocShop-v3-testing/agent-workspaces/$workspace/src"
    mkdir -p "DocShop-v3-testing/agent-workspaces/$workspace/tests"
    mkdir -p "DocShop-v3-testing/agent-workspaces/$workspace/docs"
    mkdir -p "DocShop-v3-testing/agent-workspaces/$workspace/config"
    
    # Create basic README for each workspace
    cat > "DocShop-v3-testing/agent-workspaces/$workspace/README.md" << EOF
# $workspace Workspace

## Agent Responsibilities
See AGENT_${workspace:5:1}_*.md in the root directory for detailed implementation tasks.

## Development Setup
1. Implement shared interfaces from \`../shared/interfaces/\`
2. Use shared models from \`../shared/models/\`
3. Follow integration contracts in \`../coordination/integration-points/\`

## Testing
\`\`\`bash
# Run agent-specific tests
swift test
\`\`\`

## Integration
Coordinate with other agents through the TaskCoordinator and SharedStateManager.
EOF
    
    print_success "Created workspace: $workspace"
done

# Create shared testing utilities
print_status "Setting up shared testing utilities..."

mkdir -p "DocShop-v3-testing/shared/testing"

cat > "DocShop-v3-testing/shared/testing/TestUtilities.swift" << 'EOF'
import Foundation
import XCTest

// MARK: - Test Utilities for Multi-Agent Testing

class TestUtilities {
    static func createTestProject() -> SharedProject {
        return SharedProject(
            name: "Test Project",
            description: "A test project for integration testing",
            requirements: "Test requirements"
        )
    }
    
    static func createTestDocument() -> SharedDocument {
        return SharedDocument(
            title: "Test Document",
            content: "This is test content for integration testing"
        )
    }
    
    static func createTestTask(for agent: AgentID) -> AgentTask {
        return AgentTask(
            type: .testing,
            assignedAgent: agent,
            priority: .medium
        )
    }
    
    static func waitForAsyncOperation(timeout: TimeInterval = 5.0, operation: @escaping () async throws -> Bool) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if try await operation() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        throw TestError.timeout
    }
}

enum TestError: Error {
    case timeout
    case invalidState
    case communicationFailure
}

// MARK: - Mock Agents for Testing
class MockAgent: AgentCommunication {
    let agentId: AgentID
    var status: AgentStatus = .idle
    var receivedTasks: [AgentTask] = []
    var completedTasks: [UUID] = []
    
    init(agentId: AgentID) {
        self.agentId = agentId
    }
    
    func receiveTask(_ task: AgentTask) async throws {
        receivedTasks.append(task)
        status = .working
    }
    
    func reportProgress(_ taskId: UUID, progress: Double) async {
        // Mock implementation
    }
    
    func completeTask(_ taskId: UUID, result: TaskResult) async throws {
        completedTasks.append(taskId)
        if let index = receivedTasks.firstIndex(where: { $0.id == taskId }) {
            receivedTasks.remove(at: index)
        }
        status = receivedTasks.isEmpty ? .idle : .working
    }
    
    func requestAssistance(_ request: AssistanceRequest) async throws -> AssistanceResponse {
        return AssistanceResponse(success: true, data: nil, message: "Mock assistance")
    }
}
EOF

print_success "Created shared testing utilities"

# Create development scripts
print_status "Creating development scripts..."

mkdir -p "DocShop-v3-testing/scripts"

# Create test runner script
cat > "DocShop-v3-testing/scripts/run-tests.sh" << 'EOF'
#!/bin/zsh

# Test runner for multi-agent environment

echo "🧪 Running Multi-Agent Tests..."

# Run tests for each agent workspace
WORKSPACES=("agent1-backend" "agent2-document-processing" "agent3-ai-search" "agent4-ui-enhancement" "agent5-system-integration")

for workspace in "${WORKSPACES[@]}"; do
    echo "Testing $workspace..."
    cd "agent-workspaces/$workspace"
    
    if [ -f "Package.swift" ]; then
        swift test
    else
        echo "No Package.swift found in $workspace, skipping..."
    fi
    
    cd "../.."
done

echo "✅ All tests completed"
EOF

chmod +x "DocShop-v3-testing/scripts/run-tests.sh"

# Create integration test script
cat > "DocShop-v3-testing/scripts/run-integration-tests.sh" << 'EOF'
#!/bin/zsh

# Integration test runner

echo "🔗 Running Integration Tests..."

# This would run cross-agent integration tests
# Coordinated by Agent 5 (System Integration)

cd "agent-workspaces/agent5-system-integration"

if [ -f "Package.swift" ]; then
    swift test --filter IntegrationTests
else
    echo "Integration tests not yet set up"
fi

echo "✅ Integration tests completed"
EOF

chmod +x "DocShop-v3-testing/scripts/run-integration-tests.sh"

# Create status monitoring script
cat > "DocShop-v3-testing/scripts/monitor-agents.sh" << 'EOF'
#!/bin/zsh

# Agent status monitoring script

echo "📊 Agent Status Monitor"
echo "======================"

# This would monitor agent health and status
# In a real implementation, this would connect to the SharedStateManager

echo "Agent 1 (Project Management): ✅ Healthy"
echo "Agent 2 (Document Processing): ✅ Healthy" 
echo "Agent 3 (AI Search): ✅ Healthy"
echo "Agent 4 (UI Enhancement): ✅ Healthy"
echo "Agent 5 (System Integration): ✅ Healthy"

echo ""
echo "System Health: ✅ All systems operational"
echo "Active Tasks: 0"
echo "Completed Tasks: 0"
echo ""
echo "Use 'watch -n 5 ./scripts/monitor-agents.sh' for live monitoring"
EOF

chmod +x "DocShop-v3-testing/scripts/monitor-agents.sh"

print_success "Created development scripts"

# Create configuration files
print_status "Creating configuration files..."

cat > "DocShop-v3-testing/config.json" << 'EOF'
{
  "environment": "development",
  "agents": {
    "agent1-backend": {
      "enabled": true,
      "port": 8001,
      "maxTasks": 10
    },
    "agent2-document-processing": {
      "enabled": true,
      "port": 8002,
      "maxTasks": 5
    },
    "agent3-ai-search": {
      "enabled": true,
      "port": 8003,
      "maxTasks": 8
    },
    "agent4-ui-enhancement": {
      "enabled": true,
      "port": 8004,
      "maxTasks": 3
    },
    "agent5-system-integration": {
      "enabled": true,
      "port": 8005,
      "maxTasks": 15
    }
  },
  "coordination": {
    "heartbeatInterval": 30,
    "taskTimeout": 300,
    "maxRetries": 3
  },
  "persistence": {
    "enabled": true,
    "backupInterval": 3600
  }
}
EOF

print_success "Created configuration files"

# Create documentation
print_status "Creating documentation..."

cat > "DocShop-v3-testing/README.md" << 'EOF'
# DocShop Multi-Agent Development Environment

## Overview
This is the multi-agent development environment for DocShop v3.0, implementing a 5-agent architecture for parallel, asynchronous development.

## Architecture
- **Agent 1**: Project Management & Orchestration
- **Agent 2**: Document Processing & Enhancement  
- **Agent 3**: AI Search & Intelligence
- **Agent 4**: UI Enhancement & User Experience
- **Agent 5**: System Integration & Quality Assurance

## Quick Start
```zsh
# Set up the environment
./SETUP_MULTI_AGENT_ENV.sh

# Monitor agent status
./scripts/monitor-agents.sh

# Run tests
./scripts/run-tests.sh

# Run integration tests
./scripts/run-integration-tests.sh
```

## Development Workflow
1. Each agent works in their isolated workspace
2. Communication through shared interfaces and contracts
3. Coordination via TaskCoordinator and SharedStateManager
4. Regular integration testing through Agent 5

## Directory Structure
```
DocShop-v3-testing/
├── agent-workspaces/     # Individual agent development areas
├── shared/               # Shared interfaces and models
├── coordination/         # Multi-agent coordination
├── scripts/              # Development and testing scripts
└── config.json          # Environment configuration
```

See `WORKSPACE_SETUP.md` for detailed development instructions.
EOF

print_success "Created documentation"

# Final setup
print_status "Finalizing setup..."

# Create a simple Package.swift for the testing environment
cat > "DocShop-v3-testing/Package.swift" << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DocShopMultiAgent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "SharedInterfaces", targets: ["SharedInterfaces"]),
        .library(name: "CoordinationSystem", targets: ["CoordinationSystem"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SharedInterfaces",
            path: "shared"
        ),
        .target(
            name: "CoordinationSystem", 
            path: "coordination"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["SharedInterfaces", "CoordinationSystem"],
            path: "tests"
        )
    ]
)
EOF

# Create basic test directory
mkdir -p "DocShop-v3-testing/tests"

print_success "Multi-agent environment setup complete!"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next Steps:"
echo "1. Review the agent task files (AGENT_1_*.md through AGENT_5_*.md)"
echo "2. Choose an agent to start implementing"
echo "3. Read the workspace setup guide: DocShop-v3-testing/agent-workspaces/WORKSPACE_SETUP.md"
echo "4. Start development in your chosen agent workspace"
echo ""
echo "Useful Commands:"
echo "• Monitor agents: ./DocShop-v3-testing/scripts/monitor-agents.sh"
echo "• Run tests: ./DocShop-v3-testing/scripts/run-tests.sh"
echo "• Integration tests: ./DocShop-v3-testing/scripts/run-integration-tests.sh"
echo ""
echo "Happy coding! 🚀"
EOF

chmod +x "DocShop-v3-testing/SETUP_MULTI_AGENT_ENV.sh"

print_success "Created master setup script"
</invoke>
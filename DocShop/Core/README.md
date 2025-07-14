# DocShop Orchestration & Agent System

## Overview
This directory contains the core orchestration, agent management, SDK generation, and progress tracking logic for the next-generation DocShop system.

## Key Components

- **AgentOrchestrator.swift**: Central engine for project/task/agent orchestration and monitoring.
- **SDKGenerator.swift**: Generates SDKs and client libraries from project requirements and technical documents.
- **ProgressTracker.swift**: Tracks project and agent progress, benchmarks, and drift.
- **ContextManager.swift**: Manages project and agent context, reinjection, and alignment.
- **DevelopmentAgent.swift**: Represents an agent that can be assigned tasks, execute them, and receive context updates.
- **TaskDistributor.swift**: Distributes tasks to agents based on specialization and workload.
- **BenchmarkEngine.swift**: Runs and validates project and task benchmarks.

## Data Models (see Models/)
- **Project.swift**: Project, ProjectTask, ProjectRequirements, Benchmark, and related types.
- **AgentTypes.swift**: AgentSpecialization, AgentCapability, AgentStatus, TaskResult.
- **AgentContextTypes.swift**: AgentContext, ProjectContext, ContextAlignment.

## Integration Points
- Orchestrator interacts with DocumentProcessor, AIDocumentAnalyzer, and UI components.
- Agents receive tasks and context, execute work, and report progress.
- SDKGenerator produces client libraries and documentation for projects.
- ProgressTracker and ContextManager ensure agents stay on task and benchmarks are met.

## Extensibility
- All components are designed for future expansion and integration with UI and backend services. 
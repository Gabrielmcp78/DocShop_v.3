import Foundation

class TaskDistributor {
    func distribute(tasks: [ProjectTask], to agents: [DevelopmentAgent]) {
        guard !agents.isEmpty else { return }
        var agentTaskCounts = [UUID: Int]()
        for agent in agents { agentTaskCounts[agent.id] = 0 }
        
        for var task in tasks {
            let bestAgent = agents.min { a, b in
                let aScore = score(agent: a, task: task) + (agentTaskCounts[a.id] ?? 0)
                let bScore = score(agent: b, task: task) + (agentTaskCounts[b.id] ?? 0)
                return aScore < bScore
            }
            
            if let agent = bestAgent {
                agentTaskCounts[agent.id, default: 0] += 1
                task.assignedAgentID = agent.id
                AgentOrchestrator.shared.updateStatus(for: task, to: .assigned)
                
                agent.perform(task: task) { result in
                    let finalStatus: ProjectTaskStatus = result.success ? .completed : .error
                    AgentOrchestrator.shared.updateStatus(for: task, to: finalStatus)
                    print("Task '\(task.title)' completed by agent '\(agent.name)' with result: \(result.success ? "Success" : "Failure")")
                }
            }
        }
    }
    private func score(agent: DevelopmentAgent, task: ProjectTask) -> Int {
        // Score agent-task fit by matching capabilities to task context
        let context = task.context.info.lowercased()
        let capMatch = agent.capabilities.map { $0.rawValue.lowercased() }.contains { context.contains($0) }
        return capMatch ? 0 : 10 // Lower is better
    }
}

//class BenchmarkEngine {
    //func runBenchmarks(for project: Project) {
        // Simulate running benchmarks for a project
      //  for benchmark in project.benchmarks {
        //    print("Running benchmark '", benchmark.criteria.rawValue, "' for project '", project.name, "'...")
            // Simulate result
         //   let passed = Bool.random()
         //   let result = BenchmarkResult(
          //      taskID: UUID(),
         //       passed: passed,
          //      details: passed ? "Passed" : "Failed"
          //  )
          //  print("Benchmark '", benchmark.criteria.rawValue, "': ", result.details)
        
    


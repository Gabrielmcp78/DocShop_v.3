import Foundation

class TaskDistributor {
    func distribute(tasks: [ProjectTask], to agents: [DevelopmentAgent]) {
        // Assign tasks to agents based on best fit (capabilities, load balancing)
        guard !agents.isEmpty else { return }
        var agentTaskCounts = [UUID: Int]()
        for agent in agents { agentTaskCounts[agent.id] = 0 }
        let executor = LocalAgentExecutor()
        for task in tasks {
            // Find best-fit agent (by capability match, then least loaded)
            let bestAgent = agents.min { a, b in
                let aScore = score(agent: a, task: task) + (agentTaskCounts[a.id] ?? 0)
                let bScore = score(agent: b, task: task) + (agentTaskCounts[b.id] ?? 0)
                return aScore < bScore
            }
            if let agent = bestAgent {
                agentTaskCounts[agent.id, default: 0] += 1
                executor.execute(task: task, for: agent) { result in
                    // Log or handle result as needed
                    print("Task '", task.title, "' completed by agent '", agent.name, "': ", result.success ? "Success" : "Failure")
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
        
    


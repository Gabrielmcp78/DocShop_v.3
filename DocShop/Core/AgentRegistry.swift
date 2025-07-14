import Foundation

class AgentRegistry {
    static let shared = AgentRegistry()
    private var agents: [DevelopmentAgent] = []
    
    private init() {}
    
    func register(agent: DevelopmentAgent) {
        agents.append(agent)
    }
    
    func matchAgents(for requirements: ProjectRequirements) -> [DevelopmentAgent] {
        // Match agents by specialization, platform, and capabilities using a scoring system
        let scored = agents.map { agent -> (DevelopmentAgent, Int) in
            var score = 0
            // Match by specialization (if any requirements map to agent specialization)
            if requirements.documentationRequirements.map({ $0.rawValue.lowercased() }).contains(agent.specialization.rawValue.lowercased()) {
                score += 3
            }
            // Match by target languages
            let agentLangs = Set(agent.capabilities.map { $0.rawValue })
            let reqLangs = Set(requirements.targetLanguages.map { $0.rawValue })
            if !agentLangs.isDisjoint(with: reqLangs) {
                score += 2
            }
            // Match by SDK features
            let agentSkills = Set(agent.capabilities.map { $0.rawValue })
            let reqSkills = Set(requirements.sdkFeatures.map { $0.rawValue })
            if !agentSkills.isDisjoint(with: reqSkills) {
                score += 1
            }
            // (Optional) Add more criteria as needed
            return (agent, score)
        }
        // Return agents sorted by score, highest first, and filter out zero-score
        return scored.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.map { $0.0 }
    }
    
    func allAgents() -> [DevelopmentAgent] {
        return agents
    }
} 
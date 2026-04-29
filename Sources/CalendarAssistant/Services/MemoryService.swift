import Foundation
import Observation

/// Persists the last N conversation turns so the LLM has short-term context.
/// Upgrade path: swap UserDefaults for CoreData or CloudKit without changing callers.
@Observable
final class MemoryService {
    private let maxTurns = 5
    private let storageKey = "conversation_history"

    private(set) var turns: [(role: String, content: String)] = []

    init() {
        load()
    }

    /// Formatted context block injected into LLM prompts.
    var contextString: String {
        guard !turns.isEmpty else { return "" }
        let lines = turns.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        return "Recent conversation:\n\(lines)\n\n"
    }

    func append(role: String, content: String) {
        turns.append((role: role, content: content))
        if turns.count > maxTurns {
            turns.removeFirst(turns.count - maxTurns)
        }
        save()
    }

    func clear() {
        turns.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Persistence

    private func save() {
        let encoded = turns.map { ["role": $0.role, "content": $0.content] }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    private func load() {
        guard let stored = UserDefaults.standard.array(forKey: storageKey) as? [[String: String]] else { return }
        turns = stored.compactMap { dict in
            guard let role = dict["role"], let content = dict["content"] else { return nil }
            return (role: role, content: content)
        }
    }
}

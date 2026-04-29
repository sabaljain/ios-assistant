import Foundation
import Observation

enum AppState: Equatable {
    case idle
    case processing
    case success(String)
    case failure(String)
}

/// Central coordinator. Routes user input to the matching connector.
/// To add a new capability: init a connector, append it to `connectors`.
@Observable
final class AppViewModel {
    let memory = MemoryService()

    private(set) var state: AppState = .idle

    private let connectors: [any Connector]
    private let calendarConnector: CalendarConnector

    init() {
        let cal = CalendarConnector()
        calendarConnector = cal
        connectors = [cal]
    }

    func requestPermissions() async {
        await calendarConnector.requestAccess()
    }

    func process(input: String) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        state = .processing
        memory.append(role: "user", content: trimmed)

        do {
            let connector = route(input: trimmed)
            let confirmation = try await connector.execute(input: trimmed, memory: memory)
            memory.append(role: "assistant", content: confirmation)
            state = .success(confirmation)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failure(message)
        }
    }

    func reset() {
        state = .idle
    }

    // MARK: - Routing

    private func route(input: String) -> any Connector {
        let lowercased = input.lowercased()
        for connector in connectors {
            if connector.intentKeywords.contains(where: { lowercased.contains($0) }) {
                return connector
            }
        }
        // Default to first connector (calendar) until more connectors are added
        return connectors[0]
    }
}

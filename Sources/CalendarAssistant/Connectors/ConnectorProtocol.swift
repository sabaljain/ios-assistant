import Foundation

/// Base protocol for all assistant capabilities.
/// Add new connectors (Reminders, Email, Contacts, etc.) by conforming to this protocol
/// and registering them in AppViewModel.
protocol Connector {
    /// Keywords that help route user intent to this connector.
    var intentKeywords: [String] { get }

    /// Executes the connector's action for the given natural language input.
    /// Returns a human-readable confirmation string shown to the user.
    func execute(input: String, memory: MemoryService) async throws -> String
}

import EventKit
import Foundation
import Observation

enum CalendarError: LocalizedError {
    case accessDenied
    case noDefaultCalendar
    case invalidDate(String)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied. Enable it in Settings > Privacy & Security > Calendars."
        case .noDefaultCalendar:
            return "No default calendar found. Set one up in the Calendar app."
        case .invalidDate(let raw):
            return "Couldn't parse the date '\(raw)'. Try adding a specific time, e.g. '2pm'."
        case .saveFailed(let error):
            return "Failed to save event: \(error.localizedDescription)"
        }
    }
}

@Observable
final class CalendarConnector: Connector {
    let intentKeywords = ["calendar", "meeting", "lunch", "dinner", "event", "schedule", "appointment", "call", "session", "standup"]

    private let eventStore = EKEventStore()
    private let llm = FoundationModelsService()
    private(set) var accessGranted = false

    // MARK: - Permissions

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run { self.accessGranted = granted }
        } catch {
            await MainActor.run { self.accessGranted = false }
        }
    }

    // MARK: - ConnectorProtocol

    func execute(input: String, memory: MemoryService) async throws -> String {
        guard accessGranted else { throw CalendarError.accessDenied }

        let details = try await llm.respond(
            to: input,
            generating: CalendarEventDetails.self,
            memory: memory
        )

        try await save(details)

        var confirmation = "Created: \(details.title)"
        if let start = parseDate(details.startDateISO8601) {
            let formatted = start.formatted(date: .abbreviated, time: .shortened)
            confirmation += " on \(formatted)"
        }
        return confirmation
    }

    // MARK: - Private

    private func save(_ details: CalendarEventDetails) async throws {
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw CalendarError.noDefaultCalendar
        }
        guard let start = parseDate(details.startDateISO8601) else {
            throw CalendarError.invalidDate(details.startDateISO8601)
        }
        guard let end = parseDate(details.endDateISO8601) else {
            throw CalendarError.invalidDate(details.endDateISO8601)
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = details.title
        event.startDate = start
        event.endDate = end
        event.calendar = calendar
        if !details.location.isEmpty { event.location = details.location }
        if !details.notes.isEmpty { event.notes = details.notes }

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarError.saveFailed(error)
        }
    }

    private func parseDate(_ string: String) -> Date? {
        // Full ISO 8601 with time (model's primary output format)
        let withTime = ISO8601DateFormatter()
        withTime.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        if let date = withTime.date(from: string) { return date }

        // Date-only fallback
        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        if let date = dateOnly.date(from: string) { return date }

        // Last resort: explicit format with POSIX locale for non-English devices
        let fallback = DateFormatter()
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        fallback.locale = Locale(identifier: "en_US_POSIX")
        return fallback.date(from: string)
    }
}

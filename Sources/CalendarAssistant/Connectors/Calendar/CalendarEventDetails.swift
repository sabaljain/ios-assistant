import FoundationModels

/// Typed output schema for the on-device LLM.
/// @Generable constrains the model to emit valid instances of this struct.
@Generable
struct CalendarEventDetails {
    @Guide(description: "Title of the calendar event, e.g. 'Lunch with John'")
    var title: String

    @Guide(description: "Start date and time in ISO 8601 format: YYYY-MM-DDTHH:mm:ss, e.g. '2026-04-30T12:00:00'")
    var startDateISO8601: String

    @Guide(description: "End date and time in ISO 8601 format: YYYY-MM-DDTHH:mm:ss, e.g. '2026-04-30T13:00:00'. Default to 1 hour after start if not specified.")
    var endDateISO8601: String

    @Guide(description: "Location or address for the event. Use empty string if not mentioned.")
    var location: String

    @Guide(description: "Extra notes or description for the event. Use empty string if not mentioned.")
    var notes: String
}

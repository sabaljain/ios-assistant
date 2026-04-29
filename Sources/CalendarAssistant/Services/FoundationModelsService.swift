import FoundationModels
import Observation

enum FoundationModelsError: LocalizedError {
    case modelUnavailable
    case sessionError(Error)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence is not available on this device. Enable it in Settings > Apple Intelligence & Siri."
        case .sessionError(let error):
            return "On-device model error: \(error.localizedDescription)"
        }
    }
}

@Observable
final class FoundationModelsService {
    private(set) var isProcessing = false

    func respond<T: Generable>(
        to userInput: String,
        generating type: T.Type,
        memory: MemoryService
    ) async throws -> T {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw FoundationModelsError.modelUnavailable
        }

        isProcessing = true
        defer { isProcessing = false }

        // Inject local date + timezone so the model can resolve relative terms
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        dateFormatter.locale = Locale.current
        let todayString = dateFormatter.string(from: Date())
        let timezone = TimeZone.current.identifier

        let session = LanguageModelSession()
        let prompt = """
        \(memory.contextString)Today is \(todayString) (\(timezone)).
        All dates and times must use ISO 8601 format (YYYY-MM-DDTHH:mm:ss).
        If no end time is given, default to 1 hour after start.
        If no year is given, assume the current year.

        Request: "\(userInput)"
        """

        do {
            let response = try await session.respond(to: prompt, generating: type)
            return response.content
        } catch {
            throw FoundationModelsError.sessionError(error)
        }
    }
}

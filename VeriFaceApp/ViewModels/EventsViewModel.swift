import Foundation

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [EventWithRole] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched: [EventWithRole] = try await APIClient.shared.get(Constants.Event.getAllUserEvents)
            events = fetched.sorted { $0.eventName < $1.eventName }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

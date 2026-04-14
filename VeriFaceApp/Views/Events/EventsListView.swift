import SwiftUI

struct EventsListView: View {
    @StateObject private var vm = EventsViewModel()
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.events.isEmpty {
                    ProgressView("Loading events…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.errorMessage {
                    ContentUnavailableView {
                        Label("Could not load events", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await vm.fetchEvents() } }
                    }
                } else if vm.events.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("You are not a member of any events yet.")
                    )
                } else {
                    List(vm.events) { event in
                        NavigationLink(destination: SessionsView(event: event)) {
                            EventRowView(event: event)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.fetchEvents() }
                }
            }
            .navigationTitle("My Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") { authVM.logout() }
                        .tint(.red)
                }
            }
            .task { await vm.fetchEvents() }
        }
    }
}

struct EventRowView: View {
    let event: EventWithRole

    private var roleColor: Color {
        switch event.role {
        case "owner": return .purple
        case "admin": return .blue
        case "moderator": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(event.eventName)
                    .font(.headline)
                Spacer()
                Text(event.roleLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(roleColor.opacity(0.15))
                    .foregroundStyle(roleColor)
                    .clipShape(Capsule())
            }

            if let location = event.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if let start = event.startDate {
                    Label(formatDate(start), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let end = event.endDate {
                    Label(formatDate(end), systemImage: "calendar.badge.checkmark")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ raw: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: raw) {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return raw
    }
}

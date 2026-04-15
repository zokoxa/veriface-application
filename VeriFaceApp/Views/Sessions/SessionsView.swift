import SwiftUI

struct SessionsView: View {
    let event: EventWithRole
    @StateObject private var vm = SessionsViewModel()
    @State private var showingNewSession = false

    var body: some View {
        Group {
            if vm.isLoading && vm.sessions.isEmpty {
                ProgressView("Loading sessions…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage {
                ContentUnavailableView {
                    Label("Could not load sessions", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await vm.fetchSessions(eventId: event.id) } }
                }
            } else if vm.sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "clock.badge.exclamationmark",
                    description: Text("No sessions have been created for this event yet.")
                )
            } else {
                List(vm.sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session, event: event)) {
                        SessionRowView(session: session)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await vm.fetchSessions(eventId: event.id) }
            }
        }
        .navigationTitle(event.eventName)
        .navigationBarTitleDisplayMode(.large)
        .task { await vm.fetchSessions(eventId: event.id) }
        .toolbar {
            if event.canCheckin {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            NewSessionSheet(event: event, vm: vm, isPresented: $showingNewSession)
        }
    }
}

struct NewSessionSheet: View {
    let event: EventWithRole
    @ObservedObject var vm: SessionsViewModel
    @Binding var isPresented: Bool

    @State private var setStartTime = false
    @State private var startTime = Date()
    @State private var setEndTime = false
    @State private var endTime = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Set start time", isOn: $setStartTime)
                    if setStartTime {
                        DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    }
                    Toggle("Set end time", isOn: $setEndTime)
                    if setEndTime {
                        DatePicker("End", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                    }
                }

                if let error = vm.createError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .disabled(vm.isCreating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await vm.createSession(
                                eventId: event.id,
                                startTime: setStartTime ? startTime : nil,
                                endTime: setEndTime ? endTime : nil
                            )
                            if vm.createError == nil {
                                isPresented = false
                            }
                        }
                    } label: {
                        if vm.isCreating {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(vm.isCreating)
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: SessionOutput

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.displayLabel)
                .font(.headline)

            HStack(spacing: 16) {
                Label(session.formattedStart, systemImage: "play.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(session.formattedEnd, systemImage: "stop.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Hub screen for a single session — shows attendance + check-in button
struct SessionDetailView: View {
    let session: SessionOutput
    let event: EventWithRole

    var body: some View {
        List {
            // Check-In section (only for moderators+)
            if event.canCheckin {
                Section("Face Check-In") {
                    NavigationLink(destination: CheckInView(sessionId: session.id)) {
                        Label("Launch Camera", systemImage: "camera.fill")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Section("Attendance") {
                NavigationLink(destination: AttendanceView(session: session, event: event)) {
                    Label("View Attendance", systemImage: "person.3.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.displayLabel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

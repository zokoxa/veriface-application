import SwiftUI

struct AttendanceView: View {
    let session: SessionOutput
    let event: EventWithRole

    @StateObject private var vm = AttendanceViewModel()
    @State private var searchText = ""
    @State private var filterStatus: AttendanceStatus? = nil

    private var filtered: [AttendanceWithUser] {
        vm.attendance.filter { record in
            let matchSearch = searchText.isEmpty ||
                record.fullName.localizedCaseInsensitiveContains(searchText) ||
                (record.email ?? "").localizedCaseInsensitiveContains(searchText)
            let matchFilter = filterStatus == nil || record.status == filterStatus
            return matchSearch && matchFilter
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            if let summary = vm.summary {
                summaryBar(summary)
            }

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    ForEach(AttendanceStatus.allCases, id: \.self) { status in
                        FilterChip(label: status.label, isSelected: filterStatus == status,
                                   color: status.color) {
                            filterStatus = filterStatus == status ? nil : status
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()

            // List
            if vm.isLoading && vm.attendance.isEmpty {
                ProgressView("Loading attendance…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await vm.load(sessionId: session.id) } }
                }
            } else if filtered.isEmpty {
                ContentUnavailableView("No Results", systemImage: "person.slash")
            } else {
                List(filtered) { record in
                    AttendanceRowView(record: record,
                                     canEdit: event.canCheckin,
                                     sessionId: session.id) { newStatus in
                        Task { await vm.updateStatus(userId: record.userId,
                                                     sessionId: session.id,
                                                     status: newStatus) }
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.load(sessionId: session.id) }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name or email")
        .navigationTitle(session.displayLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.wsConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(vm.wsConnected ? "Live" : "Offline")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            vm.connect(sessionId: session.id)
            await vm.load(sessionId: session.id)
        }
        .alert("Update Error", isPresented: Binding(
            get: { vm.updateError != nil },
            set: { if !$0 { vm.updateError = nil } }
        )) {
            Button("OK", role: .cancel) { vm.updateError = nil }
        } message: {
            Text(vm.updateError ?? "")
        }
    }

    @ViewBuilder
    private func summaryBar(_ s: AttendanceSummary) -> some View {
        HStack(spacing: 0) {
            SummaryCell(value: s.present, label: "Present", color: .green)
            Divider().frame(height: 40)
            SummaryCell(value: s.late, label: "Late", color: .orange)
            Divider().frame(height: 40)
            SummaryCell(value: s.absent, label: "Absent", color: .red)
            Divider().frame(height: 40)
            SummaryCell(value: s.total, label: "Total", color: .primary)
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - Sub-components

struct SummaryCell: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct AttendanceRowView: View {
    let record: AttendanceWithUser
    let canEdit: Bool
    let sessionId: Int
    let onStatusChange: (AttendanceStatus) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(record.status.color.opacity(0.15))
                Text(record.initials)
                    .font(.subheadline.bold())
                    .foregroundStyle(record.status.color)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.fullName)
                    .font(.subheadline.bold())
                if let email = record.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status badge / picker
            if canEdit {
                Menu {
                    ForEach(AttendanceStatus.allCases, id: \.self) { status in
                        Button {
                            onStatusChange(status)
                        } label: {
                            Label(status.label, systemImage: status.icon)
                        }
                    }
                } label: {
                    statusBadge
                }
            } else {
                statusBadge
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: record.status.icon)
            Text(record.status.label)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(record.status.color.opacity(0.15))
        .foregroundStyle(record.status.color)
        .clipShape(Capsule())
    }
}

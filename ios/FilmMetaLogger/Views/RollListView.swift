import SwiftUI

struct RollListView: View {
    @EnvironmentObject private var rollStore: RollStore
    @State private var showingNewRoll = false

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                if rollStore.rolls.isEmpty {
                    Text("No rolls yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(rollStore.rolls) { roll in
                    NavigationLink {
                        FrameListView(roll: roll)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(roll.filmStock) • ISO \(roll.iso)")
                                .font(.headline)
                            Text("\(roll.camera) • \(roll.lens)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Started \(Self.displayFormatter.string(from: roll.startTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let endTime = roll.endTime {
                                Text("Ended \(Self.displayFormatter.string(from: endTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let notes = roll.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if roll.isActive {
                            Button("End Roll") {
                                rollStore.endRoll(roll)
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Rolls")
            .toolbar {
                Button("New Roll") {
                    showingNewRoll = true
                }
            }
            .sheet(isPresented: $showingNewRoll) {
                NewRollView()
                    .environmentObject(rollStore)
            }
            .onAppear {
                rollStore.loadRolls()
            }
        }
    }
}

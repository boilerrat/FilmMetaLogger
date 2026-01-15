import SwiftUI

struct FrameListView: View {
    @EnvironmentObject private var frameStore: FrameStore
    let roll: Roll

    @State private var showingNewFrame = false

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    var body: some View {
        List {
            if frameStore.frames.isEmpty {
                Text("No frames yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(frameStore.frames) { frame in
                VStack(alignment: .leading, spacing: 6) {
                    Text("Frame \(frame.frameNumber)")
                        .font(.headline)
                    Text(Self.displayFormatter.string(from: frame.timestamp))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let latitude = frame.latitude, let longitude = frame.longitude {
                        Text("Location \(latitude), \(longitude)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Frames")
        .toolbar {
            Button("New Frame") {
                showingNewFrame = true
            }
        }
        .sheet(isPresented: $showingNewFrame) {
            NewFrameView(roll: roll)
                .environmentObject(frameStore)
        }
        .onAppear {
            frameStore.loadFrames(for: roll.id)
        }
    }
}

import SwiftUI

struct FrameListView: View {
    @EnvironmentObject private var frameStore: FrameStore
    let roll: Roll

    @State private var showingNewFrame = false
    @State private var showingShare = false
    @State private var shareURL: URL?
    @State private var errorMessage: String?
    private let exporter = RollExporter()

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
                    if let shutter = frame.shutter, let aperture = frame.aperture {
                        Text("\(shutter) • \(aperture)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let shutter = frame.shutter {
                        Text(shutter)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let aperture = frame.aperture {
                        Text(aperture)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let focalLength = frame.focalLength {
                        Text("Focal length \(focalLength)mm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let exposureComp = frame.exposureComp, !exposureComp.isEmpty {
                        Text("Exposure comp \(exposureComp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let latitude = frame.latitude, let longitude = frame.longitude {
                        Text("Location \(latitude), \(longitude)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !frame.keywords.isEmpty {
                        Text("Keywords: \(frame.keywords.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let transcript = frame.voiceNoteRaw, !transcript.isEmpty {
                        Text(transcript)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
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
            Menu("Export") {
                Button("Export JSON") {
                    export(format: .json)
                }
                Button("Export CSV") {
                    export(format: .csv)
                }
            }
        }
        .sheet(isPresented: $showingNewFrame) {
            NewFrameView(roll: roll)
                .environmentObject(frameStore)
        }
        .sheet(isPresented: $showingShare) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
        .alert("Export Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            frameStore.loadFrames(for: roll.id)
        }
        .onChange(of: frameStore.errorMessage) { _, newValue in
            if let newValue {
                errorMessage = newValue
            }
        }
    }

    private func export(format: RollExportFormat) {
        do {
            shareURL = try exporter.exportRoll(rollId: roll.id, format: format)
            showingShare = true
        } catch {
            errorMessage = "\(error)"
        }
    }
}

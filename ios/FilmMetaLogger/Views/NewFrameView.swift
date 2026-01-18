import SwiftUI
import CoreLocation

struct NewFrameView: View {
    @EnvironmentObject private var frameStore: FrameStore
    @Environment(\.dismiss) private var dismiss

    let roll: Roll

    @StateObject private var locationProvider = LocationProvider()
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var speechTranscriber = SpeechTranscriber()
    @State private var frameNumber: Int = 1
    @State private var timestamp = Date()
    @State private var shutter = ""
    @State private var aperture = ""
    @State private var focalLengthText = ""
    @State private var exposureComp = ""
    @State private var keywordsText = ""
    @State private var transcriptRaw = ""
    @State private var isTranscribing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Frame") {
                    Text("Frame \(frameNumber)")
                        .font(.headline)
                }

                Section("Timestamp") {
                    Text(Self.displayFormatter.string(from: timestamp))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Use Current Time") {
                        timestamp = Date()
                    }
                }

                Section("Exposure") {
                    TextField("Shutter (e.g. 1/125)", text: $shutter)
                    TextField("Aperture (e.g. f/2.8)", text: $aperture)
                    TextField("Focal length (mm)", text: $focalLengthText)
                        .keyboardType(.numberPad)
                    TextField("Exposure comp (e.g. +1)", text: $exposureComp)
                }

                Section("Keywords") {
                    TextField("Comma-separated keywords", text: $keywordsText)
                }

                Section("Location") {
                    Text(locationStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let location = locationProvider.lastLocation {
                        Text("Lat \(location.coordinate.latitude), Lon \(location.coordinate.longitude)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Refresh Location") {
                        locationProvider.requestLocation()
                    }
                }

                Section("Voice Note") {
                    if audioRecorder.isRecording {
                        Text("Recording...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if isTranscribing {
                        Text("Transcribing...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    TextEditor(text: $transcriptRaw)
                        .frame(minHeight: 120)

                    Button(audioRecorder.isRecording ? "Stop Recording" : "Record Voice Note") {
                        toggleRecording()
                    }
                }
            }
            .navigationTitle("New Frame")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFrame()
                    }
                }
            }
            .onAppear {
                frameNumber = frameStore.nextFrameNumber(for: roll.id)
                timestamp = Date()
                locationProvider.requestAuthorization()
                locationProvider.requestLocation()
                audioRecorder.requestPermission { _ in }
                speechTranscriber.requestAuthorization { _ in }
            }
            .onChange(of: locationProvider.lastError) { _, newValue in
                if let newValue {
                    errorMessage = newValue.localizedDescription
                }
            }
            .onChange(of: audioRecorder.lastError) { _, newValue in
                if let newValue {
                    errorMessage = newValue.localizedDescription
                }
            }
            .onChange(of: speechTranscriber.lastError) { _, newValue in
                if let newValue {
                    errorMessage = newValue.localizedDescription
                }
            }
            .alert("Frame Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var locationStatusText: String {
        switch locationProvider.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location authorized."
        case .notDetermined:
            return "Location permission not determined."
        case .restricted, .denied:
            return "Location permission denied."
        @unknown default:
            return "Location permission unknown."
        }
    }

    private func saveFrame() {
        let trimmedTranscript = transcriptRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedShutter = shutter.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAperture = aperture.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExposureComp = exposureComp.trimmingCharacters(in: .whitespacesAndNewlines)
        let focalLengthValue = Int(focalLengthText.trimmingCharacters(in: .whitespacesAndNewlines))
        let keywords = keywordsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        frameStore.createFrame(
            rollId: roll.id,
            frameNumber: frameNumber,
            timestamp: timestamp,
            location: locationProvider.lastLocation,
            shutter: trimmedShutter.isEmpty ? nil : trimmedShutter,
            aperture: trimmedAperture.isEmpty ? nil : trimmedAperture,
            focalLength: focalLengthValue,
            exposureComp: trimmedExposureComp.isEmpty ? nil : trimmedExposureComp,
            keywords: keywords,
            voiceNoteRaw: trimmedTranscript.isEmpty ? nil : trimmedTranscript,
            voiceNoteParsed: nil
        )
        dismiss()
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            transcribeRecording()
        } else {
            audioRecorder.startRecording()
        }
    }

    private func transcribeRecording() {
        guard let url = audioRecorder.recordingURL else { return }
        isTranscribing = true
        speechTranscriber.transcribeAudio(at: url) { transcript in
            isTranscribing = false
            if let transcript {
                transcriptRaw = transcript
            }
        }
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

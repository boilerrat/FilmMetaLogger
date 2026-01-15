import Foundation
import CoreLocation

final class FrameStore: ObservableObject {
    @Published private(set) var frames: [Frame] = []
    @Published var errorMessage: String?

    private let database: SQLiteDatabase?

    init() {
        do {
            database = try SQLiteDatabase.defaultDatabase()
        } catch {
            database = nil
            errorMessage = "Database unavailable: \(error)"
        }
    }

    func loadFrames(for rollId: String) {
        guard let database else { return }
        do {
            frames = try database.fetchFrames(rollId: rollId)
        } catch {
            errorMessage = "Failed to load frames: \(error)"
        }
    }

    func nextFrameNumber(for rollId: String) -> Int {
        guard let database else { return 1 }
        do {
            return try database.nextFrameNumber(rollId: rollId)
        } catch {
            errorMessage = "Failed to get next frame number: \(error)"
            return 1
        }
    }

    func createFrame(
        rollId: String,
        frameNumber: Int,
        timestamp: Date,
        location: CLLocation?,
        voiceNoteRaw: String?,
        voiceNoteParsed: String?
    ) {
        guard let database else { return }
        let frame = Frame(
            rollId: rollId,
            frameNumber: frameNumber,
            timestamp: timestamp,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            voiceNoteRaw: voiceNoteRaw,
            voiceNoteParsed: voiceNoteParsed
        )
        do {
            try database.insertFrame(frame)
            loadFrames(for: rollId)
        } catch {
            errorMessage = "Failed to create frame: \(error)"
        }
    }
}

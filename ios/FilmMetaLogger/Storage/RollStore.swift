import Foundation

final class RollStore: ObservableObject {
    @Published private(set) var rolls: [Roll] = []
    @Published var errorMessage: String?

    private let database: SQLiteDatabase?

    init() {
        do {
            database = try SQLiteDatabase.defaultDatabase()
        } catch {
            database = nil
            errorMessage = "Database unavailable: \(error)"
        }
        loadRolls()
    }

    func loadRolls() {
        guard let database else { return }
        do {
            rolls = try database.fetchRolls()
        } catch {
            errorMessage = "Failed to load rolls: \(error)"
        }
    }

    func createRoll(
        filmStock: String,
        iso: Int,
        camera: String,
        lens: String,
        notes: String?
    ) {
        guard let database else { return }
        let roll = Roll(
            id: UUID().uuidString,
            filmStock: filmStock,
            iso: iso,
            camera: camera,
            lens: lens,
            notes: notes,
            startTime: Date(),
            endTime: nil
        )
        do {
            try database.insertRoll(roll)
            loadRolls()
        } catch {
            errorMessage = "Failed to create roll: \(error)"
        }
    }

    func endRoll(_ roll: Roll) {
        guard let database else { return }
        do {
            try database.endRoll(rollId: roll.id, endTime: Date())
            loadRolls()
        } catch {
            errorMessage = "Failed to end roll: \(error)"
        }
    }
}

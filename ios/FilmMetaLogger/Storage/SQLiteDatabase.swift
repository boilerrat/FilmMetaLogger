import Foundation
import SQLite3

final class SQLiteDatabase {
    struct DatabaseError: Error {
        let message: String
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private var db: OpaquePointer?

    static func defaultDatabase() throws -> SQLiteDatabase {
        let directory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let url = directory.appendingPathComponent("film_meta_logger.sqlite")
        return try SQLiteDatabase(path: url.path)
    }

    init(path: String) throws {
        if sqlite3_open(path, &db) != SQLITE_OK {
            throw DatabaseError(message: "Unable to open database.")
        }
        try createTables()
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    private func createTables() throws {
        let createRolls = """
        CREATE TABLE IF NOT EXISTS rolls (
          roll_id TEXT PRIMARY KEY,
          film_stock TEXT NOT NULL,
          iso INTEGER NOT NULL,
          camera TEXT NOT NULL,
          lens TEXT NOT NULL,
          notes TEXT,
          start_time TEXT NOT NULL,
          end_time TEXT
        );
        """

        let createFrames = """
        CREATE TABLE IF NOT EXISTS frames (
          roll_id TEXT NOT NULL,
          frame_number INTEGER NOT NULL,
          shutter TEXT,
          aperture TEXT,
          focal_length INTEGER,
          exposure_comp TEXT,
          timestamp TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          weather_summary TEXT,
          temperature_c REAL,
          voice_note_raw TEXT,
          voice_note_parsed TEXT,
          keywords TEXT,
          PRIMARY KEY (roll_id, frame_number),
          FOREIGN KEY (roll_id) REFERENCES rolls(roll_id)
        );
        """

        try execute(sql: createRolls)
        try execute(sql: createFrames)
    }

    private func execute(sql: String) throws {
        var errorMessage: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = errorMessage.flatMap { String(cString: $0) } ?? "Unknown SQLite error."
            sqlite3_free(errorMessage)
            throw DatabaseError(message: message)
        }
    }

    func insertRoll(_ roll: Roll) throws {
        let sql = """
        INSERT INTO rolls (
          roll_id, film_stock, iso, camera, lens, notes, start_time, end_time
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        bindText(roll.id, to: statement, index: 1)
        bindText(roll.filmStock, to: statement, index: 2)
        bindInt(roll.iso, to: statement, index: 3)
        bindText(roll.camera, to: statement, index: 4)
        bindText(roll.lens, to: statement, index: 5)
        if let notes = roll.notes, !notes.isEmpty {
            bindText(notes, to: statement, index: 6)
        } else {
            bindNull(to: statement, index: 6)
        }
        bindText(Self.dateFormatter.string(from: roll.startTime), to: statement, index: 7)
        if let endTime = roll.endTime {
            bindText(Self.dateFormatter.string(from: endTime), to: statement, index: 8)
        } else {
            bindNull(to: statement, index: 8)
        }

        if sqlite3_step(statement) != SQLITE_DONE {
            throw DatabaseError(message: "Failed to insert roll.")
        }
    }

    func endRoll(rollId: String, endTime: Date) throws {
        let sql = "UPDATE rolls SET end_time = ? WHERE roll_id = ?;"
        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        bindText(Self.dateFormatter.string(from: endTime), to: statement, index: 1)
        bindText(rollId, to: statement, index: 2)

        if sqlite3_step(statement) != SQLITE_DONE {
            throw DatabaseError(message: "Failed to end roll.")
        }
    }

    func fetchRolls() throws -> [Roll] {
        let sql = """
        SELECT roll_id, film_stock, iso, camera, lens, notes, start_time, end_time
        FROM rolls
        ORDER BY start_time DESC;
        """
        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        var rolls: [Roll] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let rollId = columnText(statement, index: 0) ?? ""
            let filmStock = columnText(statement, index: 1) ?? ""
            let iso = Int(sqlite3_column_int(statement, 2))
            let camera = columnText(statement, index: 3) ?? ""
            let lens = columnText(statement, index: 4) ?? ""
            let notes = columnText(statement, index: 5)
            let startString = columnText(statement, index: 6) ?? ""
            let endString = columnText(statement, index: 7)

            let startTime = Self.dateFormatter.date(from: startString) ?? Date()
            let endTime = endString.flatMap { Self.dateFormatter.date(from: $0) }

            rolls.append(
                Roll(
                    id: rollId,
                    filmStock: filmStock,
                    iso: iso,
                    camera: camera,
                    lens: lens,
                    notes: notes,
                    startTime: startTime,
                    endTime: endTime
                )
            )
        }
        return rolls
    }

    func fetchRoll(rollId: String) throws -> Roll? {
        let sql = """
        SELECT roll_id, film_stock, iso, camera, lens, notes, start_time, end_time
        FROM rolls
        WHERE roll_id = ?;
        """
        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        bindText(rollId, to: statement, index: 1)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }

        let rollId = columnText(statement, index: 0) ?? ""
        let filmStock = columnText(statement, index: 1) ?? ""
        let iso = Int(sqlite3_column_int(statement, 2))
        let camera = columnText(statement, index: 3) ?? ""
        let lens = columnText(statement, index: 4) ?? ""
        let notes = columnText(statement, index: 5)
        let startString = columnText(statement, index: 6) ?? ""
        let endString = columnText(statement, index: 7)

        let startTime = Self.dateFormatter.date(from: startString) ?? Date()
        let endTime = endString.flatMap { Self.dateFormatter.date(from: $0) }

        return Roll(
            id: rollId,
            filmStock: filmStock,
            iso: iso,
            camera: camera,
            lens: lens,
            notes: notes,
            startTime: startTime,
            endTime: endTime
        )
    }

    func insertFrame(_ frame: Frame) throws {
        let sql = """
        INSERT INTO frames (
          roll_id, frame_number, shutter, aperture, focal_length, exposure_comp,
          timestamp, latitude, longitude, weather_summary, temperature_c,
          voice_note_raw, voice_note_parsed, keywords
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        bindText(frame.rollId, to: statement, index: 1)
        bindInt(frame.frameNumber, to: statement, index: 2)
        bindTextOrNull(frame.shutter, to: statement, index: 3)
        bindTextOrNull(frame.aperture, to: statement, index: 4)
        bindIntOrNull(frame.focalLength, to: statement, index: 5)
        bindTextOrNull(frame.exposureComp, to: statement, index: 6)
        bindText(Self.dateFormatter.string(from: frame.timestamp), to: statement, index: 7)
        bindDoubleOrNull(frame.latitude, to: statement, index: 8)
        bindDoubleOrNull(frame.longitude, to: statement, index: 9)
        bindTextOrNull(frame.weatherSummary, to: statement, index: 10)
        bindDoubleOrNull(frame.temperatureC, to: statement, index: 11)
        bindTextOrNull(frame.voiceNoteRaw, to: statement, index: 12)
        bindTextOrNull(frame.voiceNoteParsed, to: statement, index: 13)
        let keywords = frame.keywords.isEmpty ? nil : frame.keywords.joined(separator: ",")
        bindTextOrNull(keywords, to: statement, index: 14)

        if sqlite3_step(statement) != SQLITE_DONE {
            throw DatabaseError(message: "Failed to insert frame.")
        }
    }

    func fetchFrames(rollId: String) throws -> [Frame] {
        let sql = """
        SELECT roll_id, frame_number, shutter, aperture, focal_length, exposure_comp,
               timestamp, latitude, longitude, weather_summary, temperature_c,
               voice_note_raw, voice_note_parsed, keywords
        FROM frames
        WHERE roll_id = ?
        ORDER BY frame_number ASC;
        """
        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        bindText(rollId, to: statement, index: 1)

        var frames: [Frame] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let rollId = columnText(statement, index: 0) ?? ""
            let frameNumber = Int(sqlite3_column_int(statement, 1))
            let shutter = columnText(statement, index: 2)
            let aperture = columnText(statement, index: 3)
            let focalLength = columnInt(statement, index: 4)
            let exposureComp = columnText(statement, index: 5)
            let timestampString = columnText(statement, index: 6) ?? ""
            let latitude = columnDouble(statement, index: 7)
            let longitude = columnDouble(statement, index: 8)
            let weatherSummary = columnText(statement, index: 9)
            let temperatureC = columnDouble(statement, index: 10)
            let voiceNoteRaw = columnText(statement, index: 11)
            let voiceNoteParsed = columnText(statement, index: 12)
            let keywordsString = columnText(statement, index: 13) ?? ""

            let timestamp = Self.dateFormatter.date(from: timestampString) ?? Date()
            let keywords = keywordsString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            frames.append(
                Frame(
                    rollId: rollId,
                    frameNumber: frameNumber,
                    shutter: shutter,
                    aperture: aperture,
                    focalLength: focalLength,
                    exposureComp: exposureComp,
                    timestamp: timestamp,
                    latitude: latitude,
                    longitude: longitude,
                    weatherSummary: weatherSummary,
                    temperatureC: temperatureC,
                    voiceNoteRaw: voiceNoteRaw,
                    voiceNoteParsed: voiceNoteParsed,
                    keywords: keywords
                )
            )
        }
        return frames
    }

    func nextFrameNumber(rollId: String) throws -> Int {
        let sql = "SELECT MAX(frame_number) FROM frames WHERE roll_id = ?;"
        let statement = try prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        bindText(rollId, to: statement, index: 1)

        if sqlite3_step(statement) == SQLITE_ROW {
            let maxValue = sqlite3_column_int(statement, 0)
            return Int(maxValue) + 1
        }
        return 1
    }

    private func prepare(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw DatabaseError(message: "Failed to prepare statement.")
        }
        return statement
    }

    private func bindText(_ value: String, to statement: OpaquePointer?, index: Int32) {
        sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
    }

    private func bindInt(_ value: Int, to statement: OpaquePointer?, index: Int32) {
        sqlite3_bind_int(statement, index, Int32(value))
    }

    private func bindNull(to statement: OpaquePointer?, index: Int32) {
        sqlite3_bind_null(statement, index)
    }

    private func bindTextOrNull(_ value: String?, to statement: OpaquePointer?, index: Int32) {
        if let value, !value.isEmpty {
            bindText(value, to: statement, index: index)
        } else {
            bindNull(to: statement, index: index)
        }
    }

    private func bindIntOrNull(_ value: Int?, to statement: OpaquePointer?, index: Int32) {
        if let value {
            bindInt(value, to: statement, index: index)
        } else {
            bindNull(to: statement, index: index)
        }
    }

    private func bindDoubleOrNull(_ value: Double?, to statement: OpaquePointer?, index: Int32) {
        if let value {
            sqlite3_bind_double(statement, index, value)
        } else {
            bindNull(to: statement, index: index)
        }
    }

    private func columnText(_ statement: OpaquePointer?, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: cString)
    }

    private func columnInt(_ statement: OpaquePointer?, index: Int32) -> Int? {
        if sqlite3_column_type(statement, index) == SQLITE_NULL {
            return nil
        }
        return Int(sqlite3_column_int(statement, index))
    }

    private func columnDouble(_ statement: OpaquePointer?, index: Int32) -> Double? {
        if sqlite3_column_type(statement, index) == SQLITE_NULL {
            return nil
        }
        return sqlite3_column_double(statement, index)
    }
}

import Foundation

enum RollExportFormat {
    case json
    case csv
}

final class RollExporter {
    struct ExportError: Error {
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

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    private let database: SQLiteDatabase?

    init() {
        database = try? SQLiteDatabase.defaultDatabase()
    }

    func exportRoll(rollId: String, format: RollExportFormat) throws -> URL {
        guard let database else {
            throw ExportError(message: "Database unavailable.")
        }
        guard let roll = try database.fetchRoll(rollId: rollId) else {
            throw ExportError(message: "Roll not found.")
        }
        let frames = try database.fetchFrames(rollId: rollId)

        switch format {
        case .json:
            return try exportJSON(roll: roll, frames: frames)
        case .csv:
            return try exportCSV(roll: roll, frames: frames)
        }
    }

    private func exportJSON(roll: Roll, frames: [Frame]) throws -> URL {
        let exportRoll = ExportRoll(
            roll: ExportRollData(
                rollId: roll.id,
                filmStock: roll.filmStock,
                iso: roll.iso,
                camera: roll.camera,
                lens: roll.lens,
                notes: roll.notes,
                startTime: Self.dateFormatter.string(from: roll.startTime),
                endTime: roll.endTime.map { Self.dateFormatter.string(from: $0) }
            ),
            frames: frames.map { frame in
                ExportFrameData(
                    rollId: frame.rollId,
                    frameNumber: frame.frameNumber,
                    shutter: frame.shutter,
                    aperture: frame.aperture,
                    focalLength: frame.focalLength,
                    exposureComp: frame.exposureComp,
                    timestamp: Self.dateFormatter.string(from: frame.timestamp),
                    latitude: frame.latitude,
                    longitude: frame.longitude,
                    weatherSummary: frame.weatherSummary,
                    temperatureC: frame.temperatureC,
                    voiceNoteRaw: frame.voiceNoteRaw,
                    voiceNoteParsed: frame.voiceNoteParsed,
                    keywords: frame.keywords
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportRoll)

        return try writeToDocuments(data: data, baseName: "roll-\(roll.id)", extension: "json")
    }

    private func exportCSV(roll: Roll, frames: [Frame]) throws -> URL {
        let header = [
            "roll_id",
            "film_stock",
            "iso",
            "camera",
            "lens",
            "notes",
            "start_time",
            "end_time",
            "frame_number",
            "shutter",
            "aperture",
            "focal_length",
            "exposure_comp",
            "timestamp",
            "latitude",
            "longitude",
            "weather_summary",
            "temperature_c",
            "voice_note_raw",
            "voice_note_parsed",
            "keywords"
        ]

        var lines: [String] = [header.joined(separator: ",")]
        for frame in frames {
            let fields: [String?] = [
                roll.id,
                roll.filmStock,
                String(roll.iso),
                roll.camera,
                roll.lens,
                roll.notes,
                Self.dateFormatter.string(from: roll.startTime),
                roll.endTime.map { Self.dateFormatter.string(from: $0) },
                String(frame.frameNumber),
                frame.shutter,
                frame.aperture,
                frame.focalLength.map(String.init),
                frame.exposureComp,
                Self.dateFormatter.string(from: frame.timestamp),
                frame.latitude.map(String.init),
                frame.longitude.map(String.init),
                frame.weatherSummary,
                frame.temperatureC.map(String.init),
                frame.voiceNoteRaw,
                frame.voiceNoteParsed,
                frame.keywords.isEmpty ? nil : frame.keywords.joined(separator: ",")
            ]
            lines.append(fields.map { csvEscaped($0 ?? "") }.joined(separator: ","))
        }

        let content = lines.joined(separator: "\n")
        guard let data = content.data(using: .utf8) else {
            throw ExportError(message: "Failed to encode CSV.")
        }

        return try writeToDocuments(data: data, baseName: "roll-\(roll.id)", extension: "csv")
    }

    private func writeToDocuments(data: Data, baseName: String, extension: String) throws -> URL {
        let directory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let filename = uniqueFilename(
            directory: directory,
            baseName: baseName,
            extension: `extension`
        )
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func uniqueFilename(directory: URL, baseName: String, extension: String) -> String {
        let timestamp = Self.filenameFormatter.string(from: Date())
        let baseFilename = "\(baseName)-\(timestamp)"
        let fileManager = FileManager.default
        var candidate = "\(baseFilename).\(extension)"
        var counter = 1

        while fileManager.fileExists(atPath: directory.appendingPathComponent(candidate).path) {
            counter += 1
            candidate = "\(baseFilename)-\(counter).\(extension)"
        }

        return candidate
    }
}

private struct ExportRoll: Codable {
    let roll: ExportRollData
    let frames: [ExportFrameData]
}

private struct ExportRollData: Codable {
    let rollId: String
    let filmStock: String
    let iso: Int
    let camera: String
    let lens: String
    let notes: String?
    let startTime: String
    let endTime: String?
}

private struct ExportFrameData: Codable {
    let rollId: String
    let frameNumber: Int
    let shutter: String?
    let aperture: String?
    let focalLength: Int?
    let exposureComp: String?
    let timestamp: String
    let latitude: Double?
    let longitude: Double?
    let weatherSummary: String?
    let temperatureC: Double?
    let voiceNoteRaw: String?
    let voiceNoteParsed: String?
    let keywords: [String]
}

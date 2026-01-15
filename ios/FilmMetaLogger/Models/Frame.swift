import Foundation

struct Frame: Identifiable, Hashable {
    let rollId: String
    let frameNumber: Int
    var shutter: String?
    var aperture: String?
    var focalLength: Int?
    var exposureComp: String?
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var weatherSummary: String?
    var temperatureC: Double?
    var voiceNoteRaw: String?
    var voiceNoteParsed: String?
    var keywords: [String]

    var id: String {
        "\(rollId)-\(frameNumber)"
    }

    init(
        rollId: String,
        frameNumber: Int,
        shutter: String? = nil,
        aperture: String? = nil,
        focalLength: Int? = nil,
        exposureComp: String? = nil,
        timestamp: Date,
        latitude: Double? = nil,
        longitude: Double? = nil,
        weatherSummary: String? = nil,
        temperatureC: Double? = nil,
        voiceNoteRaw: String? = nil,
        voiceNoteParsed: String? = nil,
        keywords: [String] = []
    ) {
        self.rollId = rollId
        self.frameNumber = frameNumber
        self.shutter = shutter
        self.aperture = aperture
        self.focalLength = focalLength
        self.exposureComp = exposureComp
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.weatherSummary = weatherSummary
        self.temperatureC = temperatureC
        self.voiceNoteRaw = voiceNoteRaw
        self.voiceNoteParsed = voiceNoteParsed
        self.keywords = keywords
    }
}

import Foundation

struct Roll: Identifiable, Hashable {
    let id: String
    var filmStock: String
    var iso: Int
    var camera: String
    var lens: String
    var notes: String?
    var startTime: Date
    var endTime: Date?

    var isActive: Bool {
        endTime == nil
    }
}

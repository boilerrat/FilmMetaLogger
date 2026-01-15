import SwiftUI

@main
struct FilmMetaLoggerApp: App {
    @StateObject private var rollStore = RollStore()
    @StateObject private var frameStore = FrameStore()

    var body: some Scene {
        WindowGroup {
            RollListView()
                .environmentObject(rollStore)
                .environmentObject(frameStore)
        }
    }
}

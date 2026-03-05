import SwiftUI

@main
struct SlimNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .background(WindowSetup())
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 360, height: 540)
    }
}

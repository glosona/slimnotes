import Foundation
import SwiftUI
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedId: UUID?

    private var saveURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("SlimNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("notes.json")
    }

    init() {
        load()
        if notes.isEmpty { addNote() }
    }

    var selectedNote: Binding<Note>? {
        guard let id = selectedId,
              notes.contains(where: { $0.id == id }) else { return nil }
        return Binding(
            get: {
                guard let i = self.notes.firstIndex(where: { $0.id == id }) else { return Note() }
                return self.notes[i]
            },
            set: { newValue in
                guard let i = self.notes.firstIndex(where: { $0.id == id }) else { return }
                self.notes[i] = newValue
                self.notes[i].updatedAt = Date()
                self.scheduleSave()
            }
        )
    }

    private var saveTask: DispatchWorkItem?

    private func scheduleSave() {
        saveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.save() }
        saveTask = task
        DispatchQueue.main.async(execute: task)
    }

    func addNote() {
        let n = Note()
        notes.insert(n, at: 0)
        selectedId = n.id
        save()
    }

    func deleteNote(_ id: UUID) {
        notes.removeAll { $0.id == id }
        selectedId = notes.first?.id
        save()
    }

    func save() {
        try? JSONEncoder().encode(notes).write(to: saveURL)
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Note].self, from: data) else { return }
        notes = decoded
        selectedId = decoded.first?.id
    }

    func exportToAppleNotes(_ note: Note) {
        let safeTitle = note.displayTitle
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let safeBody = note.body
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let script = """
        tell application "Notes"
            activate
            set newNote to make new note at folder "Notes" with properties {name:"\(safeTitle)", body:"\(safeBody)"}
        end tell
        """
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
    }
}

import SwiftUI

struct NoteEditorView: View {
    @Binding var note: Note
    @EnvironmentObject var store: NoteStore
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            titleField
            Divider().opacity(0.15)
            bodyContent
            Divider().opacity(0.15)
            bottomToolbar
        }
    }

    private var titleField: some View {
        TextField("제목", text: $note.title)
            .font(Theme.Font.editorTitle)
            .textFieldStyle(.plain)
            .padding(.horizontal, Theme.Spacing.editorH)
            .padding(.top, Theme.Spacing.editorTop)
            .padding(.bottom, Theme.Spacing.editorBottom)
            .focused($titleFocused)
    }

    @ViewBuilder
    private var bodyContent: some View {
        LiveMarkdownEditor(text: $note.body)
            .transition(.opacity)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            wordCount
            Spacer()
            exportButton
        }
        .padding(.horizontal, Theme.Spacing.toolbarH)
        .padding(.vertical, Theme.Spacing.toolbarV)
    }

    private var wordCount: some View {
        let words = note.body.count
        return Text("\(words) words")
            .font(Theme.Font.wordCount)
            .foregroundStyle(.quaternary)
    }

    private var exportButton: some View {
        Button { store.exportToAppleNotes(note) } label: {
            Label("내보내기", systemImage: "square.and.arrow.up")
                .font(Theme.Font.toolbar)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

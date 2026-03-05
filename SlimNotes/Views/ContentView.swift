import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NoteStore
    @State private var showSidebar = true
    @State private var bgOpacity: Double = Theme.defaultBgOpacity

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                TitleBarView(showSidebar: $showSidebar, bgOpacity: $bgOpacity)
                Divider().opacity(Theme.dividerOpacity)

                HStack(spacing: 0) {
                    if showSidebar {
                        SidebarView()
                            .frame(width: Theme.Spacing.sidebarWidth)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        Divider().opacity(Theme.dividerOpacity)
                    }

                    editorOrPlaceholder
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.window))
        .animation(.spring(duration: 0.25), value: showSidebar)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.window)
            .fill(Color(nsColor: .windowBackgroundColor).opacity(0.1))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.window))
            .opacity(bgOpacity)
    }

    @ViewBuilder
    private var editorOrPlaceholder: some View {
        if let binding = store.selectedNote {
            NoteEditorView(note: binding)
        } else {
            EmptyNoteView()
        }
    }
}

private struct EmptyNoteView: View {
    var body: some View {
        VStack {
            Image(systemName: "note.text")
                .font(Theme.Font.emptyIcon)
                .foregroundStyle(.tertiary)
            Text("노트를 선택하세요")
                .font(Theme.Font.emptyState)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

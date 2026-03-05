import SwiftUI

struct NoteRowView: View {
    @EnvironmentObject var store: NoteStore
    let note: Note

    private var isSelected: Bool { store.selectedId == note.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(note.displayTitle)
                .font(Theme.Font.rowTitle(isSelected))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)

            HStack {
                Text(note.preview.isEmpty ? "내용 없음" : note.preview)
                    .font(Theme.Font.rowPreview)
                    .lineLimit(1)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(note.formattedDate)
                    .font(Theme.Font.rowDate)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.horizontal, Theme.Spacing.rowH)
        .padding(.vertical, Theme.Spacing.rowV)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onTapGesture { store.selectedId = note.id }
        .contextMenu {
            Button("iOS Notes로 내보내기") { store.exportToAppleNotes(note) }
            Divider()
            Button("삭제", role: .destructive) { store.deleteNote(note.id) }
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.row)
            .fill(isSelected ? Color.accentColor.opacity(Theme.selectedRowOpacity) : Color.clear)
            .padding(.horizontal, 4)
    }
}

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: NoteStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.notes) { note in
                    NoteRowView(note: note)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

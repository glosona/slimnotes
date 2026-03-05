import SwiftUI
import AppKit

struct TitleBarView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var showSidebar: Bool
    @Binding var bgOpacity: Double

    @State private var isAlwaysOnTop = false
    
    var body: some View {
        HStack(spacing: 8) {
            windowButtons
            Spacer()
            opacityControl
            alwaysOnTopButton
            sidebarToggle
            newNoteButton
        }
        .padding(.horizontal, Theme.Spacing.titleBarH)
        .padding(.vertical, Theme.Spacing.titleBarV)
    }

    private var windowButtons: some View {
        HStack(spacing: 6) {
            Button { NSApp.terminate(nil) } label: {
                Circle()
                    .fill(Theme.WindowButton.close)
                    .frame(width: Theme.WindowButton.size, height: Theme.WindowButton.size)
            }
            .buttonStyle(.plain)

            Button { NSApp.windows.first?.miniaturize(nil) } label: {
                Circle()
                    .fill(Theme.WindowButton.minimise)
                    .frame(width: Theme.WindowButton.size, height: Theme.WindowButton.size)
            }
            .buttonStyle(.plain)
        }
    }

    private var opacityControl: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.lefthalf.filled")
                .font(Theme.Font.controlIcon(10))
                .foregroundStyle(.tertiary)
            Slider(value: $bgOpacity, in: Theme.backgroundOpacityRange)
                .frame(width: 44)
                .tint(.secondary)
        }
    }
    
    private var alwaysOnTopButton: some View {
        Button {
            isAlwaysOnTop.toggle()
            updateWindowLevel()
        } label: {
            Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                .font(Theme.Font.controlIcon(12))
                .foregroundStyle(isAlwaysOnTop ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }


    private var sidebarToggle: some View {
        Button { withAnimation { showSidebar.toggle() } } label: {
            Image(systemName: showSidebar ? "sidebar.left" : "sidebar.right")
                .font(Theme.Font.controlIcon(12))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var newNoteButton: some View {
        Button { store.addNote() } label: {
            Image(systemName: "square.and.pencil")
                .font(Theme.Font.controlIcon(12))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
    
    private func updateWindowLevel() {
        guard let window = NSApp.keyWindow else { return }

        if isAlwaysOnTop {
            window.level = .floating
        } else {
            window.level = .normal
        }

        window.makeKeyAndOrderFront(nil)
    }
}

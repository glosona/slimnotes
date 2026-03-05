import SwiftUI

enum Theme {
    // MARK: - Corner Radius
    enum Radius {
        static let window: CGFloat = 14
        static let row: CGFloat = 6
    }

    // MARK: - Spacing & Padding
    enum Spacing {
        static let titleBarH: CGFloat = 12
        static let titleBarV: CGFloat = 7
        static let rowH: CGFloat = 10
        static let rowV: CGFloat = 7
        static let editorH: CGFloat = 14
        static let editorTop: CGFloat = 10
        static let editorBottom: CGFloat = 7
        static let toolbarH: CGFloat = 12
        static let toolbarV: CGFloat = 6
        static let sidebarWidth: CGFloat = 130
    }

    // MARK: - Font
    enum Font {
        static let titleBar = SwiftUI.Font.system(size: 11, weight: .medium, design: .rounded)
        static let editorTitle = SwiftUI.Font.system(size: 14, weight: .semibold)
        static let editorBody = SwiftUI.Font.system(size: 13)
        static let rowTitle = { (selected: Bool) in
            SwiftUI.Font.system(size: 12, weight: selected ? .semibold : .regular)
        }
        static let rowPreview = SwiftUI.Font.system(size: 10)
        static let rowDate = SwiftUI.Font.system(size: 9)
        static let toolbar = SwiftUI.Font.system(size: 11)
        static let wordCount = SwiftUI.Font.system(size: 10, design: .monospaced)
        static let emptyState = SwiftUI.Font.system(size: 13)
        static let emptyIcon = SwiftUI.Font.system(size: 28)
        static let controlIcon = { (size: CGFloat) in SwiftUI.Font.system(size: size) }
    }

    // MARK: - Window Buttons
    enum WindowButton {
        static let size: CGFloat = 11
        static let close = Color.red.opacity(0.75)
        static let minimise = Color.yellow.opacity(0.75)
    }

    // MARK: - Misc
    static let dividerOpacity: Double = 0.2
    static let selectedRowOpacity: Double = 0.18
    static let backgroundOpacityRange: ClosedRange<Double> = 0.25...1.0
    static let defaultBgOpacity: Double = 0.88
}

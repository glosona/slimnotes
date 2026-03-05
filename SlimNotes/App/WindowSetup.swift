import SwiftUI

struct WindowSetup: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            
            w.styleMask = [
                            .borderless,
                            .resizable,
                            .miniaturizable
                        ]
            w.isMovableByWindowBackground = true
            
            w.level = .normal
            w.collectionBehavior = []

            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = true

        }
        return v
    }

    func updateNSView(_ v: NSView, context: Context) {}
}

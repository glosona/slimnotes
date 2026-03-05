import SwiftUI
import WebKit

struct MarkdownPreview: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences = prefs
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.setValue(false, forKey: "drawsBackground")
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        wv.loadHTMLString(MarkdownRenderer.toHTML(markdown), baseURL: nil)
    }
}

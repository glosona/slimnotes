import Foundation

enum MarkdownRenderer {
    static func toHTML(_ md: String) -> String {
        let body = mdToHTML(md)
        return """
        <!DOCTYPE html><html><head><meta charset="UTF-8">
        <style>\(css)</style>
        </head><body>\(body)</body></html>
        """
    }
}

// MARK: - CSS
// light-dark() requires macOS 15+, so we use prefers-color-scheme media queries
// to support macOS 12+.

private let css = """
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
    font-family: -apple-system, sans-serif;
    font-size: 13px;
    line-height: 1.75;
    padding: 10px 14px 20px;
    color: #1a1a1a;
    background: transparent;
    word-break: break-word;
}
h1 { font-size: 19px; font-weight: 700; margin: 8px 0 6px; }
h2 {
    font-size: 15px; font-weight: 600; margin: 8px 0 5px;
    border-bottom: 1px solid rgba(0,0,0,.1); padding-bottom: 3px;
}
h3 { font-size: 13px; font-weight: 600; margin: 6px 0 4px; color: #555; }
p { margin-bottom: 8px; }
ul, ol { padding-left: 18px; margin-bottom: 8px; }
li { margin-bottom: 2px; }
blockquote {
    border-left: 2px solid #d0a070;
    padding: 4px 10px; margin: 6px 0;
    color: #666; font-style: italic;
    background: rgba(0,0,0,.03);
    border-radius: 0 4px 4px 0;
}
code {
    font-family: 'SF Mono', Menlo, monospace;
    font-size: 11.5px;
    background: rgba(0,0,0,.07);
    padding: 1px 4px; border-radius: 3px;
}
pre {
    background: rgba(0,0,0,.05);
    padding: 10px 12px; border-radius: 6px; margin: 6px 0;
    overflow-x: auto; white-space: pre-wrap;
}
pre code { background: none; padding: 0; }
hr { border: none; border-top: 1px solid rgba(0,0,0,.1); margin: 10px 0; }
strong { font-weight: 700; }
em { font-style: italic; }
a { color: #2060cc; }

@media (prefers-color-scheme: dark) {
    body { color: #e8e8e8; }
    h2 { border-bottom-color: rgba(255,255,255,.12); }
    h3 { color: #aaa; }
    blockquote { border-left-color: #a07050; color: #999; background: rgba(255,255,255,.04); }
    code { background: rgba(255,255,255,.10); }
    pre { background: rgba(255,255,255,.07); }
    hr { border-top-color: rgba(255,255,255,.1); }
    a { color: #5599ff; }
}
"""

// MARK: - Markdown → HTML

private func mdToHTML(_ text: String) -> String {
    let lines = text.components(separatedBy: "\n")
    var out = ""
    var inCode = false
    var inUL = false
    var inOL = false

    func closeList() {
        if inUL { out += "</ul>\n"; inUL = false }
        if inOL { out += "</ol>\n"; inOL = false }
    }

    for line in lines {
        if line.hasPrefix("```") {
            closeList()
            if inCode { out += "</code></pre>\n"; inCode = false }
            else { out += "<pre><code>"; inCode = true }
            continue
        }
        if inCode { out += escHTML(line) + "\n"; continue }

        if line.hasPrefix("### ") { closeList(); out += "<h3>\(inline(String(line.dropFirst(4))))</h3>\n"; continue }
        if line.hasPrefix("## ")  { closeList(); out += "<h2>\(inline(String(line.dropFirst(3))))</h2>\n"; continue }
        if line.hasPrefix("# ")   { closeList(); out += "<h1>\(inline(String(line.dropFirst(2))))</h1>\n"; continue }
        if line.hasPrefix("> ")   { closeList(); out += "<blockquote>\(inline(String(line.dropFirst(2))))</blockquote>\n"; continue }
        if line == "---" || line == "***" { closeList(); out += "<hr>\n"; continue }

        if line.hasPrefix("- ") || line.hasPrefix("* ") {
            if inOL { out += "</ol>\n"; inOL = false }
            if !inUL { out += "<ul>\n"; inUL = true }
            out += "<li>\(inline(String(line.dropFirst(2))))</li>\n"
            continue
        }
        if line.range(of: #"^\d+\. .+"#, options: .regularExpression) != nil {
            if inUL { out += "</ul>\n"; inUL = false }
            if !inOL { out += "<ol>\n"; inOL = true }
            let content = line.components(separatedBy: ". ").dropFirst().joined(separator: ". ")
            out += "<li>\(inline(content))</li>\n"
            continue
        }
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
            closeList(); out += "<br>\n"; continue
        }
        closeList()
        out += "<p>\(inline(line))</p>\n"
    }
    closeList()
    return out
}

private func inline(_ text: String) -> String {
    var s = escHTML(text)
    s = applyRegex(s, #"\*\*\*(.+?)\*\*\*"#, "<strong><em>$1</em></strong>")
    s = applyRegex(s, #"\*\*(.+?)\*\*"#,     "<strong>$1</strong>")
    s = applyRegex(s, #"__(.+?)__"#,          "<strong>$1</strong>")
    s = applyRegex(s, #"\*(.+?)\*"#,          "<em>$1</em>")
    s = applyRegex(s, #"_(.+?)_"#,            "<em>$1</em>")
    s = applyRegex(s, #"~~(.+?)~~"#,          "<del>$1</del>")
    s = applyRegex(s, #"`(.+?)`"#,            "<code>$1</code>")
    s = applyRegex(s, #"\[(.+?)\]\((.+?)\)"#, "<a href=\"$2\">$1</a>")
    return s
}

private func escHTML(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
     .replacingOccurrences(of: "<", with: "&lt;")
     .replacingOccurrences(of: ">", with: "&gt;")
}

private func applyRegex(_ s: String, _ pattern: String, _ template: String) -> String {
    (try? NSRegularExpression(pattern: pattern))
        .map { $0.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template) }
        ?? s
}

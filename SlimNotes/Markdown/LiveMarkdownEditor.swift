import SwiftUI
import AppKit

// MARK: - Line type

private enum LineType {
    case h1, h2, h3
    case ul
    case ol(Int)
    case checkbox(Bool)
    case hr
    case codeBlock
    case codeLine
    case plain
}

private func lineType(_ raw: String) -> LineType {
    if raw.hasPrefix("### ")  { return .h3 }
    if raw.hasPrefix("## ")   { return .h2 }
    if raw.hasPrefix("# ")    { return .h1 }
    if raw.hasPrefix("- [x]") { return .checkbox(true) }
    if raw.hasPrefix("- [ ]") { return .checkbox(false) }
    if raw.hasPrefix("- ") || raw.hasPrefix("* ") { return .ul }
    if let m = raw.range(of: #"^(\d+)\. "#, options: .regularExpression),
       let n = Int(raw[m].dropLast(2)) { return .ol(n) }
    if raw.hasPrefix("```")   { return .codeBlock }
    if raw.range(of: #"^(-{3,}|={3,}|_{3,})$"#, options: .regularExpression) != nil { return .hr }
    return .plain
}

private func lineBody(_ raw: String, _ type: LineType) -> String {
    switch type {
    case .h1:       return String(raw.dropFirst(2))
    case .h2:       return String(raw.dropFirst(3))
    case .h3:       return String(raw.dropFirst(4))
    case .ul:       return String(raw.dropFirst(2))
    case .checkbox:
        let prefix6 = raw.hasPrefix("- [ ] ") || raw.hasPrefix("- [x] ")
        return String(raw.dropFirst(prefix6 ? 6 : 5))
    case .ol:
        if let r = raw.range(of: #"^\d+\. "#, options: .regularExpression) {
            return String(raw[r.upperBound...])
        }
        return raw
    default: return raw
    }
}

private func continuation(_ raw: String, _ type: LineType) -> String? {
    switch type {
    case .ul:        return raw.hasPrefix("- ") ? "- " : "* "
    case .checkbox:  return "- [ ] "
    case .ol(let n): return "\(n + 1). "
    default:         return nil
    }
}

// MARK: - Attributes

private let plainAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13),
    .foregroundColor: NSColor.labelColor
]

// kern: -0.5 cancels CoreText's minimum glyph advance for 0.001pt font,
// ensuring hidden markers truly occupy zero width.
private let hiddenAttrs: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor.clear,
    .font: NSFont.systemFont(ofSize: 0.001),
    .kern: -0.5
]

private let dimAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
    .foregroundColor: NSColor.tertiaryLabelColor
]

private let h1Attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 20),
    .foregroundColor: NSColor.labelColor
]
private let h2Attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 16),
    .foregroundColor: NSColor.labelColor
]
private let h3Attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 14),
    .foregroundColor: NSColor.secondaryLabelColor
]
private let codeBlockAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
    .foregroundColor: NSColor.secondaryLabelColor
]

// MARK: - Build NSAttributedString for one line

private func buildLine(_ raw: String, _ type: LineType) -> NSAttributedString {
    switch type {

    case .h1:
        let out = NSMutableAttributedString(string: "# ", attributes: hiddenAttrs)
        let body = NSMutableAttributedString(string: lineBody(raw, .h1), attributes: h1Attrs)
        applyInline(body)
        out.append(body)
        return out

    case .h2:
        let out = NSMutableAttributedString(string: "## ", attributes: hiddenAttrs)
        let body = NSMutableAttributedString(string: lineBody(raw, .h2), attributes: h2Attrs)
        applyInline(body)
        out.append(body)
        return out

    case .h3:
        let out = NSMutableAttributedString(string: "### ", attributes: hiddenAttrs)
        let body = NSMutableAttributedString(string: lineBody(raw, .h3), attributes: h3Attrs)
        applyInline(body)
        out.append(body)
        return out

    case .ul:
        let marker = raw.hasPrefix("- ") ? "- " : "* "
        let out = NSMutableAttributedString(string: marker, attributes: dimAttrs)
        let body = NSMutableAttributedString(string: lineBody(raw, .ul), attributes: plainAttrs)
        applyInline(body)
        out.append(body)
        return out

    case .ol(let n):
        guard let pr = raw.range(of: #"^\d+\. "#, options: .regularExpression) else {
            return NSAttributedString(string: raw, attributes: plainAttrs)
        }
        let rawPrefix = String(raw[raw.startIndex..<pr.upperBound])
        let out = NSMutableAttributedString(string: rawPrefix, attributes: dimAttrs)
        let body = NSMutableAttributedString(string: lineBody(raw, .ol(n)), attributes: plainAttrs)
        applyInline(body)
        out.append(body)
        return out

    case .checkbox(let checked):
        let prefixLen = (raw.hasPrefix("- [ ] ") || raw.hasPrefix("- [x] ")) ? 6 : 5
        let markerStr = String(raw.prefix(prefixLen))
        let out = NSMutableAttributedString(string: markerStr, attributes: hiddenAttrs)

        let para = NSMutableParagraphStyle()
        para.headIndent = 20
        para.firstLineHeadIndent = 20
        var bodyBase = plainAttrs
        bodyBase[.paragraphStyle] = para
        if checked {
            bodyBase[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            bodyBase[.foregroundColor]    = NSColor.tertiaryLabelColor
        }
        let body = NSMutableAttributedString(
            string: lineBody(raw, .checkbox(checked)),
            attributes: bodyBase
        )
        if !checked { applyInline(body) }
        out.append(body)
        return out

    case .hr:
        let para = NSMutableParagraphStyle()
        para.paragraphSpacingBefore = 6
        para.paragraphSpacing = 6
        para.alignment = .center
        return NSAttributedString(string: raw, attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.tertiaryLabelColor,
            .kern: 8.0,
            .paragraphStyle: para
        ])

    case .codeBlock, .codeLine:
        return NSAttributedString(string: raw, attributes: codeBlockAttrs)

    case .plain:
        let tabs = raw.prefix(while: { $0 == "\t" }).count
        var base = plainAttrs
        if tabs > 0 {
            let para = NSMutableParagraphStyle()
            let indent = CGFloat(tabs) * 20
            para.firstLineHeadIndent = indent
            para.headIndent = indent
            base[.paragraphStyle] = para
        }
        let out = NSMutableAttributedString(string: raw, attributes: base)
        applyInline(out)
        return out
    }
}

// MARK: - Inline: tokenize → code-first → stack match → apply
//
// Code spans are atomic: delimiters inside `code` are ignored.
// All other spans support arbitrary nesting via a stack.

private enum DelimKind: Equatable {
    case bold, italic, strike, code
}

private struct Token { let kind: DelimKind; let range: NSRange }
private struct Span  { let open: NSRange; let content: NSRange; let close: NSRange; let kind: DelimKind }

private func tokenize(_ s: NSString) -> [Token] {
    var tokens: [Token] = []
    var i = 0
    while i < s.length {
        let c = s.character(at: i)
        let next: unichar = i + 1 < s.length ? s.character(at: i + 1) : 0
        switch c {
        case 0x2A:
            if next == 0x2A { tokens.append(Token(kind: .bold,   range: NSRange(location: i, length: 2))); i += 2 }
            else            { tokens.append(Token(kind: .italic, range: NSRange(location: i, length: 1))); i += 1 }
        case 0x5F:
            if next == 0x5F { tokens.append(Token(kind: .bold,   range: NSRange(location: i, length: 2))); i += 2 }
            else            { tokens.append(Token(kind: .italic, range: NSRange(location: i, length: 1))); i += 1 }
        case 0x7E:
            if next == 0x7E { tokens.append(Token(kind: .strike, range: NSRange(location: i, length: 2))); i += 2 }
            else            { i += 1 }
        case 0x2D:
            if next == 0x2D { tokens.append(Token(kind: .strike, range: NSRange(location: i, length: 2))); i += 2 }
            else            { i += 1 }
        case 0x60:
            tokens.append(Token(kind: .code, range: NSRange(location: i, length: 1))); i += 1
        default: i += 1
        }
    }
    return tokens
}

private func matchSpans(_ tokens: [Token]) -> [Span] {
    var stack: [Token] = []
    var spans: [Span]  = []
    for t in tokens {
        if let idx = stack.lastIndex(where: { $0.kind == t.kind }) {
            let opener = stack[idx]
            let cStart = opener.range.upperBound
            let cEnd   = t.range.location
            guard cEnd > cStart else { stack.remove(at: idx); continue }
            spans.append(Span(open: opener.range,
                              content: NSRange(location: cStart, length: cEnd - cStart),
                              close: t.range, kind: t.kind))
            stack.remove(at: idx)
        } else {
            stack.append(t)
        }
    }
    return spans
}

private func applyInline(_ attr: NSMutableAttributedString) {
    guard attr.length > 0 else { return }
    let baseFont = attr.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
                   ?? NSFont.systemFont(ofSize: 13)
    let all = tokenize(attr.string as NSString)

    // Code spans first — content is atomic (no inner markdown)
    let codeSpans = matchSpans(all.filter { $0.kind == .code })

    func insideCode(_ r: NSRange) -> Bool {
        codeSpans.contains { $0.content.location <= r.location && r.upperBound <= $0.content.upperBound }
    }
    let otherSpans = matchSpans(all.filter { $0.kind != .code && !insideCode($0.range) })

    for span in codeSpans + otherSpans {
        let style: [NSAttributedString.Key: Any]
        switch span.kind {
        case .bold:
            style = [.font: NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)]
        case .italic:
            style = [.obliqueness: 0.2]
        case .strike:
            style = [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
        case .code:
            style = [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                     .backgroundColor: NSColor.labelColor.withAlphaComponent(0.08)]
        }
        attr.addAttributes(style,       range: span.content)
        attr.addAttributes(hiddenAttrs, range: span.open)
        attr.addAttributes(hiddenAttrs, range: span.close)
    }
}

// MARK: - Write one line into NSTextStorage (undo-excluded)

private func writeLine(_ storage: NSTextStorage, at offset: Int, raw: String, type: LineType,
                       undoManager: UndoManager?) {
    let len = (raw as NSString).length
    guard len > 0 else { return }
    let range = NSRange(location: offset, length: len)
    guard range.upperBound <= storage.length else { return }

    undoManager?.disableUndoRegistration()
    defer { undoManager?.enableUndoRegistration() }

    let styled = buildLine(raw, type)
    storage.setAttributes(plainAttrs, range: range)
    styled.enumerateAttributes(
        in: NSRange(location: 0, length: min(styled.length, len)), options: []
    ) { attrs, r, _ in
        let target = NSRange(location: offset + r.location, length: r.length)
        if target.upperBound <= storage.length {
            storage.setAttributes(attrs, range: target)
        }
    }
}

// MARK: - Checkbox overlay

private final class CheckboxView: NSView {
    var isChecked: Bool { didSet { needsDisplay = true } }
    var onToggle: ((Bool) -> Void)?

    init(checked: Bool, frame: NSRect) {
        self.isChecked = checked
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 1.5, dy: 1.5)
        let path = NSBezierPath(roundedRect: r, xRadius: 2.5, yRadius: 2.5)
        if isChecked {
            NSColor.controlAccentColor.setFill(); path.fill()
            let ck = NSBezierPath()
            ck.move(to:  NSPoint(x: r.minX + 2.5, y: r.midY - 0.5))
            ck.line(to:  NSPoint(x: r.midX - 0.5, y: r.minY + 2.5))
            ck.line(to:  NSPoint(x: r.maxX - 1.5, y: r.maxY - 1.5))
            NSColor.white.setStroke()
            ck.lineWidth = 1.5; ck.lineJoinStyle = .round; ck.stroke()
        } else {
            NSColor.labelColor.withAlphaComponent(0.28).setStroke()
            path.lineWidth = 1.2; path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        isChecked.toggle(); onToggle?(isChecked)
    }
}

// MARK: - LiveMarkdownEditor

struct LiveMarkdownEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let tv     = scroll.documentView as! NSTextView
        tv.delegate    = context.coordinator
        tv.isRichText  = true
        tv.isEditable  = true
        tv.isSelectable = true
        tv.allowsUndo  = true
        tv.drawsBackground = false
        tv.textContainerInset = NSSize(width: 12, height: 10)
        tv.isAutomaticQuoteSubstitutionEnabled  = false
        tv.isAutomaticDashSubstitutionEnabled   = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        scroll.drawsBackground     = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers  = true
        context.coordinator.load(tv, text: text)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        let tv = scroll.documentView as! NSTextView
        // Bug 1 fix: only reload when text actually changed externally (note switch).
        // Never call load() for changes that originated from typing in this view.
        guard tv.string != text else { return }
        context.coordinator.load(tv, text: text)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LiveMarkdownEditor
        var isUpdating = false

        init(_ parent: LiveMarkdownEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView, !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }

            parent.text = tv.string

            // Skip styling while IME is composing (e.g. Korean input)
            if tv.hasMarkedText() { return }

            if let storage = tv.textStorage {
                let ns  = tv.string as NSString
                guard ns.length > 0 else { return }
                let loc = min(tv.selectedRange().location, ns.length - 1)
                let pr  = ns.paragraphRange(for: NSRange(location: loc, length: 0))
                let ln  = ns.substring(with: pr).trimmingCharacters(in: .newlines)
                storage.beginEditing()
                writeLine(storage, at: pr.location, raw: ln, type: lineType(ln),
                          undoManager: tv.undoManager)
                storage.endEditing()
            }
            syncCheckboxes(tv)
        }

        func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
            guard sel == #selector(NSResponder.insertNewline(_:)) else { return false }
            return handleEnter(tv)
        }
        
        func load(_ tv: NSTextView, text: String) {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }
            
            let currentLen = tv.textStorage?.length ?? 0
            tv.undoManager?.disableUndoRegistration()
            tv.textStorage?.replaceCharacters(
                in: NSRange(location: 0, length: currentLen),
                with: NSAttributedString(string: text, attributes: plainAttrs)
            )
            tv.undoManager?.enableUndoRegistration()

            styleAll(tv)
            tv.setSelectedRange(NSRange(location: 0, length: 0))
            tv.typingAttributes = plainAttrs
            tv.layoutManager?.ensureLayout(for: tv.textContainer!)
            syncCheckboxes(tv)
        }

        private func styleAll(_ tv: NSTextView) {
            guard let storage = tv.textStorage else { return }
            let ns = tv.string as NSString
            var pos = 0, inCode = false
            storage.beginEditing()
            while pos < ns.length {
                let pr = ns.paragraphRange(for: NSRange(location: pos, length: 0))
                let ln = ns.substring(with: pr).trimmingCharacters(in: .newlines)
                let t: LineType
                if ln.hasPrefix("```") { inCode = !inCode; t = .codeBlock }
                else if inCode { t = .codeLine }
                else { t = lineType(ln) }
                writeLine(storage, at: pr.location, raw: ln, type: t,
                          undoManager: tv.undoManager)
                pos = pr.upperBound
                if pos <= pr.location { break }
            }
            storage.endEditing()
        }

        private func handleEnter(_ tv: NSTextView) -> Bool {
            isUpdating = true
            defer { isUpdating = false }

            let sel   = tv.selectedRange()
            let ns    = tv.string as NSString
            let pr    = ns.paragraphRange(for: NSRange(location: sel.location, length: 0))
            let ln    = ns.substring(with: pr).trimmingCharacters(in: .newlines)
            let t     = lineType(ln)
            let body  = lineBody(ln, t)
            let atEnd = sel.location >= pr.location + (ln as NSString).length

            // Style the departing line. Undo-excluded: Cmd+Z should restore raw
            // markdown text (via text undo), not fight with attribute undo.
            if let storage = tv.textStorage {
                storage.beginEditing()
                writeLine(storage, at: pr.location, raw: ln, type: t,
                          undoManager: tv.undoManager)
                storage.endEditing()
            }

            tv.breakUndoCoalescing()
            if atEnd, let prefix = continuation(ln, t) {
                if body.trimmingCharacters(in: .whitespaces).isEmpty {
                    tv.undoManager?.disableUndoRegistration()
                    tv.textStorage?.replaceCharacters(in: pr, with: "\n")
                    tv.undoManager?.enableUndoRegistration()
                    tv.setSelectedRange(NSRange(location: pr.location + 1, length: 0))
                } else {
                    tv.insertText("\n" + prefix, replacementRange: sel)
                }
            } else {
                tv.insertText("\n", replacementRange: sel)
            }

            tv.typingAttributes = plainAttrs
            parent.text = tv.string
            tv.layoutManager?.ensureLayout(for: tv.textContainer!)
            syncCheckboxes(tv)
            return true
        }

        // MARK: Checkbox overlays

        func syncCheckboxes(_ tv: NSTextView) {
            tv.subviews.filter { $0 is CheckboxView }.forEach { $0.removeFromSuperview() }
            guard let lm = tv.layoutManager, let tc = tv.textContainer else { return }
            let ns = tv.string as NSString
            var pos = 0, inCode = false
            while pos < ns.length {
                let pr = ns.paragraphRange(for: NSRange(location: pos, length: 0))
                let ln = ns.substring(with: pr).trimmingCharacters(in: .newlines)
                if ln.hasPrefix("```") { inCode = !inCode }
                if !inCode, ln.hasPrefix("- [ ]") || ln.hasPrefix("- [x]") {
                    let checked = ln.hasPrefix("- [x]")
                    // Use the first visible character after the hidden marker to position the box
                    let gr = lm.glyphRange(
                        forCharacterRange: NSRange(location: pr.location, length: 1),
                        actualCharacterRange: nil
                    )
                    var rect = lm.boundingRect(forGlyphRange: gr, in: tc)
                    rect.origin.x += tv.textContainerInset.width
                    rect.origin.y += tv.textContainerInset.height
                    let sz: CGFloat = 14
                    let cb = CheckboxView(
                        checked: checked,
                        frame: NSRect(x: rect.minX, y: rect.midY - sz / 2, width: sz, height: sz)
                    )
                    let loc = pr.location
                    cb.onToggle = { [weak self, weak tv] now in
                        guard let self, let tv else { return }
                        self.toggleCheckbox(tv, at: loc, checked: now)
                    }
                    tv.addSubview(cb)
                }
                pos = pr.upperBound
                if pos <= pr.location { break }
            }
        }

        private func toggleCheckbox(_ tv: NSTextView, at pos: Int, checked: Bool) {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }
            let ns   = tv.string as NSString
            let pr   = ns.paragraphRange(for: NSRange(location: pos, length: 0))
            let ln   = ns.substring(with: pr).trimmingCharacters(in: .newlines)
            let body = lineBody(ln, lineType(ln))
            let newLn = (checked ? "- [x] " : "- [ ] ") + body
            let rr = NSRange(location: pr.location, length: (ln as NSString).length)
            tv.textStorage?.replaceCharacters(in: rr, with: newLn)
            if let storage = tv.textStorage {
                storage.beginEditing()
                writeLine(storage, at: pr.location, raw: newLn, type: lineType(newLn),
                          undoManager: tv.undoManager)
                storage.endEditing()
            }
            parent.text = tv.string
            tv.layoutManager?.ensureLayout(for: tv.textContainer!)
            syncCheckboxes(tv)
        }
    }
}

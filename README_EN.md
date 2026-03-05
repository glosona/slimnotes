**English** | [한국어](./README.md)

# SlimNotes

**A lightweight markdown note-taking app for macOS**

> A simple note-taking app that uses Markdown.

![SlimNotes Screenshot](./Slim%20Notes.png)

---

## How I Used AI

I started this project with zero Swift experience. I gave Claude AI my app concept and used the generated code as a starting point — then learned Swift/SwiftUI by reading through it.

This wasn't just copy-pasting AI output. It was a cycle of **reading code → identifying issues → formulating specific requirements → iterating**.

| What I Did | Details |
|---|---|
| **Style customization** | Replaced native buttons with custom ones, added opacity slider, etc. |
| **Markdown rendering debugging** | Analyzed `LiveMarkdownEditor.swift` directly to identify bugs and communicate fixes |
| **Performance optimization** | Fixed SwiftUI real-time rendering lag → changed to apply formatting on Enter key |
| **Keeping it lightweight** | No external libraries — used AppKit (`NSTextView`, `NSTextStorage`) directly |

---

## Key Features

- Live markdown rendering (applied per-line on Enter)
- Header/emphasis markers are hidden after rendering; list markers stay visible
- Adjustable window background opacity
- Auto-save notes (JSON-based)
- Sidebar note management (create / delete / select)

### Supported Markdown Syntax

| Syntax | Example | Notes |
|---|---|---|
| Headings | `# H1` `## H2` `### H3` | Markers hidden, size/weight applied |
| Emphasis | `**bold**` `_italic_` `~~strikethrough~~` | Markers hidden |
| Inline code | `` `code` `` | Background highlight |
| Lists | `- item` `1. item` | Markers kept (dimmed) |
| Code blocks | ` ``` ` | Monospace font |
| Checklists | `- [ ]` `- [x]` | ⚠️ Unstable — fix planned |
| Horizontal rules | `---` `===` `___` | ⚠️ Unstable — fix planned |

---

## Installation

### Option 1 — Download the app (recommended)

1. Download `SlimNotes.app.zip` from [Releases](https://github.com/glosona/SlimNotes/releases/latest)
2. Unzip and move to `/Applications`
3. On first launch, right-click → **Open** (to bypass macOS Gatekeeper)

> This app is not signed with an Apple Developer certificate.
> You can also allow it via System Settings → Privacy & Security → "Open Anyway".

### Option 2 — Build from source

```bash
git clone https://github.com/glosona/SlimNotes.git
cd SlimNotes
open SlimNotes.xcodeproj
# Build & run with ⌘+R in Xcode
```

**Requirements**
- macOS 13+
- Xcode 15+

---

## Tech Stack

| Area | Technology |
|---|---|
| UI Framework | **SwiftUI** |
| Text Editing | **NSTextView** (AppKit) — bridged via `NSViewRepresentable` |
| Markdown Rendering | **NSTextStorage + NSLayoutManager** — attribute-based live rendering |
| Data Storage | **JSON (Codable)** — direct filesystem persistence |
| External Dependencies | **None** — pure Apple frameworks only |

---

## Roadmap

- [ ] Stabilize checklist / horizontal rule rendering
- [ ] Write tests (Unit + UI)
- [ ] Profile and optimize memory usage
  - The app binary is small, but memory usage under live rendering needs measurement
- [ ] Expand markdown syntax support

---

## License

MIT License

## Why
PLAN.md ("Field editor: rich text") asks for a rich-text field editor. In the final sweep, Add card and Edit note show raw markup: the sample Example field reads `<b>明天</b>见`, and the Bold, Italic and Underline buttons insert literal `<b>…</b>` tags into a plain `TextField`. Desktop Anki shows the formatting, not the tags.

## What Changes
- Edit each field as rich text. iOS 26 `TextEditor` takes an `AttributedString` with a selection, and the formatting buttons toggle bold, italic and underline on the selection.
- Add a small converter between the engine's field HTML and `AttributedString`. It handles `<b>/<strong>`, `<i>/<em>`, `<u>`, `<br>` and `&nbsp;`, plus the entities `&amp;`, `&lt;`, `&gt;` and `&quot;`.
- Keep markup the editor can't show unchanged: `<img>`, `[sound:…]`, `<span …>`, `<div>`, cloze `{{c1::…}}` and MathJax all round-trip with no loss. A field that contains tags the converter doesn't know stays in plain-text HTML mode, so its data is never lost.
- Cloze stays a text insertion (`{{cN::…}}`), as now.
- The note goes back to the engine as HTML through the existing `add_note`/`update_notes` path. Nothing changes in the engine.

## Impact
`app/Cornhub/Screens/NoteEditor/NoteEditorScreen.swift`, `FieldFormatting.swift`, a new `FieldHTML.swift`, `NoteEditorModel.swift` if needed, and unit tests for the converter.

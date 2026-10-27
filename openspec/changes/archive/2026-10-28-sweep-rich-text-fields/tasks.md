## 1. Rich text fields
- [x] 1.1 `FieldHTML` converts field HTML ⇄ `AttributedString` for b/strong, i/em, u, br and the common entities. Fields with unsupported markup round-trip unchanged (they stay plain-text HTML)
- [x] 1.2 Editor fields are rich-text `TextEditor`s. Bold, Italic and Underline toggle the attribute on the selection; Cloze still inserts `{{cN::…}}`
- [x] 1.3 Saving writes HTML back. Adding and editing a note keep `<img>`, `[sound:…]` and cloze markup intact

## 2. Proof
- [x] 2.1 `FieldHTMLTests` cover the round trip: plain, bold/italic/underline, nested, br, entities, and the unsupported-markup passthrough
- [x] 2.2 `ScreenTourUITests` `testAddCard` and `testBrowse` pass. Review the add-card and edit-note screenshots: no raw tags are visible, and bold text shows as bold

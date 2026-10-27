## Decisions
- Fields are edited as HTML strings in SwiftUI `TextEditor`s. Bold, italic, underline and cloze wrap the current selection with `<b>`, `<i>`, `<u>` and `{{cN::…}}` (next free cloze number).
- Pictures and recordings are stored with `add_media_file` and inserted as `<img src>` and `[sound:…]`.
- Sticky fields are remembered per note type in memory for the session and kept after adding.
- Chinese note type: Hanzi beside the picture tile, Pinyin and English side by side, Example below; other fields get a generic block.

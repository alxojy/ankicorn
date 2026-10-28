## Why
User feedback on Add card for the Chinese note type: the pinyin can be derived from the hanzi as it's typed, so a separate pinyin step is busywork. English can be filled in automatically too, as long as the user can still type their own.

## What Changes
- **Pinyin from the hanzi, on the device.** As the Hanzi field changes (debounced about 300 ms), fill **Pinyin** with tone-marked pinyin from `CFStringTransform` / `String.applyingTransform(.mandarinToLatin, reverse: false)`. Syllables are spaced as the transform gives them, lower case, and markup is stripped first. It's offline and free. The Example pinyin field is derived from the Example field the same way.
- **English from the hanzi.** After the pinyin, fill **English** using Apple's on-device Translation framework (zh-Hans → en, through `.translationTask` in the editor). If translation isn't available (the language pack isn't downloaded and the user declines, or an older device), fall back to `TextGenerator` (Apple Intelligence or the Claude key) with a short "give the English meaning of this word in 1–4 words" prompt. If neither works, leave English empty, and show no error banner for that.
- **Free text always wins.** A field is auto-filled only while it is empty or still holds the value the app last filled in. Once the user edits it, it is never overwritten, until they clear it. Clearing the hanzi clears the auto values it produced.
- **UI:** the Pinyin and English fields stay visible and editable, side by side as in PLAN.md. An auto-filled value shows a small "auto" sparkle badge or muted label in the field title, so it's clear it came from the app. Polyphonic characters (行, 了, 的) can come out wrong; the badge invites a check.
- The "Auto-fill example, audio and picture" button stays for the example and audio. It no longer needs to touch pinyin or English.
- This only applies when the note type is the bundled Chinese vocab type, or a note type with fields named Hanzi/Pinyin/English (case-insensitive). Other note types are unchanged.
- Editing an existing note (Browse → Edit) does not auto-fill.

## Impact
`Screens/NoteEditor/NoteEditorModel.swift`, `NoteEditorScreen.swift`, and a new `Extras/Pinyin.swift` (or similar). Unit tests for the pinyin helper and the "don't overwrite edits" rule.

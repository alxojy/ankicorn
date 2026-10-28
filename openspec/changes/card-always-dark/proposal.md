## Why
User screenshot (HSK card 感觉 on iPhone, after `notetype-app-style` merged): the card is still a bright cream page inside the dark app. The user wants every card on the dark Ink background, like the original design, without having to restyle each note type or change how desktop Anki looks.

Cause, observed in code: `CardStyle.decide` reads the note type's `.card { background… }`. A light background gives `.light(background:)`, which keeps the cream background and dark default text, as the `Imported note types render readably` requirement asks. `notetype-app-style` can rewrite the note type CSS, but that changes desktop too and has to be done per note type.

## What Changes
- **Dark by default, in the app only:** a setting *Card colours* in Settings › Review, with **App (dark)** as the default and **Note type's own** as the other choice. Nothing in the collection or the note type changes, so desktop Anki and syncing are unaffected.
- **How a light card becomes dark (App mode):** when `CardStyle.decide` returns `.light`, the card's content is shown on the Ink card colour with its colours inverted and hues kept (`filter: invert(1) hue-rotate(180deg)` on the card content). Dark text becomes light, the cream page becomes dark, and coloured text keeps its hue (the green pinyin stays green, lighter). Pictures, videos and other media are inverted back so they show their real colours. The page background behind the content is the Ink card token, not an inverted cream.
- **Readable colours:** after inversion, text keeps at least WCAG AA contrast against the Ink card colour. If a note type's coloured text falls below that (checked on the computed colour of the pinyin/meaning elements in the test fixture), raise its lightness.
- **Unchanged cases:** `.ink` (no background) and `.dark` cards already look right and are left as they are. **Note type's own** keeps today's behaviour exactly.
- **Interaction with `notetype-app-style`:** that feature stays for people who want desktop to match too. In App mode the review ⋯ "Restyle this note type…" entry is no longer pushed for light note types; it stays in Settings › Note types.

## Impact
`Screens/Review/CardWebView.swift` (document CSS per style and setting), `Screens/Review/CardStyle.swift` (unchanged decision, new rendering branch), the settings store and Settings › Review, `ReviewScreen` (⋯ menu entry), tests. Updates the `Imported note types render readably` requirement.

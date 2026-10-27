## Decisions
- All mutation goes through rslib wrappers in `Backend+Manage.swift`; Swift only builds requests.
- Note type editing uses `get_notetype` / `update_notetype` on the protobuf `Notetype`; changing a note type's kind or the change-notetype page is out of scope (TODO).
- Find duplicates groups the first field of a note type's notes in Swift after an engine search, as desktop Anki's Python does.

## Why
Reviewing is the core of the app. The Study and Start review buttons are placeholders.

## What Changes
- Full-screen review: header (close, progress, Undo, menu placeholder), card panel rendering rslib's question/answer HTML in a WKWebView, tap to reveal, grade bar with intervals from `describe_next_states`, swipe to grade, congrats screen.
- Backend wrappers: `getQueuedCards`, `answerCard`, `describeNextStates`, `renderExistingCard`, `undo`, `redo`, `getUndoStatus`, `congratsInfo`, `setCurrentDeck`.
- Start review and deck Study launch it.

## Impact
New `review` capability; `decks-home` buttons now open it.

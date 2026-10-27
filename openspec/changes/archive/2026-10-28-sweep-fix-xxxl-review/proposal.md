## Why
PLAN.md asks for Dynamic Type support. In the final sweep at the largest accessibility size (61-review-xxxl, 60-home-xxxl):
- The review grade bar breaks labels mid-word ("Ag/ain", "Go/od", "<6/m").
- The undo and ⋯ buttons in the review header collide.
- The card area is blank when the screenshot is taken.
- On home, the New/Learning/Review legend breaks mid-word ("Learn/ing").

Two small copy bugs as well:
- Custom study says "1 cards".
- The login sheet cuts its explanation off at one line ("Only a sync k…").

## What Changes
- Grade bar: at accessibility sizes, cap the label type size (as the tab bar does) or switch to a 2×2 grid, so labels never break mid-word. Each button stays at least 44 pt.
- Review header: at accessibility sizes, keep the close, undo and ⋯ buttons as fixed 44 pt circles with capped icon sizes.
- Card at XXXL: find out why the card is blank (a web view frame or load at large sizes, or just a screenshot taken before load). Fix it so the question shows; the card HTML may scale with Dynamic Type.
- Home legend: wrap whole items (a flow layout or vertical stack at accessibility sizes), never mid-word.
- "1 card" / "N cards" pluralisation in Custom study (use inflection `^[\(n) card](inflect: true)` or a plural string).
- The login sheet explanation wraps to as many lines as it needs.

## Impact
`Screens/Review/ReviewScreen.swift`, `Screens/DeckHome/DeckHomeScreen.swift`, `Screens/DeckHome/CustomStudySheet.swift` (or wherever the count lives), `Sync/LoginSheet.swift`.

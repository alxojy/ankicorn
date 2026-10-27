## Why
Deck options (FSRS), card info and the stats graphs already exist as Anki's own SvelteKit pages. Hosting them gives full parity quickly, as PLAN.md "Reusing Anki's web pages" says.

## What Changes
- `scripts/build-web.sh` builds the pages from the pinned Anki source (cargo for the generated TS, yarn and vite for the pages) into `app/Cornhub/Resources/AnkiWeb/` (gitignored); `bootstrap.sh` runs it.
- A `WKURLSchemeHandler` serves the bundled pages and forwards `POST /_anki/<method>` to rslib `run_method`, porting mediasrv.py's special endpoints deliberately.
- An Ink CSS override and dark mode are injected into the pages.
- Deck options opens from the deck overview, Card info from the review menu, and the Stats tab hosts the graphs page.
- If the pages were not built, each screen shows a clear error page.

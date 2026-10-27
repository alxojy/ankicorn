## ADDED Requirements

### Requirement: Anki pages hosted in the app
The app SHALL build Anki's deck-options, card-info and graphs pages from the pinned source and serve them from the app bundle in a WKWebView through a custom URL scheme.

#### Scenario: Open a page
- **WHEN** the user opens deck options for a deck
- **THEN** the bundled deck-options page loads for that deck in a sheet, in the Ink dark look

#### Scenario: Pages not built
- **WHEN** the bundled pages are missing
- **THEN** an error page explains that the web pages were not built and how to build them

### Requirement: Backend calls from pages
The scheme handler SHALL forward `POST /_anki/<method>` with a protobuf body to the engine through `run_method` and return the protobuf response, and MUST NOT forward methods outside an allow-list taken from Anki's mediasrv.

#### Scenario: Engine call
- **WHEN** a page posts `/_anki/cardStats`
- **THEN** the engine's `card_stats` response bytes are returned

#### Scenario: Engine error
- **WHEN** the engine returns an error
- **THEN** the handler answers HTTP 500 with the error message as text

### Requirement: Entry points
Deck options SHALL open from the deck overview, Card info from the review menu, and the Stats tab SHALL host the graphs page.

#### Scenario: Stats tab
- **WHEN** the user opens the Stats tab
- **THEN** the graphs page for the current deck is shown

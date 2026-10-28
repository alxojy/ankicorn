## ADDED Requirements

### Requirement: Range drives the whole Stats screen
The Week, Month and Year chips SHALL change every card on the Stats screen: the retention period and its review count, the totals, the activity chart and the forecast.

#### Scenario: Switching to Month
- **WHEN** the user taps Month
- **THEN** retention reads "last 30 days" with its review count, the totals cover 30 days, the activity shows 30 days, and the forecast covers the next 30 days

#### Scenario: Little history
- **WHEN** the user has reviewed only one card, today
- **THEN** each range still visibly differs (labels, totals, chart length), and retention says "from 1 review"

#### Scenario: Nothing in range
- **WHEN** there are no reviews in the selected range
- **THEN** the retention card says "No reviews in this range"

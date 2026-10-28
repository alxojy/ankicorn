## Why
User: "cycling between week, month, year doesn't do anything?" (Stats, All decks).

It technically works, but you can't see it. In `StatsModel`, `range` only picks which true-retention bucket the big number uses (`trueRetention.week/.month/.year`). When the user has only reviewed in the last few days, all three buckets are the same (100%), so the number doesn't move. Everything else on the screen ignores the range:
- the heatmap is fixed at "Last 16 weeks" (112 days);
- the forecast is fixed at "Next 7 days";
- the "cards today" and "min today" lines are always today.

So switching the chips changes nothing visible.

## What Changes
The selected range drives every card on the Stats screen. The engine data is already there (`graphs(search:days: 365)` returns reviews per day, future due, and true retention per bucket):
- **Retention card:**
  - **Label:** reads "True retention · last 7 days / 30 days / 12 months".
  - **Review count:** shows the reviews it's based on ("from 12 reviews"), so a 100% from 1 review reads as such.
  - **No reviews in range:** shows "No reviews in this range" instead of a number.
- **Totals for the range:** next to it, the totals for the range replace the "today" lines: reviews, minutes studied, and days studied out of the days in range. The streak stays, since it's not range-based.
- **Activity chart:**
  - **Week:** 7 daily bars with weekday labels.
  - **Month:** a 5-week heatmap, or 30 daily bars.
  - **Year:** the heatmap over 52 weeks, with month labels and horizontal scroll if it doesn't fit.
  - **Title:** matches the range.
- **Forecast:**
  - **Week:** next 7 days by day.
  - **Month:** next 30 days.
  - **Year:** the next 12 months, by month.
  - **Title:** matches the range.
- **Transition:** switching the chip animates the change (a quick crossfade). VoiceOver announces the new range.

## Impact
`Screens/Stats/StatsModel.swift` (range-aware computed data from the existing graphs response; no new engine calls unless the 365-day window is too short for "12 months" forecast, in which case use the response's future-due as is), `StatsScreen.swift` and the chart views, and tests.

## 1. Range-driven cards
- [x] 1.1 Retention card: range in the label, "from N reviews", "No reviews in this range" when empty
- [x] 1.2 Range totals (reviews, minutes, days studied of days in range) replace the today lines; streak stays
- [x] 1.3 Activity: week = 7 daily bars, month = 30 days, year = 52-week heatmap with month labels; title matches
- [x] 1.4 Forecast: week = 7 days, month = 30 days, year = 12 months by month; title matches
- [x] 1.5 Switching range animates and is announced to VoiceOver

## 2. Proof
- [ ] 2.1 Unit tests on `StatsModel` with a stubbed graphs response that has reviews spread over a year: each range gives different retention, totals, activity length and forecast buckets
- [ ] 2.2 A UI test: tap Week, Month, Year and the activity and forecast titles change, and the retention label names the range. Screenshots of all three reviewed

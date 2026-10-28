## 1. Fix
- [x] 1.1 In-page fit script: measure content height vs viewport (minus the bottom inset), shrink `img` max-height by the overflow shared across pictures, floor 96 pt; report "still overflows" to Swift
- [x] 1.2 Re-run on load, reveal, image load, Dynamic Type and size changes
- [x] 1.3 Bottom fade and scrolling only when it still overflows
- [x] 1.4 Replay circle fully inside the card's bottom-right corner, not overhanging the edge

## 2. Proof
- [ ] 2.1 UI test with an invented card (several lines plus a fixture picture) that overflows only by the picture: the picture's frame is fully inside the card and the replay button doesn't intersect it; screenshot
- [ ] 2.2 UI test with an invented card whose text alone overflows: it still scrolls to the picture (reuse `--seed-long-card`)

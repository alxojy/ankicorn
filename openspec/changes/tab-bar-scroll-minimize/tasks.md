## 1. Behaviour
- [x] 1.1 Scrolling down (more than ~12 pt) on any tab-shell scrolling screen minimizes the tab bar; scrolling up, reaching the top or reaching the end shows it again
- [x] 1.2 Tab bar visibility combines its reasons (selection mode, keyboard if present, scroll-minimized) in one place; switching tabs or navigating shows it again
- [x] 1.3 A bottom scrim (Theme.bg to clear) sits behind the bar so content fades under it
- [x] 1.4 The last row of every tab screen and pushed screen, including the deck overview's subdeck grid, can scroll fully above the visible bar
- [x] 1.5 Reduce Motion fades instead of sliding; with VoiceOver running the bar never minimizes

## 2. Proof
- [ ] 2.1 A unit test of the visibility logic: each reason alone hides the bar, scroll-up/top/end clears scroll-minimized, small jitters don't toggle, VoiceOver keeps it shown
- [ ] 2.2 A UI test on a deck overview with enough subdecks to scroll: swipe up and the tab bar is not hittable; swipe down and it is hittable again; at the end of the content the last tile's frame is above the tab bar's frame. Screenshots before, while minimized, and at the end
- [ ] 2.3 `ScreenTourUITests` still pass (Browse selection mode still hides the bar). Review the screenshots

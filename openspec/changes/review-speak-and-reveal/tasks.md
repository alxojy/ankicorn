## 1. Speak
- [ ] 1.1 Speak plays the note's audio when there is any, otherwise TTS of the headword only (the Hanzi field for Chinese vocab; the first field or stripped question for others)
- [ ] 1.2 Pinyin, English and the example are never spoken

## 2. Reveal
- [ ] 2.1 The question side shows a glass "Show answer" capsule in the grade bar's place; no dimmed grade buttons
- [ ] 2.2 Revealing turns the capsule into the grade bar with a spring (a crossfade with Reduce Motion)

## 3. Proof
- [ ] 3.1 Unit tests for the speech text: a Chinese vocab note gives "你好" only; a note with `[sound:x.mp3]` picks the audio; a Basic note with HTML gives the plain first field
- [ ] 3.2 `ScreenTourUITests` `testReviewFlow` and `testLargestTextSize` pass. Assert that the question side has a "Show answer" button and no "grade-good" button until it's revealed. Review 10-review-question and 11-review-answer

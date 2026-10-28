## 1. Auto-fill as you type
- [x] 1.1 A pinyin helper turns hanzi (with markup stripped) into tone-marked pinyin on the device; Pinyin fills from Hanzi and Example pinyin from Example
- [x] 1.2 English fills from the hanzi through on-device Translation, falling back to TextGenerator, and stays empty and quiet when neither is available
- [x] 1.3 A field the user has edited is never overwritten; clearing the hanzi clears the values it produced; auto values show an "auto" marker
- [x] 1.4 Only Chinese-style note types on Add card; Edit note doesn't auto-fill

## 2. Proof
- [ ] 2.1 Unit tests: `Pinyin.from("你好")` == "nǐ hǎo"; markup is stripped; the model doesn't overwrite an edited Pinyin; clearing the hanzi clears the auto values
- [ ] 2.2 `ScreenTourUITests` `testAddCard`: type 学生 in the Hanzi field (Chinese vocab note type) and assert the Pinyin field reads "xué shēng". Review the add-card screenshot (English may stay empty on the simulator if Translation isn't available; record what happened)

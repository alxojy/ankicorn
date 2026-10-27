## ADDED Requirements

### Requirement: Answer line without the question
In cards mode, the Browse row's secondary line SHALL show the card's answer without repeating the question, with separators between fields.

#### Scenario: Chinese vocab card row
- **WHEN** Browse lists the Hanzi → English card for 你好
- **THEN** the row title is "你好", and the secondary line starts with "hello", not with "你好"

#### Scenario: Example sentence fields stay apart
- **WHEN** a row's answer includes the example sentence, its pinyin and its English
- **THEN** the three appear separated (for example by " · "), not glued together

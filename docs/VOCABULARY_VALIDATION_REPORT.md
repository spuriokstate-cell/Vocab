# Vocabulary Validation Report

Source: `latest_Vocab_Meanings_Grade1_Grade2.pdf` (My Word Book, 63 pages), extracted with `tool/extract_pdf.py` into `assets/vocabulary/grade1.json` and `grade2.json`.

**Result: PASS** (9/9 checks passed)

| Check | Result | Detail |
|---|---|---|
| Grade 1 has exactly 339 entries | ✅ Pass | found 339 |
| Grade 2 has exactly 826 entries | ✅ Pass | found 826 |
| Total is exactly 1,165 entries | ✅ Pass | found 1165 |
| Every entry has a word, meaning and example | ✅ Pass | none missing |
| Every id is unique | ✅ Pass | all unique |
| Ids follow g<grade>_<order> format | ✅ Pass | all match |
| Original order preserved (1..N in each grade, no gaps) | ✅ Pass |  |
| No duplicate words | ✅ Pass | none |
| No stray leading/trailing spaces | ✅ Pass | clean |

## Summary

- Grade 1 entries: 339
- Grade 2 entries: 826
- Total entries: 1165
- Contractions kept exactly as written (10): isn't, didn't, don't, we're, can't, they're, doesn't, wasn't, won't, o'clock
- Fill-in-the-blank questions possible: 1148 of 1165 (17 flagged, see `VOCABULARY_REVIEW_FLAGS.md`)

Meanings and example sentences were copied exactly from the PDF. Nothing was rewritten.

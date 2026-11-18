#!/usr/bin/env python3
"""Validate assets/vocabulary/grade1.json + grade2.json and write two reports.

Usage (from the project folder):
    python3 tool/validate_vocabulary.py

Writes:
    docs/VOCABULARY_VALIDATION_REPORT.md  - counts, ids, order, empty fields, duplicates
    docs/VOCABULARY_REVIEW_FLAGS.md       - entries that need a human decision
Exit code is 1 if a hard validation check fails.
"""
import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
VOCAB = ROOT / "assets" / "vocabulary"
DOCS = ROOT / "docs"
EXPECTED = {1: 339, 2: 826}

# Suggested replacement sentences for examples that don't contain the exact
# target word. These are NOT applied: they need a parent's approval first.
SUGGESTED = {
    "thumb": "Hold up your thumb.", "eye": "Close one eye and wink.",
    "block": "Put the red block on top.", "nail": "Dad hit the nail with a hammer.",
    "wheel": "The front wheel is flat.", "pound": "This bag of apples weighs one pound.",
    "spot": "The puppy has a black spot.", "boot": "I can't find my left boot.",
    "root": "The root grows under the ground.", "potato": "I ate a baked potato.",
    "curtain": "Close the curtain at night.", "taste": "Taste the soup before you add salt.",
    "brick": "He laid one brick at a time.", "manner": "She spoke in a kind manner.",
    "wing": "The bird hurt its wing.", "ton": "The big truck carried a ton of rocks.",
    "bean": "I planted a bean seed.",
}

# Words that sound the same as another word in the list (listening activities
# add the example sentence for context and never offer the twin as a choice).
HOMOPHONES = [
    ["there", "their", "they're"], ["to", "too", "two"], ["by", "buy"], ["for", "four"],
    ["know", "no"], ["knew", "new"], ["right", "write"], ["one", "won"], ["sun", "son"],
    ["our", "hour"], ["eight", "ate"], ["eye", "I"], ["see", "sea"], ["week", "weak"],
    ["meat", "meet"], ["dear", "deer"], ["pair", "pear"], ["bear", "bare"],
    ["piece", "peace"], ["blue", "blew"], ["knight", "night"], ["hole", "whole"],
    ["sail", "sale"], ["tail", "tale"], ["road", "rode"], ["plain", "plane"],
    ["here", "hear"], ["wood", "would"], ["sent", "cent"], ["break", "brake"],
    ["threw", "through"], ["be", "bee"], ["so", "sew"], ["toe", "tow"],
    ["wait", "weight"], ["way", "weigh"], ["which", "witch"], ["nose", "knows"],
    ["its", "it's"], ["red", "read"], ["wear", "where"], ["mail", "male"],
    ["flower", "flour"], ["hair", "hare"], ["heel", "heal"], ["not", "knot"],
    ["made", "maid"], ["seen", "scene"], ["tied", "tide"], ["knock", "nock"],
]


# Words where a following 's is a contraction (it's = it is), not a possessive.
NO_POSSESSIVE = {"it", "that", "what", "he", "she", "there", "here", "who", "let", "where", "how"}


def find_word(word: str, text: str) -> list:
    """Spans of whole-word matches. A possessive 's after a noun is allowed."""
    spans = []
    for m in re.finditer(r"(?<![A-Za-z'’])" + re.escape(word) + r"(?![A-Za-z])", text, re.I):
        nxt = text[m.end():m.end() + 3]
        if nxt[:1] in ("'", "’"):
            possessive = nxt[1:2].lower() == "s" and not nxt[2:3].isalpha()
            if not possessive or word.lower() in NO_POSSESSIVE:
                continue
        spans.append(m.span())
    return spans


def main() -> int:
    entries = []
    for g in (1, 2):
        entries += json.loads((VOCAB / f"grade{g}.json").read_text(encoding="utf-8"))
    by_grade = collections.Counter(e["grade"] for e in entries)
    ids = [e["id"] for e in entries]
    words = collections.Counter(e["word"].lower() for e in entries)

    checks = []

    def check(name, ok, detail=""):
        checks.append((name, ok, detail))

    check("Grade 1 has exactly 339 entries", by_grade[1] == EXPECTED[1], f"found {by_grade[1]}")
    check("Grade 2 has exactly 826 entries", by_grade[2] == EXPECTED[2], f"found {by_grade[2]}")
    check("Total is exactly 1,165 entries", len(entries) == 1165, f"found {len(entries)}")
    empty = [e["id"] for e in entries if not all(str(e.get(k, "")).strip() for k in ("word", "meaning", "example"))]
    check("Every entry has a word, meaning and example", not empty, ", ".join(empty) or "none missing")
    dup_ids = [i for i, c in collections.Counter(ids).items() if c > 1]
    check("Every id is unique", not dup_ids, ", ".join(dup_ids) or "all unique")
    bad_ids = [e["id"] for e in entries if e["id"] != f"g{e['grade']}_{e['order']:04d}"]
    check("Ids follow g<grade>_<order> format", not bad_ids, ", ".join(bad_ids[:10]) or "all match")
    order_ok = all(
        [e["order"] for e in entries if e["grade"] == g] == list(range(1, by_grade[g] + 1)) for g in (1, 2)
    )
    check("Original order preserved (1..N in each grade, no gaps)", order_ok)
    dup_words = sorted(w for w, c in words.items() if c > 1)
    check("No duplicate words", not dup_words, ", ".join(dup_words) or "none")
    trimmed = [e["id"] for e in entries if any(str(e[k]) != str(e[k]).strip() for k in ("word", "meaning", "example"))]
    check("No stray leading/trailing spaces", not trimmed, ", ".join(trimmed) or "clean")

    missing_word = [e for e in entries if not find_word(e["word"], e["example"])]
    repeated = [e for e in entries if len(find_word(e["word"], e["example"])) > 1]
    vocab_words = set(words)
    homophone_hits = [g for g in HOMOPHONES if sum(1 for w in g if w.lower() in vocab_words) >= 2]
    contractions = [e["word"] for e in entries if "'" in e["word"]]

    failed = [c for c in checks if not c[1]]
    lines = [
        "# Vocabulary Validation Report",
        "",
        "Source: `latest_Vocab_Meanings_Grade1_Grade2.pdf` (My Word Book, 63 pages), extracted with "
        "`tool/extract_pdf.py` into `assets/vocabulary/grade1.json` and `grade2.json`.",
        "",
        f"**Result: {'PASS' if not failed else 'FAIL'}** ({len(checks) - len(failed)}/{len(checks)} checks passed)",
        "",
        "| Check | Result | Detail |",
        "|---|---|---|",
    ]
    for name, ok, detail in checks:
        lines.append(f"| {name} | {'✅ Pass' if ok else '❌ Fail'} | {detail} |")
    lines += [
        "",
        "## Summary",
        "",
        f"- Grade 1 entries: {by_grade[1]}",
        f"- Grade 2 entries: {by_grade[2]}",
        f"- Total entries: {len(entries)}",
        f"- Contractions kept exactly as written ({len(contractions)}): {', '.join(contractions)}",
        f"- Fill-in-the-blank questions possible: {len(entries) - len(missing_word)} of {len(entries)} "
        f"({len(missing_word)} flagged, see `VOCABULARY_REVIEW_FLAGS.md`)",
        "",
        "Meanings and example sentences were copied exactly from the PDF. Nothing was rewritten.",
    ]
    (DOCS / "VOCABULARY_VALIDATION_REPORT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    flags = [
        "# Vocabulary Review Flags",
        "",
        "These entries were **not changed**. They need a parent's decision. "
        "To approve a fix, edit the entry in `assets/vocabulary/grade1.json` or `grade2.json` and "
        "run `python3 tool/validate_vocabulary.py` again.",
        "",
        f"## 1. Example sentence does not contain the exact word ({len(missing_word)})",
        "",
        "The fill-in-the-blank engine only blanks the exact word, so these are **left out of "
        "Fill in the Blanks** until approved. All other activities use them normally.",
        "",
        "| Id | Word | Example in PDF | Suggested replacement (needs approval) |",
        "|---|---|---|---|",
    ]
    for e in missing_word:
        flags.append(f"| {e['id']} | {e['word']} | {e['example']} | {SUGGESTED.get(e['word'], '—')} |")
    flags += [
        "",
        f"## 2. Word appears more than once in its example ({len(repeated)})",
        "",
        "Handled automatically: every occurrence becomes a blank and the child answers once.",
        "",
        "| Id | Word | Example |",
        "|---|---|---|",
    ]
    for e in repeated:
        flags.append(f"| {e['id']} | {e['word']} | {e['example']} |")
    flags += [
        "",
        f"## 3. Words that sound like another word in the list ({len(homophone_hits)} groups)",
        "",
        "Handled automatically: listening activities read the example sentence for context and "
        "never offer a sound-alike word as a wrong choice.",
        "",
    ]
    for g in homophone_hits:
        flags.append("- " + " / ".join(w for w in g if w.lower() in vocab_words))
    (DOCS / "VOCABULARY_REVIEW_FLAGS.md").write_text("\n".join(flags) + "\n", encoding="utf-8")

    for name, ok, detail in checks:
        print(("PASS " if ok else "FAIL ") + name + (f" ({detail})" if detail else ""))
    print(f"Flagged for review: {len(missing_word)} examples without the exact word")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

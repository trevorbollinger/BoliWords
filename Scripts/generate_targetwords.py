#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


MIN_SUBWORDS = 3
MIN_SUBWORDS_BY_LENGTH = {
    4: 6,
    5: 8,
    6: 10,
}
WORDLIST_PATH = Path("BoliWords/Resources/wordlist.txt")
TARGETWORDS_PATH = Path("BoliWords/Resources/targetwords.txt")


@dataclass(frozen=True)
class WordInfo:
    word: str
    mask: int
    counts: tuple[int, ...]
    length: int

    @classmethod
    def from_word(cls, word: str) -> "WordInfo":
        mask = 0
        counts = [0] * 26
        for char in word.lower():
            code = ord(char) - 97
            if 0 <= code < 26:
                mask |= 1 << code
                counts[code] += 1
        return cls(word=word, mask=mask, counts=tuple(counts), length=len(word))

    def can_form(self, other: "WordInfo") -> bool:
        return all(other_count <= self_count for self_count, other_count in zip(self.counts, other.counts))


def load_words(path: Path) -> list[str]:
    return [
        line.strip().lower()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def build_target_words(words: list[str]) -> list[str]:
    infos = [WordInfo.from_word(word) for word in words]
    sorted_infos = sorted(infos, key=lambda info: info.length)
    seen_anagram_sets: set[str] = set()
    target_words: list[str] = []

    for info in infos:
        signature = "".join(sorted(info.word))
        if signature in seen_anagram_sets:
            continue

        subword_count = 0
        target_mask = info.mask
        min_subwords = MIN_SUBWORDS_BY_LENGTH.get(info.length, MIN_SUBWORDS)

        for candidate in sorted_infos:
            if candidate.length > info.length:
                break
            if (candidate.mask & ~target_mask) != 0:
                continue
            if info.can_form(candidate):
                subword_count += 1
                if subword_count >= min_subwords:
                    break

        if subword_count >= min_subwords:
            target_words.append(info.word)
            seen_anagram_sets.add(signature)

    return target_words


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    wordlist_path = repo_root / WORDLIST_PATH
    targetwords_path = repo_root / TARGETWORDS_PATH

    words = load_words(wordlist_path)
    target_words = build_target_words(words)
    targetwords_path.write_text("\n".join(target_words) + "\n", encoding="utf-8")

    print(f"Loaded {len(words)} words")
    print(f"Wrote {len(target_words)} target words to {targetwords_path}")


if __name__ == "__main__":
    main()

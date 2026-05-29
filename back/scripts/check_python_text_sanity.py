from __future__ import annotations

import re
import sys
from pathlib import Path

SUSPICIOUS_TEXT_PATTERNS = (
    "\ufffd",
    "紐",
    "怨",
    "섏",
    "몄",
    "寃",
    "쒖",
    "곗",
    "移댄",
    "由щ",
)

COMMENT_OR_DOCSTRING_RE = re.compile(r'^\s*#|"""|\'\'\'')


def main(argv: list[str]) -> int:
    failed = False
    for raw_path in argv[1:]:
        path = Path(raw_path)
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            print(f"{path}: not valid UTF-8")
            failed = True
            continue

        for line_number, line in enumerate(content.splitlines(), start=1):
            if not COMMENT_OR_DOCSTRING_RE.search(line):
                continue
            if any(pattern in line for pattern in SUSPICIOUS_TEXT_PATTERNS):
                print(f"{path}:{line_number}: suspicious mojibake in comment/docstring")
                failed = True

    if failed:
        print("Refusing commit until broken text is fixed.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

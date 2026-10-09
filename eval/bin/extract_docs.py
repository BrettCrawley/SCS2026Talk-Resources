#!/usr/bin/env python3
"""Recover markdown documents from a run's response text.

Used when a model answered with the documents instead of writing them to disk.
Splits the response on top-level headings and writes one file per document.

Usage: extract_docs.py <result.json> <dest_dir>
Prints the number of documents written.
"""

import json
import re
import sys
from pathlib import Path


def load_result_text(path):
    raw = Path(path).read_text().strip()
    if not raw:
        return ""
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = {}
        for line in raw.splitlines():
            try:
                obj = json.loads(line)
            except Exception:
                continue
            if isinstance(obj, dict) and obj.get("type") == "result":
                data = obj
    return str(data.get("result", "") or "")


def slug(title, fallback):
    s = re.sub(r"[^a-z0-9]+", "_", title.lower()).strip("_")
    return (s or fallback)[:60]


def main():
    text = load_result_text(sys.argv[1])
    dest = Path(sys.argv[2])

    if len(text) < 500:
        print(0)
        return

    # Split on level-1 headings. Anything before the first is a preamble.
    parts = re.split(r"^# +(.+)$", text, flags=re.MULTILINE)
    written = 0

    if len(parts) < 3:
        # No document headings. This is prose about the task, not the documents:
        # typically a model describing what it is going to do, or claiming to
        # have dispatched work. Keep it as evidence, underscore-prefixed so it
        # is not mistaken for a deliverable, and report nothing recovered.
        dest.mkdir(parents=True, exist_ok=True)
        (dest / "_response_not_documents.txt").write_text(text)
        print(0)
        return

    dest.mkdir(parents=True, exist_ok=True)
    for i in range(1, len(parts) - 1, 2):
        title, body = parts[i].strip(), parts[i + 1]
        if len(body.strip()) < 200:      # a heading with no real content
            continue
        written += 1
        name = f"{written:02d}_{slug(title, f'document_{written}')}.md"
        (dest / name).write_text(f"# {title}\n{body}")

    print(written)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Convert simple plain text into Atlassian Document Format."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


HEADING_RE = re.compile(r"^(#{1,6})\s+(.*\S)\s*$")
UNORDERED_RE = re.compile(r"^[-*]\s+(.*\S)\s*$")
ORDERED_RE = re.compile(r"^\d+\.\s+(.*\S)\s*$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert simple plain text into block-structured Jira ADF JSON."
    )
    parser.add_argument(
        "path",
        nargs="?",
        help="Input text file. Reads stdin if omitted.",
    )
    parser.add_argument(
        "--indent",
        type=int,
        default=2,
        help="JSON indentation level (default: 2).",
    )
    return parser.parse_args()


def read_input(path: str | None) -> str:
    if path is None:
        return sys.stdin.read()
    return Path(path).read_text()


def split_blocks(text: str) -> list[list[str]]:
    lines = [raw_line.rstrip() for raw_line in text.replace("\r\n", "\n").split("\n")]
    blocks: list[list[str]] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue

        if HEADING_RE.match(line):
            blocks.append([line])
            index += 1
            continue

        if UNORDERED_RE.match(line):
            items: list[str] = []
            while index < len(lines) and UNORDERED_RE.match(lines[index] or ""):
                items.append(lines[index])
                index += 1
            blocks.append(items)
            continue

        if ORDERED_RE.match(line):
            items = []
            while index < len(lines) and ORDERED_RE.match(lines[index] or ""):
                items.append(lines[index])
                index += 1
            blocks.append(items)
            continue

        paragraph_lines: list[str] = []
        while index < len(lines):
            current = lines[index]
            if not current.strip():
                index += 1
                break
            if current != line and (
                HEADING_RE.match(current) or UNORDERED_RE.match(current) or ORDERED_RE.match(current)
            ):
                break
            paragraph_lines.append(current)
            index += 1
        blocks.append(paragraph_lines)

    return blocks


def text_with_breaks(lines: list[str]) -> list[dict]:
    content: list[dict] = []
    for index, line in enumerate(lines):
        content.append({"type": "text", "text": line})
        if index != len(lines) - 1:
            content.append({"type": "hardBreak"})
    return content


def paragraph_block(lines: list[str]) -> dict:
    return {"type": "paragraph", "content": text_with_breaks(lines)}


def heading_block(level: int, text: str) -> dict:
    return {
        "type": "heading",
        "attrs": {"level": level},
        "content": [{"type": "text", "text": text}],
    }


def list_block(lines: list[str], ordered: bool) -> dict:
    items: list[dict] = []
    pattern = ORDERED_RE if ordered else UNORDERED_RE
    for line in lines:
        match = pattern.match(line)
        assert match is not None
        items.append(
            {
                "type": "listItem",
                "content": [
                    {
                        "type": "paragraph",
                        "content": [{"type": "text", "text": match.group(1)}],
                    }
                ],
            }
        )
    return {
        "type": "orderedList" if ordered else "bulletList",
        "content": items,
    }


def block_to_adf(lines: list[str]) -> dict:
    if len(lines) == 1:
        heading_match = HEADING_RE.match(lines[0])
        if heading_match is not None:
            return heading_block(level=len(heading_match.group(1)), text=heading_match.group(2))
    if all(UNORDERED_RE.match(line) for line in lines):
        return list_block(lines=lines, ordered=False)
    if all(ORDERED_RE.match(line) for line in lines):
        return list_block(lines=lines, ordered=True)
    return paragraph_block(lines)


def build_adf(text: str) -> dict:
    blocks = [block_to_adf(lines) for lines in split_blocks(text)]
    return {"type": "doc", "version": 1, "content": blocks}


def main() -> int:
    args = parse_args()
    adf = build_adf(read_input(args.path))
    print(json.dumps(adf, indent=args.indent))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

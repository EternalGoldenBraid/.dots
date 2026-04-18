#!/usr/bin/env python3
"""
extract-graph-spec.py — Convert a .drawio diagram page into a lean agent brief.

This script intentionally emits only agent-facing structure:

- titled sections derived from containers / swimlanes
- section items derived from semantic nodes
- standalone notes
- explicit relationships derived from edges

Usage:
    python scripts/extract-graph-spec.py diagram.drawio
    python scripts/extract-graph-spec.py diagram.drawio --diagram-name "Page-1"
    python scripts/extract-graph-spec.py diagram.drawio --output graph.yaml
"""
from __future__ import annotations

import argparse
import html
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any


BR_RE = re.compile(r"<br\s*/?>", re.IGNORECASE)
TAG_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"\s+")


def _style_has(style: str, token: str) -> bool:
    return style.startswith(token) or f";{token}" in style


def _classify_vertex(style: str) -> str:
    if _style_has(style, "text;"):
        return "text"
    if _style_has(style, "swimlane;"):
        return "container"
    if "shape=note" in style:
        return "note"
    return "node"


def _label_text(raw: str | None) -> str:
    if not raw:
        return ""
    text = BR_RE.sub(" | ", raw)
    text = TAG_RE.sub("", text)
    text = html.unescape(text)
    text = WS_RE.sub(" ", text).strip()
    return text


def _geometry(cell: ET.Element) -> dict[str, float]:
    geom = cell.find("mxGeometry")
    if geom is None:
        return {}

    result: dict[str, float] = {}
    for key in ("x", "y", "width", "height"):
        value = geom.get(key)
        if value is None:
            continue
        try:
            result[key] = float(value)
        except ValueError:
            continue
    return result


def _is_title_cell(cell: ET.Element) -> bool:
    return cell.get("vertex") == "1" and "fontSize=18" in (cell.get("style") or "")


def _sort_key(item: dict[str, Any]) -> tuple[float, float, str]:
    geometry = item.get("_sort_geometry", {})
    return (
        geometry.get("y", 0.0),
        geometry.get("x", 0.0),
        item.get("label", ""),
    )


def _yaml_scalar(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(str(value), ensure_ascii=False)


def _yaml_lines(value: Any, indent: int = 0) -> list[str]:
    prefix = " " * indent
    if isinstance(value, dict):
        if not value:
            return [prefix + "{}"]
        lines: list[str] = []
        for key, item in value.items():
            if isinstance(item, (dict, list)):
                lines.append(f"{prefix}{key}:")
                lines.extend(_yaml_lines(item, indent + 2))
            else:
                lines.append(f"{prefix}{key}: {_yaml_scalar(item)}")
        return lines
    if isinstance(value, list):
        if not value:
            return [prefix + "[]"]
        lines = []
        for item in value:
            if isinstance(item, (dict, list)):
                lines.append(f"{prefix}-")
                lines.extend(_yaml_lines(item, indent + 2))
            else:
                lines.append(f"{prefix}- {_yaml_scalar(item)}")
        return lines
    return [prefix + _yaml_scalar(value)]


def _select_diagram(root: ET.Element, diagram_name: str | None, diagram_index: int | None) -> ET.Element:
    diagrams = root.findall("diagram")
    if not diagrams:
        raise ValueError("No <diagram> elements found.")

    if diagram_name is not None:
        for diagram in diagrams:
            if diagram.get("name") == diagram_name:
                return diagram
        raise ValueError(f"Diagram named '{diagram_name}' not found.")

    if diagram_index is not None:
        if diagram_index < 0 or diagram_index >= len(diagrams):
            raise ValueError(
                f"Diagram index {diagram_index} is out of range for {len(diagrams)} page(s)."
            )
        return diagrams[diagram_index]

    return diagrams[0]


def extract_diagram(path: Path, diagram_name: str | None, diagram_index: int | None) -> dict[str, Any]:
    tree = ET.parse(path)
    root = tree.getroot()
    if root.tag != "mxfile":
        raise ValueError(f"Root element must be <mxfile>, got <{root.tag}>")

    selected = _select_diagram(root, diagram_name, diagram_index)
    graph_model = selected.find("mxGraphModel")
    if graph_model is None:
        raise ValueError("Compressed diagrams are not supported: mxGraphModel missing.")
    root_elem = graph_model.find("root")
    if root_elem is None:
        raise ValueError("mxGraphModel is missing a <root> element.")

    all_cells = root_elem.findall("mxCell")
    cells_by_id = {cell.get("id"): cell for cell in all_cells if cell.get("id")}

    title = selected.get("name", "")
    containers: list[dict[str, Any]] = []
    semantic_cells: list[dict[str, Any]] = []
    notes: list[dict[str, Any]] = []

    for cell in all_cells:
        cid = cell.get("id")
        if cid in {None, "0", "1"}:
            continue
        if cell.get("edge") == "1":
            continue
        if cell.get("vertex") != "1":
            continue

        style = cell.get("style") or ""
        label = _label_text(cell.get("value"))
        if not label:
            continue

        if _is_title_cell(cell):
            title = label
            continue

        kind = _classify_vertex(style)
        if kind == "text":
            continue

        parent_id = cell.get("parent")
        parent_cell = cells_by_id.get(parent_id or "")
        parent_label = _label_text(parent_cell.get("value")) if parent_cell is not None else ""
        entry = {
            "id": cid,
            "label": label,
            "kind": kind,
            "parent": parent_id if parent_id not in {"0", "1"} else None,
            "parent_label": parent_label or None,
            "_sort_geometry": _geometry(cell),
        }

        if kind == "container":
            containers.append(entry)
        elif kind == "note":
            notes.append(entry)
        else:
            semantic_cells.append(entry)

    containers.sort(key=_sort_key)
    semantic_cells.sort(key=_sort_key)
    notes.sort(key=_sort_key)

    known_labels = {item["id"]: item["label"] for item in [*containers, *semantic_cells, *notes]}
    relationships: list[str] = []
    for cell in all_cells:
        if cell.get("edge") != "1":
            continue
        source = cell.get("source")
        target = cell.get("target")
        if not source or not target:
            continue
        if source not in known_labels or target not in known_labels:
            continue
        edge_label = _label_text(cell.get("value"))
        arrow = f" --{edge_label}--> " if edge_label else " --> "
        relationships.append(f"{known_labels[source]}{arrow}{known_labels[target]}")

    sections = []
    for container in containers:
        items = [
            item["label"]
            for item in semantic_cells
            if item.get("parent") == container["id"] and item["label"]
        ]
        if items:
            sections.append({"name": container["label"], "items": items})

    root_level_items = [
        item["label"]
        for item in semantic_cells
        if item.get("parent") is None and item["label"]
    ]
    if root_level_items:
        sections.append({"name": "Ungrouped", "items": root_level_items})

    note_labels = [item["label"] for item in notes if item["label"]]

    return {
        "version": 1,
        "source": {
            "diagram_name": selected.get("name"),
            "title": title,
        },
        "agent_brief": {
            "sections": sections,
            "notes": note_labels,
            "relationships": relationships,
        },
    }


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract a lean agent-facing graph brief from a draw.io diagram page."
    )
    parser.add_argument("diagram", help="Path to the .drawio file")
    parser.add_argument(
        "--diagram-name",
        help="Diagram page name to extract (preferred over --diagram-index)",
    )
    parser.add_argument(
        "--diagram-index",
        type=int,
        help="0-based diagram page index to extract",
    )
    parser.add_argument(
        "--format",
        choices=("yaml", "json"),
        default="yaml",
        help="Output format (default: yaml)",
    )
    parser.add_argument(
        "--output",
        help="Optional output file path; prints to stdout when omitted",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    path = Path(args.diagram)
    if not path.exists():
        print(f"ERROR: File not found: {path}")
        return 1
    if not path.is_file():
        print(f"ERROR: Not a file: {path}")
        return 1

    try:
        extracted = extract_diagram(
            path=path,
            diagram_name=args.diagram_name,
            diagram_index=args.diagram_index,
        )
    except (ET.ParseError, ValueError) as exc:
        print(f"ERROR: {exc}")
        return 1

    if args.format == "json":
        content = json.dumps(extracted, indent=2, ensure_ascii=False) + "\n"
    else:
        content = "\n".join(_yaml_lines(extracted)) + "\n"

    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content, encoding="utf-8")
        print(f"Wrote graph spec to {output_path}")
    else:
        sys.stdout.write(content)

    return 0


if __name__ == "__main__":
    sys.exit(main())

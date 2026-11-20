#!/usr/bin/env python3
"""Comprehensive static validator for Frontier Command (Godot 4.3 project).
Checks JSON syntax/schemas, res:// references, .tscn structure, unique class_name declarations,
architecture dependency boundaries, Godot 3 deprecated APIs, balanced delimiters, and unresolved TODOs."""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FORBIDDEN_IN_HEADLESS = [
    "Node2D", "Control", "CanvasItem", "CanvasLayer", "Camera2D",
    "AudioStreamPlayer", "Sprite2D", "Button", "Label",
    "res://src/view", "res://src/ui", "res://scenes",
]

GODOT3_DEPRECATED = [
    r"\bKinematicBody2D\b",
    r"\byield\s*\(",
    r"\.instance\s*\(",
    r"\brand_range\s*\(",
    r"\bSpatial\b",
    r"\bPoolVector2Array\b",
]


def check_delimiters(text: str, rel: str) -> list:
    errs = []
    pairs = {"(": ")", "[": "]", "{": "}"}
    closing = {")": "(", "]": "[", "}": "{"}
    stack = []
    in_str = None
    escaped = False
    for ln, line in enumerate(text.splitlines(), 1):
        for ch in line:
            if in_str:
                if escaped:
                    escaped = False
                elif ch == "\\":
                    escaped = True
                elif ch == in_str:
                    in_str = None
                continue
            if ch == "#":
                break
            if ch in ('"', "'"):
                in_str = ch
            elif ch in pairs:
                stack.append((ch, ln))
            elif ch in closing:
                if not stack or stack[-1][0] != closing[ch]:
                    errs.append(f"Unmatched '{ch}' in {rel}:{ln}")
                else:
                    stack.pop()
    for ch, ln in stack:
        errs.append(f"Unclosed '{ch}' in {rel}:{ln}")
    return errs


def main() -> int:
    errors = []
    warnings = []
    stats = {"gd_files": 0, "tscn_files": 0, "json_files": 0, "res_refs_checked": 0}

    # 1. Validate project.godot
    proj = ROOT / "project.godot"
    if not proj.exists():
        errors.append("Missing project.godot")
    else:
        txt = proj.read_text(encoding="utf-8")
        if "config_version=5" not in txt:
            errors.append("project.godot missing config_version=5")
        for m in re.finditer(r'res://([^"\s]+)', txt):
            stats["res_refs_checked"] += 1
            if not (ROOT / m.group(1)).exists():
                errors.append(f"project.godot broken res:// ref: res://{m.group(1)}")

    # 2. Validate JSON files & map schemas
    for jp in sorted(ROOT.rglob("*.json")):
        stats["json_files"] += 1
        try:
            data = json.loads(jp.read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"Invalid JSON in {jp.relative_to(ROOT)}: {exc}")
            continue
        if jp.parent.name == "maps":
            for k in ["map_id", "display_name", "buildings", "camera"]:
                if k not in data:
                    errors.append(f"Map {jp.name} missing key: {k}")
            ids = [b.get("id") for b in data.get("buildings", [])]
            if len(ids) != len(set(ids)):
                errors.append(f"Map {jp.name} has duplicate building IDs")
            if not any(b.get("owner_id") == 1 for b in data.get("buildings", [])):
                errors.append(f"Map {jp.name} has no player starting building")

    # 3. Validate GDScript files
    seen_classes = {}
    for gd in sorted(ROOT.rglob("*.gd")):
        stats["gd_files"] += 1
        rel = str(gd.relative_to(ROOT))
        text = gd.read_text(encoding="utf-8")
        lines = text.splitlines()

        errors.extend(check_delimiters(text, rel))

        for ln, line in enumerate(lines, 1):
            m = re.match(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", line)
            if m:
                cname = m.group(1)
                if cname in seen_classes:
                    errors.append(f"Duplicate class_name {cname}: {rel}:{ln} and {seen_classes[cname]}")
                seen_classes[cname] = f"{rel}:{ln}"

            if "TODO" in line or "FIXME" in line:
                warnings.append(f"Unresolved TODO/FIXME in {rel}:{ln}")

            for pat in GODOT3_DEPRECATED:
                if re.search(pat, line):
                    errors.append(f"Godot 3 deprecated API ({pat}) in {rel}:{ln}")

        for m in re.finditer(r"res://([A-Za-z0-9_./-]+)", text):
            ref = m.group(1).rstrip("/")
            stats["res_refs_checked"] += 1
            if not (ROOT / ref).exists():
                errors.append(f"Broken res:// reference in {rel}: res://{ref}")

        if rel.startswith(("src/core/", "src/sim/", "src/ai/", "src/map/")):
            for forbidden in FORBIDDEN_IN_HEADLESS:
                if re.search(rf"\b{re.escape(forbidden)}\b", text):
                    errors.append(f"Architecture boundary violation in {rel}: references {forbidden}")

    # 4. Validate .tscn files
    for sc in sorted(ROOT.rglob("*.tscn")):
        stats["tscn_files"] += 1
        rel = str(sc.relative_to(ROOT))
        text = sc.read_text(encoding="utf-8")
        if not text.startswith("[gd_scene "):
            errors.append(f"{rel} does not start with [gd_scene")
        ext_ids = set(re.findall(r'id="([^"]+)"', text))
        for m in re.finditer(r'path="res://([^"]+)"', text):
            stats["res_refs_checked"] += 1
            if not (ROOT / m.group(1)).exists():
                errors.append(f"Broken scene resource in {rel}: res://{m.group(1)}")
        for m in re.finditer(r'ExtResource\("([^"]+)"\)', text):
            if m.group(1) not in ext_ids:
                errors.append(f"Missing ExtResource id {m.group(1)} in {rel}")

    print("=== Frontier Command Static Validation Report ===")
    print(f"Checked: {stats['gd_files']} .gd, {stats['tscn_files']} .tscn, {stats['json_files']} .json, {stats['res_refs_checked']} res:// refs")
    print(f"Unique class_name declarations: {len(seen_classes)}")
    print(f"Errors: {len(errors)} | Warnings: {len(warnings)}")
    for e in errors:
        print("  [ERROR]", e)
    for w in warnings:
        print("  [WARN]", w)
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())

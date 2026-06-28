#!/usr/bin/env python3
from __future__ import annotations
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_PATTERNS = [r"(?<!不)保證讀心", r"一秒看穿", r"百分之百安全", r"一定有效", r"保證成功"]
errors = []
warnings = []

manifest = json.loads((ROOT / "data/apps_manifest.json").read_text(encoding="utf-8"))
if len(manifest.get("apps", [])) != 8:
    errors.append("apps_manifest must contain 8 apps")

all_ids = set()
for app in manifest["apps"]:
    slug = app["slug"]
    base = ROOT / "data/apps" / slug
    required = ["manifest.json", "categories.json", "diagrams.json", "videos.json", "social_videos.json", "store_metadata.json", "ui_copy.json"]
    for fn in required:
        if not (base / fn).exists(): errors.append(f"{slug}: missing {fn}")
    diagrams = json.loads((base / "diagrams.json").read_text(encoding="utf-8"))
    videos = json.loads((base / "videos.json").read_text(encoding="utf-8"))
    social = json.loads((base / "social_videos.json").read_text(encoding="utf-8"))
    store = json.loads((base / "store_metadata.json").read_text(encoding="utf-8"))
    if len(diagrams) != 200: errors.append(f"{slug}: diagrams={len(diagrams)}")
    if sum(d.get("accessLevel") == "free" for d in diagrams) != 20: errors.append(f"{slug}: free diagrams count")
    if sum(d.get("accessLevel") == "pro" for d in diagrams) != 180: errors.append(f"{slug}: pro diagrams count")
    if len(videos) != 20: errors.append(f"{slug}: videos={len(videos)}")
    if sum(v.get("accessLevel") == "free" for v in videos) != 3: errors.append(f"{slug}: free videos count")
    if len(social) != 10: errors.append(f"{slug}: social videos={len(social)}")
    for v in videos:
        if v.get("title", "") not in v.get("learningObjective", ""):
            errors.append(f"{v.get('id')}: learning objective is not anchored to video title")
        for scene in v.get("storyboard", []):
            if v.get("title", "") not in scene.get("framePromptZh", ""):
                errors.append(f"{v.get('id')}: frame prompt is not anchored to video title")
    titles = [d["title"] for d in diagrams]
    if len(titles) != len(set(titles)): errors.append(f"{slug}: duplicate diagram titles")
    for d in diagrams:
        if d["id"] in all_ids: errors.append(f"duplicate id {d['id']}")
        all_ids.add(d["id"])
        for key in ["answerSummary", "keyPoints", "actionSteps", "diagram", "copy", "search"]:
            if key not in d: errors.append(f"{d.get('id')}: missing {key}")
        text = json.dumps(d, ensure_ascii=False)
        for pattern in FORBIDDEN_PATTERNS:
            if re.search(pattern, text): errors.append(f"{d['id']}: forbidden claim pattern {pattern}")
    if store["lengthChecks"]["subtitleChars"] > 30:
        warnings.append(f"{slug}: subtitle > 30 characters")
    if store["lengthChecks"]["promotionalTextChars"] > 170:
        errors.append(f"{slug}: promotional text > 170 characters")
    if app["contentCounts"]["diagrams"] != len(diagrams): errors.append(f"{slug}: manifest count mismatch")

# Production artifact coverage
import csv
def csv_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return sum(1 for _ in csv.DictReader(f))
prod_expected = {
    "image_generation_queue.csv": 1600,
    "video_scene_queue.csv": 480,
    "social_video_queue.csv": 240,
    "app_store_asset_queue.csv": 112,
    "editorial_review_queue.csv": 1600,
}
for fn, expected in prod_expected.items():
    p = ROOT / "production" / fn
    if not p.exists(): errors.append(f"missing production/{fn}")
    elif csv_rows(p) != expected: errors.append(f"production/{fn}: rows={csv_rows(p)} expected={expected}")
if len(list((ROOT / "production/vtt").glob("*/*.vtt"))) != 160:
    errors.append("production/vtt must contain 160 files")
if len(list((ROOT / "production/voiceover").glob("*/*.txt"))) != 160:
    errors.append("production/voiceover must contain 160 files")

if errors:
    print("CONTENT VALIDATION FAILED")
    for e in errors: print("ERROR:", e)
    for w in warnings: print("WARN:", w)
    sys.exit(1)
print("CONTENT VALIDATION PASSED")
print(f"apps=8 diagrams={8*200} videos={8*20} social_videos={8*10}")
for w in warnings: print("WARN:", w)


# 3D Visual Guide Apps｜Codex Handoff v2.1

Generated: 2026-06-25

This is a repository-ready product, editorial, asset-production, and Codex implementation package. It does not claim the iOS app, illustrations, or final videos have already been produced or submitted.

## Complete planning inventory

- 8 app manifests and materially differentiated feature specs.
- 1,600 diagram records: 200 per app, with 20 Free and 180 Pro.
- Every diagram includes UI copy, summary, key points, actions, alt text, Chinese/English image prompts, negative prompt, motion prompt, asset names, and review status.
- 160 in-app video scripts: 20 per app; 480 storyboard scenes with voiceover, subtitles, frame prompts, motion prompts, and asset names.
- 80 social short-video scripts: 10 per app; 240 timed segments.
- 160 WebVTT subtitle files and 160 voiceover files.
- 8 App Store metadata packages, 64 screenshot scripts, and 8 thirty-second preview timelines.
- UI microcopy, onboarding, paywall, error, empty-state, and accessibility copy.
- Super Grok research/editorial prompts, image prompts, video prompts, copy/ASO/localization prompts.
- JSON schemas, validator, production queues, expanded production books, AGENTS.md, master handoff prompt, and 14 Codex tasks.

## Start here

1. Read `HANDOFF_SUMMARY.md`.
2. Run: `python3 scripts/validate_content.py`
3. Open `CODEX_START_HERE.md`.
4. Give this repository to Codex and paste the master handoff prompt.
5. Start with `codex/tasks/00_repository_audit.md`.
6. Build the love-psychology pilot first.

## Important editorial and asset status

All generated content is `draft-ready-for-review`, not `published`. Travel and survival content require domain-expert review before release. Final image and video assets are not included; the package contains complete production prompts, shot lists, VTT, voiceover, and asset contracts.

## Main folders

- `docs/` product, UX, unique-feature, video, workflow, and safety specs.
- `data/apps/<slug>/` complete per-app machine-readable datasets.
- `prompts/` Super Grok, image, video, ASO, localization, and Codex prompts.
- `production/` CSV queues, VTT, voiceover, and fully expanded production books.
- `schemas/` JSON contracts.
- `codex/tasks/` phased implementation prompts.
- `scripts/` validation and export utilities.
- `reports/` coverage and validation reports.

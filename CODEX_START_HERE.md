# Codex Master Handoff Prompt

Read `AGENTS.md` and all files listed under “Read first”, especially `docs/UNIQUE_FEATURE_FUNCTIONAL_SPECS.md`. Do not start by generating new product copy; this repository already contains the content source of truth.

Your goal is to implement the iOS 17+ SwiftUI MVP with a shared core and materially differentiated feature modules for eight app variants.

Execution order:
1. Run `python3 scripts/validate_content.py` and fix only structural data errors if any.
2. Verify `production/image_generation_queue.csv` has 1,600 rows and `production/video_scene_queue.csv` has 480 scene rows.
3. Inspect the repository and create a concise implementation plan mapped to `codex/tasks/00–13`.
4. Implement one task at a time. After every task, run relevant tests and summarize changed files.
5. Start with the `love-psychology` pilot target. Keep a Debug-only variant switcher for all eight datasets.
6. Do not connect a server, analytics, accounts, or remote CMS in P0.
7. Do not create fake images or videos. Use explicit placeholders bearing a “Placeholder” development label until assets exist.
8. Use the provided StoreKit product IDs and localized `Product.displayPrice`.
9. When requirements conflict, stop and report the conflict instead of silently choosing a risky behavior.

First response should contain:
- repository understanding
- proposed folder/Xcode target structure
- task order
- build/test commands you will use
- blockers, if any

# AGENTS.md

## Mission
Build an iOS 17+ SwiftUI product family for eight materially differentiated 3D visual-guide apps. The repository includes complete planning data, 1,600 diagram records, 160 in-app video scripts, 80 social video scripts, UI copy, and App Store metadata.

## Read first
1. `docs/PRODUCT_PRD.md`
2. `docs/UX_UI_COPY_SPEC.md`
3. `docs/EDITORIAL_SAFETY_POLICY.md`
4. `docs/UNIQUE_FEATURE_FUNCTIONAL_SPECS.md`
5. `docs/CONTENT_PRODUCTION_WORKFLOW.md`
6. `reports/content_coverage.json`
7. `data/apps_manifest.json`
8. The target app's `data/apps/<slug>/manifest.json`

## Non-negotiable rules
- Do not invent or silently rewrite editorial content. Read JSON as the source of truth.
- Do not mark editorial records as published.
- Do not add API keys, credentials, analytics IDs, or private data.
- The MVP must work with bundled local JSON and bundled/local placeholder assets.
- Use StoreKit 2. The displayed purchase price must come from `Product.displayPrice`.
- Provide Restore Purchases.
- Do not expose the Debug app-variant switcher in Release builds.
- Free content must remain accessible without sign-in.
- Every image needs an accessibility label from `diagram.altText`.
- Respect Reduce Motion and Dynamic Type.
- Do not implement claims such as mind reading, guaranteed safety, diagnosis, or guaranteed results.
- App Store screenshots and preview capture only implemented UI.

## Architecture
- SwiftUI + Observation/MVVM where useful.
- Feature folders: AppCore, ContentKit, PurchaseKit, PersistenceKit, MediaKit, AccessibilityKit, VariantFeatures.
- One shared codebase; a release target embeds only one `appSlug` and its assets/data.
- Each app must route to its unique feature views listed in its manifest.

## Verification before finishing a task
- Run `python3 scripts/validate_content.py`.
- Run the relevant Xcode build and tests when Xcode is available.
- Report exact commands, results, changed files, and remaining risks.
- Do not claim a test passed if it was not run.

## Definition of done
- Build succeeds.
- Unit tests pass.
- No placeholder is presented as a completed feature.
- Purchase and restore states are testable with StoreKit configuration.
- Content counts match the manifest.
- UI copy and safety notes are visible in the correct contexts.

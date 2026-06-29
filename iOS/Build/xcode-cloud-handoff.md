# Xcode Cloud Handoff

Required by user: App Store binary must go through Xcode Cloud, not local archive upload.

Project: `VisualGuideFamily.xcodeproj`

Scheme: `LovePsychology`

Bundle ID: `com.jiang.visualguide.lovepsychology`

Workflow target: Archive - iOS, App Store Connect distribution, `APP_STORE_ELIGIBLE`.

ASC App Store ID: `6785267886`

GitHub repo: `https://github.com/kingboss568/love-psychology-illustrated-ios`

Latest pushed commit: `fc2843d`.

ASC status on 2026-06-29:

- App record exists.
- Version `1.0` is `READY_FOR_REVIEW` after adding the App Store version item to review submission `a11a1ea6-4757-4461-a365-2385c810ae3b`.
- Metadata and screenshots are uploaded.
- Primary category is `LIFESTYLE`.
- Age rating declaration is completed.
- App Review detail is created.
- Pro IAP `6785268820` is `READY_TO_SUBMIT`; it still needs to be selected in the version page "In-App Purchases and Subscriptions" section before final submit.
- Existing ASC build `9334dab6-af8a-41ad-8396-959d7bb6b621` is `VALID`, `APP_STORE_ELIGIBLE`, and `usesNonExemptEncryption=false`, but it is not selected into version `1.0` and is not accepted as final because no Xcode Cloud product/run is associated with this App.
- App Privacy data collection is published as no data collected.
- Xcode Cloud product `926f1ab4-637d-403a-92c2-1415f405fc64` was created for `LovePsychology`.
- Workflow `0C943171-1563-4738-9E7A-EAF59ADC9A83` was updated to `Archive - App Store` with `buildDistributionAudience=APP_STORE_ELIGIBLE`.
- Cloud run `e7e77020-74b1-47f7-9e6e-a0eccd14e7b3` / run number `7` completed successfully from commit `fc2843d`.
- Cloud build `45cf97ef-0914-4643-9c7e-76d8b91a9d2e` / build `7` is `VALID`, `APP_STORE_ELIGIBLE`, `expired=false`, and `usesNonExemptEncryption=false`.
- Build `7` is selected into App Store version `1.0`.
- Internal-only Cloud builds `5` and `6` exist from the first default TestFlight workflow and should not be selected for App Store submission.
- Current blocker: ASC browser session expired while trying to select the first IAP into version review. User must sign in to App Store Connect UI, then select IAP `6785268820` on the version page before submitting.

Therefore first Xcode Cloud product/workflow setup must be completed in App Store Connect or Xcode UI after the Mac is unlocked.

Remaining before final submit:

- Sign in to App Store Connect UI.
- Select Pro IAP `6785268820` in the version page "In-App Purchases and Subscriptions" section.
- Submit existing review submission `a11a1ea6-4757-4461-a365-2385c810ae3b` after confirming both app version and IAP are listed.

Local no-sign build passed on Xcode 27.0 build 27A5194q.

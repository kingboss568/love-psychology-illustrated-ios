# Xcode Cloud Handoff

Required by user: App Store binary must go through Xcode Cloud, not local archive upload.

Project: `VisualGuideFamily.xcodeproj`

Scheme: `LovePsychology`

Bundle ID: `com.jiang.visualguide.lovepsychology`

Workflow target: Archive - iOS, App Store Connect distribution, `APP_STORE_ELIGIBLE`.

ASC App Store ID: `6785267886`

GitHub repo: `https://github.com/kingboss568/love-psychology-illustrated-ios`

Latest pushed commit: `186a5f3` plus post-ASC status update commit pending at handoff time.

ASC status on 2026-06-29:

- App record exists.
- Version `1.0` is `PREPARE_FOR_SUBMISSION`.
- Metadata and screenshots are uploaded.
- Primary category is `LIFESTYLE`.
- Age rating declaration is completed.
- App Review detail is created.
- Pro IAP `6785268820` is `READY_TO_SUBMIT`.
- Existing ASC build `9334dab6-af8a-41ad-8396-959d7bb6b621` is `VALID`, `APP_STORE_ELIGIBLE`, and `usesNonExemptEncryption=false`, but it is not selected into version `1.0` and is not accepted as final because no Xcode Cloud product/run is associated with this App.
- App Privacy data collection is still not published; the public Connect API does not support creating the `DATA_NOT_COLLECTED` record, and the Iris endpoint requires authenticated browser cookies.
- App Store Connect API rejected `POST /v1/ciProducts` with: resource `ciProducts` does not allow `CREATE`; allowed operations are `DELETE`, `GET_COLLECTION`, `GET_INSTANCE`.

Therefore first Xcode Cloud product/workflow setup must be completed in App Store Connect or Xcode UI after the Mac is unlocked.

Before first Cloud run:

- Confirm repo remote exists and is pushed.
- Confirm shared scheme is committed.
- Confirm ASC app record exists.
- Confirm Xcode Cloud product/workflow exists or complete onboarding from Xcode/ASC UI.
- Set Cloud Next Build Number above any existing ASC build number.

Local no-sign build passed on Xcode 27.0 build 27A5194q.

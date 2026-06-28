# Xcode Cloud Handoff

Required by user: App Store binary must go through Xcode Cloud, not local archive upload.

Project: `VisualGuideFamily.xcodeproj`

Scheme: `LovePsychology`

Bundle ID: `com.jiang.visualguide.lovepsychology`

Workflow target: Archive - iOS, App Store Connect distribution, `APP_STORE_ELIGIBLE`.

Before first Cloud run:

- Confirm repo remote exists and is pushed.
- Confirm shared scheme is committed.
- Confirm ASC app record exists.
- Confirm Xcode Cloud product/workflow exists or complete onboarding from Xcode/ASC UI.
- Set Cloud Next Build Number above any existing ASC build number.

Local no-sign build passed on Xcode 27.0 build 27A5194q.

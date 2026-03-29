# Release Checklist

## Build and signing

- Confirm Xcode is selected with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- Install the project generator dependency once with `gem install --user-install xcodeproj`
- Set the `DEVELOPMENT_TEAM` and `Developer ID Application` identity for the `knook` target
- Generate or refresh `knook.xcodeproj` with `ruby packaging/macos/generate-xcodeproj.rb`
- Signed release path:
  - Archive and export the app with `packaging/macos/release.sh <version>`
  - Notarize the DMG build
  - Staple the notarization ticket
- Unsigned preview path:
  - Build and package with `KNOOK_UNSIGNED_PREVIEW=1 packaging/macos/release.sh <version>`
  - Document the first-launch Gatekeeper workaround in the release notes and cask caveats

## Functional QA

- Menu bar icon updates when a break starts
- Reminder panel appears before the next break
- Break overlay shows the configured message, sound, and background
- Skip, postpone, early end, and manual pause behave as expected
- Launch at login can be toggled on and off
- Office hours suppress reminders outside the configured window
- Idle reset starts a fresh timer after stepping away

## Distribution

- Attach screenshots to the GitHub release notes
- Publish the `knook-<version>.dmg`
- Update `packaging/homebrew/Casks/knook.rb` with the new version and SHA
- Copy the cask into `preetsuthar17/homebrew-tap`

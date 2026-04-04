# Release Checklist

## One-time setup

- Confirm Xcode is selected with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- Install the project generator dependency once with `gem install --user-install xcodeproj`
- Store notarization credentials in the keychain (once per machine):
  ```bash
  xcrun notarytool store-credentials knook-notary \
    --apple-id <your-apple-id-email> \
    --team-id BDT655MGNN \
    --password <app-specific-password>
  ```
  Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Passwords.

## Build and signing

- For testing update prompts across versions, keep the repo default on the newer release version and build the older local app with `KNOOK_MARKETING_VERSION=<older-version> packaging/macos/release.sh <older-version>`
- Signed + notarized release (default):
  - Run `packaging/macos/release.sh <version>`
  - The script archives, exports, signs the DMG, submits for notarization, and staples the ticket automatically
- Unsigned preview path:
  - Build and package with `KNOOK_UNSIGNED_PREVIEW=1 packaging/macos/release.sh <version>`
  - Document the first-launch Gatekeeper workaround in the release notes

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

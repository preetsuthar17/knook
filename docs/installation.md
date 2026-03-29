# Installation

## Summary

`knook` supports direct installs from GitHub releases and Homebrew installs from `preetsuthar17/tap`. knook checks the latest GitHub release and prefers Homebrew for guided upgrades.

## Requirements

- macOS 13 or newer
- permission to install apps into `/Applications`

## Install

1. Open the latest release: [GitHub Releases](https://github.com/preetsuthar17/knook/releases/latest)
2. Download the latest DMG
3. Move `knook.app` into `/Applications`
4. Launch `knook` once from `/Applications`

## In-App Updates

knook checks the latest GitHub release automatically and shows an update banner in the menu bar popover when a newer version is available.

Use the `Update` button in the popover to open a Homebrew upgrade command in Terminal:

```bash
brew tap preetsuthar17/tap && brew update && (brew upgrade --cask knook || brew install --cask knook)
```

If Homebrew is not available, the same button opens the GitHub release page instead.

## Optional Homebrew Install

Homebrew remains the preferred package-manager distribution path:

```bash
brew tap preetsuthar17/tap
brew install --cask knook
```

## Package Upgrade Guide

If `knook` was installed with Homebrew, use the package manager to upgrade it:

```bash
brew update
brew upgrade --cask knook
```

If you want to force Homebrew to reinstall the currently published version:

```bash
brew reinstall --cask knook
```

To confirm the installed app version:

```bash
defaults read /Applications/knook.app/Contents/Info CFBundleShortVersionString
```

For local updater testing, you can build an older app version from the same repo by overriding the build version at package time:

```bash
KNOOK_MARKETING_VERSION=0.1.1 packaging/macos/release.sh 0.1.1
```

## Update

For direct installs, use the in-app `Update` button from the menu bar popover or reinstall from the latest GitHub release.

For manual Homebrew installs:

```bash
brew update
brew upgrade --cask knook
```

## Troubleshooting

### App does not start after reinstall

Make sure the old app bundle is gone, then reinstall the newest release into `/Applications`.

### I want a clean first-time install

Remove the app and all local settings:

```bash
pkill -x knook 2>/dev/null || true
brew uninstall --cask knook 2>/dev/null || true
rm -rf /Applications/knook.app
rm -rf ~/Library/Application\ Support/knook
rm -rf ~/Library/Application\ Support/nook
rm -rf ~/Library/Application\ Support/Nook
rm -f ~/Library/Preferences/io.github.preetsuthar17.knook.plist
rm -rf ~/Library/Saved\ Application\ State/io.github.preetsuthar17.knook.savedState
```

Then install the newest release again into `/Applications`.

### I want to clear cached Homebrew downloads too

Optional:

```bash
brew cleanup --prune=all
rm -rf ~/Library/Caches/Homebrew/downloads/*knook*
```

## Uninstall

Remove just the app:

```bash
brew uninstall --cask knook 2>/dev/null || true
rm -rf /Applications/knook.app
```

Remove the app and all local settings:

```bash
pkill -x knook 2>/dev/null || true
brew uninstall --cask knook 2>/dev/null || true
rm -rf /Applications/knook.app
rm -rf ~/Library/Application\ Support/knook
rm -rf ~/Library/Application\ Support/nook
rm -rf ~/Library/Application\ Support/Nook
rm -f ~/Library/Preferences/io.github.preetsuthar17.knook.plist
rm -rf ~/Library/Saved\ Application\ State/io.github.preetsuthar17.knook.savedState
```

## Notes

- GitHub Releases are the source of truth for version discovery
- Homebrew is the preferred path for upgrades when it is installed

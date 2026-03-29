# Installation

## Summary

`knook` is currently distributed as a Homebrew Cask preview build.

Install path:

```bash
brew tap preetsuthar17/tap
brew install --cask knook
xattr -dr com.apple.quarantine /Applications/knook.app
open /Applications/knook.app
```

Why the extra `xattr` step:

- the current preview build is not notarized yet
- macOS may quarantine the app after Homebrew install
- removing the quarantine attribute lets the app open normally

## Requirements

- macOS 13 or newer
- Homebrew installed

## Install

Run:

```bash
brew tap preetsuthar17/tap
brew install --cask knook
```

Then clear quarantine and launch:

```bash
xattr -dr com.apple.quarantine /Applications/knook.app
open /Applications/knook.app
```

## Update

To update to the latest preview release:

```bash
brew update
brew upgrade --cask knook
xattr -dr com.apple.quarantine /Applications/knook.app
```

## Troubleshooting

### "knook is damaged and can't be opened"

This is the expected macOS Gatekeeper response for the current unsigned preview build.

Run:

```bash
xattr -dr com.apple.quarantine /Applications/knook.app
open /Applications/knook.app
```

### App does not start after reinstall

Make sure the old app bundle is gone, then reinstall:

```bash
rm -rf /Applications/knook.app
brew reinstall --cask knook
xattr -dr com.apple.quarantine /Applications/knook.app
open /Applications/knook.app
```

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

Then install again:

```bash
brew install --cask knook
xattr -dr com.apple.quarantine /Applications/knook.app
open /Applications/knook.app
```

### I want to clear cached Homebrew downloads too

Optional:

```bash
brew cleanup --prune=all
rm -rf ~/Library/Caches/Homebrew/downloads/*knook*
```

## Uninstall

Remove just the app:

```bash
brew uninstall --cask knook
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

- once `knook` is signed and notarized, the quarantine workaround should go away
- until then, this document is the source of truth for preview installs

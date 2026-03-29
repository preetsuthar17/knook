# Homebrew Tap Template

This directory contains the `knook` cask that should be copied into your custom tap repository.

The cask is ready for an unsigned preview release. Until Apple Developer signing and notarization are configured, macOS will require a manual first-launch confirmation after install.

Recommended tap repository:

- `preetsuthar17/homebrew-tap`

Recommended structure inside that tap:

```text
homebrew-tap/
  Casks/
    knook.rb
```

Typical flow:

```bash
brew tap-new preetsuthar17/homebrew-tap
gh repo create preetsuthar17/homebrew-tap --public --source "$(brew --repository preetsuthar17/homebrew-tap)" --push
cp packaging/homebrew/Casks/knook.rb "$(brew --repository preetsuthar17/homebrew-tap)/Casks/knook.rb"
```

Preview release flow:

```bash
KNOOK_UNSIGNED_PREVIEW=1 packaging/macos/release.sh 0.1.0
gh release create v0.1.0 build/knook-0.1.0.dmg --title "knook 0.1.0" --notes "Unsigned preview release."
```

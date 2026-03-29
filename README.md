# knook

<p align="center">
  <img src="Sources/AppShell/Resources/AppIcon.png" alt="knook" width="128">
</p>

<p align="center">
  <strong>Open-source, privacy-first macOS break reminders for a calmer work rhythm</strong>
</p>

knook is a native menu bar app for macOS that helps you take screen breaks without accounts, subscriptions, or cloud syncing.

> knook is in active development and should be treated as early alpha software. UI details, contributor workflows, and local setup may still change as the app is being hardened.

[Quick Start](#quick-start) · [Install Guide](docs/installation.md) · [What knook is](#what-knook-is) · [Why knook exists](#why-knook-exists) · [What It Feels Like](#what-it-feels-like) · [Current Capabilities](#current-capabilities) · [Repository Map](#repository-map) · [Contributing](#contributing) · [Support](#support)

## What knook is

knook is a native SwiftUI menu bar app for screen-break reminders on macOS.

It keeps track of your break rhythm locally, offers short and long breaks, and adds lightweight context-aware pause behavior so reminders can stay useful without feeling overly disruptive during focused work.

## Why knook exists

Healthy break reminders should be available without a paywall, account system, or opaque syncing model.

knook is being built as a community-owned, privacy-first alternative in this category: small, local-first, and understandable from the inside out.

## What It Feels Like

In day-to-day use, knook is meant to stay quiet until it is helpful:

1. You launch knook and it lives in the menu bar.
2. It keeps time for your next break locally.
3. It gives you a heads-up reminder before the break starts.
4. It shows a full break overlay when it is time to pause.
5. You can postpone, skip, end early, or pause reminders depending on the current state and settings.

The goal is not to create a complicated wellness platform. The goal is to make taking small breaks on macOS feel simple and sustainable.

## Current Capabilities

knook currently provides:

- a native macOS menu bar app in SwiftUI
- a scheduler core in `Core`
- short and long breaks
- heads-up reminder panels
- a break overlay window
- postpone, skip, early end, and manual pause or resume controls
- office hours, idle reset, and launch-at-login wiring
- smart pause for full-screen focus
- versioned local JSON settings

## Quick Start

The fastest install path is the latest GitHub release or the Homebrew cask.

### Direct install

Download the latest release from GitHub, move `knook.app` into `/Applications`, and launch it from there.

### Optional Homebrew install

Install with:

```bash
brew tap preetsuthar17/tap
brew install --cask knook
```

Upgrade later with:

```bash
brew update
brew upgrade --cask knook
```

When a newer GitHub release is published, knook shows an update banner in the menu bar popover. The `Update` button opens a Homebrew upgrade command in Terminal when Homebrew is available and falls back to the GitHub release page otherwise.

### Source build

Requirements:

- macOS 13 or newer
- a current Swift toolchain
- a full Xcode installation for the best local development experience

Build the app:

```bash
swift build
```

Run the app:

```bash
swift run
```

For the full local development workflow, including `swift run knook`, filtered test commands, and launch-time overrides such as `KNOOK_WORK`, `KNOOK_BREAK`, and `KNOOK_FORCE_ONBOARDING`, see [docs/local-development.md](docs/local-development.md).

For a deeper install guide, including troubleshooting, uninstall, and reset steps, see [docs/installation.md](docs/installation.md).

Quick examples:

```bash
swift test
```

```bash
KNOOK_FORCE_ONBOARDING=1 swift run
```

`swift test` currently expects a full Xcode installation in this repository's setup.

## Known Limitations

- source build and developer setup are required today
- screenshots and demo assets are not included in the README yet
- signed and notarized distribution is still being finalized
- the contributor-facing test workflow still needs cleanup

## Repository Map

- `Sources/AppShell/`: macOS app shell, menu bar UI, windows, and app coordination
- `Sources/Core/`: scheduler, models, persistence, and platform integration
- `Tests/`: scheduler, persistence, and app test coverage
- `docs/`: release and supporting project docs, including the local development guide
- `packaging/`: macOS packaging assets, Xcode project generator, release scripts, and Homebrew cask template

## Contributing

Contributions are welcome, especially around scheduler behavior, macOS polish, onboarding, and documentation.

Start with [CONTRIBUTING.md](CONTRIBUTING.md) for local setup expectations and contribution guidelines. If you find a bug or want to propose a feature, open an issue or feature request in GitHub.

## Support

If you want to support ongoing maintenance, see [SUPPORT.md](SUPPORT.md).

## Privacy

knook stores its settings locally in Application Support and does not send data to a server.

## Roadmap

### Near term

- polish the reminder and break overlay interactions
- improve keyboard accessibility and labeling
- strengthen smart timing beyond the current MVP
- tighten the public contributor workflow

### Later

- additional smart pause providers such as meetings and video contexts
- AppleScript or Shortcuts support
- Focus Filters integration
- published notarized distribution

## License

knook is available under the [MIT License](LICENSE).

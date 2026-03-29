# Local Development

This guide covers the fastest way to build, run, and test knook locally.

## Requirements

- macOS 13 or newer
- a current Swift toolchain
- a full Xcode installation for the best local development experience

## Build

Build the package from the repository root:

```bash
swift build
```

## Run

Launch the app from the repository root:

```bash
swift run
```

`swift run knook` is also valid in this package because knook is the executable product.

## Test

Run the full test suite:

```bash
swift test
```

Run a targeted test class while iterating:

```bash
swift test --filter AppModelLaunchTests
```

`swift test` currently expects a full Xcode installation in this repository's setup.

## Fast Local Iteration

knook supports launch-time environment variable overrides for local testing. These values are read when the app starts, override whatever is currently saved in settings, and do not persist back to disk.

Available overrides:

- `KNOOK_WORK=<seconds>` sets the work interval for the current launch only
- `KNOOK_BREAK=<seconds>` sets the break duration for the current launch only
- `KNOOK_FORCE_ONBOARDING=1` forces the onboarding flow for the current launch only
- legacy `NOOK_*` variants still work for existing local scripts

Examples:

```bash
# 10s work, 5s break
KNOOK_WORK=10 KNOOK_BREAK=5 swift run

# 30s work, default break
KNOOK_WORK=30 swift run

# Combine with force onboarding
KNOOK_FORCE_ONBOARDING=1 KNOOK_WORK=10 KNOOK_BREAK=5 swift run
```

Values are in seconds. They override whatever is saved in settings without persisting.

## What To Verify

When using the short-duration overrides above, you should see:

- a reminder or break cycle arrive much sooner than your normal saved schedule
- a shorter break end more quickly when `KNOOK_BREAK` is set
- the onboarding flow appear when `KNOOK_FORCE_ONBOARDING=1` is set

Forced onboarding is only a launch-time override. It does not overwrite the saved onboarding state until you explicitly complete or dismiss the setup flow.

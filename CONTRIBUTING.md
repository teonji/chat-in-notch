# Contributing

Thanks for your interest! Bug reports, ideas and pull requests are welcome. By taking part you agree to follow the
[code of conduct](CODE_OF_CONDUCT.md). An overview of the code is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Setup

- Apple Silicon Mac, macOS 27+, Xcode 27 (Swift 6.x), Apple Intelligence enabled.
- `./build.sh run` builds and launches the app. There are no automated tests yet, so please describe
  how you verified your change in the pull request (what you ran, on which macOS, with/without a notch).

## Commit messages

This repository uses [Conventional Commits](https://www.conventionalcommits.org): versions and the changelog
are generated from them, so the type matters.

| Type | Effect on the version | Example |
| --- | --- | --- |
| `feat:` | minor (1.0.0 → 1.1.0) | `feat: add global shortcut to open the notch` |
| `fix:` | patch (1.0.0 → 1.0.1) | `fix: keep the notch closed after Esc` |
| `feat!:` or a `BREAKING CHANGE:` footer | major | `feat!: drop support for macOS 27.0` |
| `docs:`, `chore:`, `refactor:`, `test:`, `ci:` | none | `docs: clarify install steps` |

Use the imperative mood, keep the first line short, and add a body when the *why* is not obvious.

## Pull requests

- Keep each PR focused on one change.
- Make sure `./build.sh` succeeds without new warnings. (One deprecation warning for `installTap` is known.)
- Format with `xcrun swift-format format --in-place --recursive Sources Package.swift`; CI runs the linter in strict mode.
- UI strings and code comments are in English.
- Do not add third-party logos or assets without a license that allows redistribution.

## Landing page

The website lives in `site/` (see `site/README.md`). Use a `docs(site):` or `chore(site):` commit type for changes
there, so they do not trigger a new app version.

## How releases work

1. Merging into `main` makes [release-please](https://github.com/googleapis/release-please) open or update a
   "release PR" with the next version and changelog.
2. Merging that PR creates the tag and GitHub release, updates `CHANGELOG.md` and the version in
   `Resources/Info.plist`, and a macOS runner attaches `Chat-in-Notch.zip` to the release.

Maintainers: in *Settings › Actions › General*, enable **Allow GitHub Actions to create and approve pull requests**,
otherwise release-please cannot open the release PR.

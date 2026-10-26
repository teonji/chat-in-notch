# Chat in Notch

[![Build](https://github.com/teonji/chat-in-notch/actions/workflows/build.yml/badge.svg)](https://github.com/teonji/chat-in-notch/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![macOS 27+](https://img.shields.io/badge/macOS-27%2B-lightgrey)

A chat with Apple's **on-device language model** (Foundation Models) that lives in your Mac's **notch**.
Hover over the notch and it expands into a chat; one button opens it as a regular window.
Everything runs **locally, offline, with no tokens or accounts**. Your conversations never leave the Mac.

> Personal project, not affiliated with or endorsed by Apple. It uses the public `FoundationModels`,
> `Speech` and `ImagePlayground` APIs.

## Features

- **Hover to open**: the notch expands with an animation; `Esc`, a click outside or moving the mouse away closes it.
- **Standalone window** with a conversation list: rename (double-click), delete (with confirmation).
- **Local history**, also reachable from the notch.
- **Image attachments** (paperclip, drag & drop or paste): the model can read them.
- **`/image <description>`** generates an image with Image Playground.
- **Dictation** with the microphone (on-device recognition), auto-send after a few seconds of silence.
- **Read aloud** with system voices. With read-aloud on, the microphone reopens by itself after each answer,
  so you can have a spoken conversation.

## Requirements

- Apple Silicon Mac with **macOS 27** or later.
- **Apple Intelligence** turned on, with the model downloaded.
- To build from source: Xcode 27 (Swift 6.x).

You do **not** need to run `sudo fm license`: that agreement only concerns the `fm` command-line tool.

## Install

Download `Chat-in-Notch.zip` from the [Releases](../../releases) page and unzip it.

The app is signed ad-hoc (there is no paid developer account), so macOS blocks it the first time.
Either open **System Settings › Privacy & Security › Open Anyway**, or run:

```sh
xattr -dr com.apple.quarantine "Chat in Notch.app"
```

You can verify the download with the `.sha256` file attached to each release.

## Build from source

```sh
./build.sh run     # builds, assembles "build/Chat in Notch.app" and launches it
./package.sh       # creates dist/Chat-in-Notch.zip
```

## Privacy

Conversations and images are stored in `~/Library/Application Support/ChatInNotch`.
Your messages are processed on your Mac and never sent anywhere. The first time you use a feature, macOS may
download Apple's language or speech models; that is a system download, not your data. The microphone is only
used for dictation, after you grant permission.

## Notes

- `/image` uses the `ImageCreator` API when available; otherwise it opens Apple's Image Playground panel.
- The on-device model has a limited context window: in very long chats the app restarts from a recent summary.
- If the app says the model is unavailable, turn on Apple Intelligence in System Settings and wait for the model to download.
- There are no automated tests yet.

## Versioning and releases

Versions follow [Semantic Versioning](https://semver.org) and are produced automatically by
[release-please](https://github.com/googleapis/release-please) from [Conventional Commits](https://www.conventionalcommits.org).
See [CHANGELOG.md](CHANGELOG.md).

## Contributing

Issues and pull requests are welcome: read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[code of conduct](CODE_OF_CONDUCT.md). For an overview of how the app is built see
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Security issues: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)

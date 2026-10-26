# Architecture

Chat in Notch is a small AppKit + SwiftUI app. It has no third-party dependencies: everything comes from Apple
frameworks (`FoundationModels`, `Speech`, `AVFoundation`, `ImagePlayground`, `SwiftUI`, `AppKit`).

## Layout

```
Sources/ChatInNotch/
  main.swift                 AppKit entry point (no SwiftUI App/Scene)
  AppDelegate.swift          Owns the store, the notch, the main and Settings windows, and the main menu
  NotchController.swift      The floating panel above the notch: hover detection, expand and collapse
  NotchView.swift            SwiftUI content of the panel: notch shape, header, history list
  ChatStore.swift            Conversations, model sessions, streaming, persistence
  ChatView.swift             Chat UI shared by the notch and the main window (messages, input, attachments)
  MainWindowView.swift       Sidebar with conversations and the model status
  SettingsView.swift         Settings window
  Dictation.swift            Microphone dictation with SpeechAnalyzer
  Speaker.swift              Read-aloud with AVSpeechSynthesizer, sentence by sentence
  ImageStorage.swift         Resizes and stores attached images
  ImagePlaygroundPanel.swift Fallback window for image generation
  ModelStatus.swift          Availability of the on-device model
  AppPaths.swift, Pointer.swift
Resources/                   Info.plist and app icon
site/                        Landing page (SvelteKit), deployed to GitHub Pages
```

## How the notch works

- `NotchController` owns an `NSPanel` (borderless, non-activating, level above the menu bar, on every Space).
  It is always on screen but transparent and ignores the mouse while collapsed.
- Hover is detected with global and local `NSEvent` monitors for mouse movement. A small trigger rectangle around
  the notch expands the panel after a short delay. Leaving the panel, pressing `Esc` or clicking elsewhere collapses it.
- The notch size comes from `NSScreen` (`safeAreaInsets` and the auxiliary top areas). On Macs without a notch a
  simulated 190 x 32 pt notch is used.
- `NotchShape` draws the black body. Its top corners are concave so the panel blends into the screen edge, which is
  why the content is inset by the shape's top radius.
- Regular windows (file picker, Image Playground, Settings) open above normal windows only if the panel steps down
  or collapses first; see the `notchLowerLevel` / `notchRestoreLevel` notifications.
- While the standalone window is open the notch ignores the mouse.

## Conversations

- `ChatStore` is `@Observable` and `@MainActor`. It keeps the conversations, the selection and one
  `LanguageModelSession` per conversation.
- Replies are streamed (`streamResponse`) into the last message. Image attachments are passed as `Attachment`s.
- Sessions are not persisted. When a saved conversation is resumed, or when the context window is exceeded, a new
  session starts from a short recap of the recent messages.
- Conversations are saved as JSON in `~/Library/Application Support/ChatInNotch/conversations.json` and images in the
  `Images` folder next to it. A file that cannot be decoded is kept aside rather than overwritten.
- `/image <description>` uses `ImageCreator` and falls back to the Image Playground window when the API refuses the app.

## Voice

- `Dictation` streams microphone audio to `SpeechAnalyzer` / `SpeechTranscriber` (on-device). A few seconds without
  new text sends the message.
- `Speaker` reads a reply as it streams, one sentence at a time. With read-aloud on, `ChatView` reopens the
  microphone after the reply has been read, which gives a spoken conversation.

## Design choices

- No SwiftUI `App`/`Scene`: for a Dock-less app the Settings scene and window management proved unreliable, so the
  windows are plain `NSWindow`s hosting SwiftUI views.
- No dependencies and no network code of its own: privacy is a property of the architecture.
- Distribution is ad-hoc signed (no developer account), see the README for the Gatekeeper note.

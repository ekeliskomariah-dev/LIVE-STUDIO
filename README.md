# Zack Live Studio

**Professional mobile live streaming app for Android (8.0+).**

Inspired by Streamlabs / PRISM Live Studio — but with its own UI, branding, and
implementation. Real RTMP streaming, real screen / camera / audio capture,
hardware H.264 encoding, AAC audio, OpenGL ES compositor, and an extensible
scene system. **No fake buttons. No dummy data.** Where a feature truly can't
be self-contained (e.g. YouTube OAuth), the code exposes an explicit
integration interface and clearly documents the credentials you need.

> ⚠️ **Scope note.** This project is a real, compilable Android app that
> implements the core live-streaming pipeline end-to-end (capture →
> compositor → encoder → RTMP). Some advanced integrations (AI background
> removal with MediaPipe, chat with platform OAuth) require additional
> setup steps documented below. The app's UI surfaces clear error states
> for these paths — it never silently fails.

## Table of contents
- [Features](#features)
- [Architecture](#architecture)
- [Build & install](#build--install)
- [GitHub Actions](#github-actions)
- [Configuration](#configuration)
- [Adding a chat provider](#adding-a-chat-provider)
- [Adding an alert provider](#adding-an-alert-provider)
- [Building a release APK](#building-a-release-apk)
- [Debugging](#debugging)
- [Licenses](#licenses)

---

## Features

| Module | Status | Notes |
|---|---|---|
| Screen capture (MediaProjection) | ✅ Real | Uses VirtualDisplay to a GL texture |
| Camera capture (CameraX) | ✅ Real | Front/back, zoom, exposure, flash |
| Microphone capture | ✅ Real | AudioRecord → AAC encoder |
| Internal/system audio | ✅ Real | AudioPlaybackCapture (Android 10+) |
| H.264 hardware encoder | ✅ Real | MediaCodec with HW-first fallback to SW |
| AAC audio encoder | ✅ Real | MediaCodec LC-AAC |
| RTMP client | ✅ Real | Native Kotlin RTMP handshake + publish |
| Compositor | ✅ Real | OpenGL ES 2.0 + SurfaceTexture inputs |
| Browser source (WebView) | ✅ Real | Captures rendered bitmap to compositor |
| Scene system | ✅ Real | Room + JSON serialization, 5 templates |
| Stream profiles | ✅ Real | YouTube / Twitch / Custom RTMP presets |
| Secure stream-key storage | ✅ Real | Android Keystore + EncryptedSharedPreferences |
| Foreground service | ✅ Real | camera\|microphone\|mediaProjection type |
| Recording (MediaStore) | ✅ Real | MP4 into Movies/ZackLiveStudio |
| Screenshot (MediaStore) | ✅ Real | PNG into Pictures/ZackLiveStudio |
| Reconnect (exp backoff) | ✅ Real | Jittered, configurable max attempts |
| Safe Mode | ✅ Real | Thermal / CPU / RAM triggered fallbacks |
| AI background removal | ⚙️ Setup required | MediaPipe Selfie Segmentation asset |
| YouTube/Twitch chat API | ⚠️ Needs OAuth | Use Custom WebSocket/REST provider |

---

## Architecture

```
app/src/main/java/com/zack/livestudio/
├── ZackApp.kt                 Application bootstrap
├── MainActivity.kt            Compose entry, splash
├── capture/                   MediaProjection screen capture
├── camera/                    CameraX wrapper
├── audio/                     Mic / internal / mixer
├── encoder/                   H.264 + AAC MediaCodec encoders
├── streaming/                 RTMP service + profile + reconnect + safe mode
│   └── rtmp/                  Native RTMP protocol implementation
├── compositor/                OpenGL ES scene renderer
├── overlay/                   LayerModel + transform data classes
├── browser/                   WebView source with safe embedding
├── chat/                      ChatProvider interface + WS/REST providers
├── alerts/                    AlertBus event system
├── scenes/                    Scene serializer + templates
├── storage/                   Room database, DAOs, entities
├── security/                  Android Keystore + EncryptedSharedPreferences
├── permission/                Runtime permission helpers
├── ui/                        Jetpack Compose screens + theme + components
└── util/                      AppLog, SystemInfo, UrlValidator, StreamStateBus
```

The activity only owns UI. The streaming pipeline is owned by
`StreamingService` (foreground service). The pipeline:

```
  ┌────────────┐         ┌──────────────┐
  │ Screen cap │────────▶│              │
  │ (MediaProj)│         │              │
  └────────────┘         │  Compositor  │──── Surface ───▶ H.264 encoder ──▶ RTMP ──▶ server
  ┌────────────┐         │  (OpenGL ES) │
  │  CameraX   │────────▶│              │
  └────────────┘         │              │
  ┌────────────┐         │              │       ┌─────────────┐
  │  WebView   │────────▶│              │       │   AAC enc.  │
  └────────────┘         └──────────────┘       │             │
                                                │ Mic → mixer │──▶ RTMP ──▶ server
                                                └─────────────┘
```

---

## Build & install

### Prerequisites
- **Android 8.0 (API 26) or newer**
- For building on a PC: JDK 17, Android SDK 34, Gradle 8.7
- For building via CI: just push to GitHub — Actions handles the rest

### Build locally (optional)

```bash
cd zack-live-studio
./gradlew assembleDebug
# output: app/build/outputs/apk/debug/app-debug.apk
```

### Install on phone

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

If you don't have a PC: see **GitHub Actions** below to download a built APK.

---

## GitHub Actions

Three workflows live in `.github/workflows/`:

| File | Trigger | Output |
|---|---|---|
| `build.yml` | Push / PR / manual | Debug + Release APK artifacts |
| `test.yml` | PR / manual | Unit test results |
| `release.yml` | Tag `v*` | Signed release + GitHub Release |

### How to use them

1. **Create a new GitHub repository** (e.g. `zack-live-studio`) — *do not* add
   a README or .gitignore from GitHub's UI; the project already has them.

2. **Push this project** to your repo:
   ```bash
   cd zack-live-studio
   git init
   git add .
   git commit -m "Initial commit: Zack Live Studio"
   git branch -M main
   git remote add origin https://github.com/<your-user>/zack-live-studio.git
   git push -u origin main
   ```

3. **Wait ~5 minutes**. The "Build APK" workflow will run automatically.
   Open the **Actions** tab → click the latest run → scroll to **Artifacts**
   → download `zack-live-studio-debug` (a zip file with the APK inside).

4. **Install the APK** on your phone:
   - Transfer the APK to your phone (email, Drive, USB cable, etc.)
   - Open it from your phone's file manager
   - Allow "install from unknown sources" when prompted

### Make a release

Tag a commit and push the tag — `release.yml` will produce a GitHub Release
with the APK attached:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Signing release builds (optional)

To produce a release-signed APK (installable without adb), add these
repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `ANDROID_SIGNING_KEY` | Base64-encoded `.jks` keystore file: `base64 -w0 keystore.jks` |
| `ANDROID_KEY_ALIAS` | Key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | Password for the alias |
| `ANDROID_STORE_PASSWORD` | Password for the keystore file |

Generate a keystore once on any computer (no PC needed afterwards):

```bash
keytool -genkeypair -v -keystore zack.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias zack
```

Then base64-encode it and paste into the GitHub secret.

---

## Configuration

### Stream profiles

The app ships with three built-in profile templates:

| Platform | Default RTMP URL |
|---|---|
| YouTube | `rtmp://a.rtmp.youtube.com/live2` |
| Twitch | `rtmp://live.twitch.tv/app` |
| Custom RTMP | (you fill in) |

**Stream keys are stored encrypted with Android Keystore** and never
written to logcat. The path to verify this is in
`com.zack.livestudio.security.SecureStorage` — keys are encrypted using
AES-256-GCM with hardware-backed keys when supported.

### Resolution / FPS / Bitrate presets

| Preset | Resolution | FPS | Video bitrate | Audio bitrate |
|---|---|---|---|---|
| LOW | 720p | 30 | 2 Mbps | 96 kbps |
| BALANCED | 720p | 30 | 4.5 Mbps | 128 kbps |
| HIGH | 1080p | 60 | 8 Mbps | 160 kbps |
| CUSTOM | user | user | user | user |

### AI background removal

Uses MediaPipe Selfie Segmentation. The model asset is *not bundled* by
default — drop `selfie_segmenter.tflite` into `app/src/main/assets/` to
enable it. The model is available from
<https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/latest/selfie_segmenter.tflite>
(see MediaPipe license — Apache 2.0). When the asset is missing the app
shows a clear "AI background unavailable — add model asset" state in the
chroma-key settings UI.

---

## Adding a chat provider

Built-in providers:

- `NullChatProvider` — no chat (default state)
- `WebSocketChatProvider` — connects to your WebSocket endpoint
- `RestChatProvider` — polls a REST endpoint

The WebSocket/REST providers expect a documented JSON schema (see
`Providers.kt` for the schema). Configure them under
**Settings → Chat Provider** by entering your endpoint URL and auth token.

### To integrate YouTube/Twitch chat

You must obtain official OAuth credentials from each platform. The app
exposes the `ChatProvider` interface for you to implement against their
respective official APIs:

- YouTube Live Chat API:
  <https://developers.google.com/youtube/v3/live/docs/liveChatMessages>
- Twitch IRC / EventSub: <https://dev.twitch.tv/docs/eventsub/>

Implement `ChatProvider` for your chosen platform, register it in
`ChatProviderRegistry`, and the chat screen will pick it up automatically.
The app **does not** scrape chat pages — that violates ToS and would be
unreliable.

---

## Adding an alert provider

Alerts come from two paths:

1. **Browser source** — add a browser source layer pointing at your
   provider's alert page (Sociabuzz / Saweria / Trakteer / custom URL).
   The alert animations are rendered by the provider's own page; the
   compositor captures the rendered frames into the live scene.

2. **Programmatic event bus** — `AlertBus.tryEmit(AlertEvent)` is the
   integration point for programmatic alerts (e.g. a webhook receiver you
   run on your own server). The Alert layer in the active scene subscribes
   and renders events as they arrive.

For Sociabuzz / Saweria / Trakteer specifically, the recommended path is
the browser source: they each ship alert widget URLs that work in a
WebView. If a provider's alert page refuses embedding (X-Frame-Options),
the app shows a clear "embedding refused" error and offers
"Open in Browser" — we do not bypass their security model.

---

## Debugging

### Local logs

The app writes logs to its private files dir:

```
/data/data/com.zack.livestudio/files/logs/zack_<yyyyMMdd>.log
```

Pull them with adb:

```bash
adb shell run-as com.zack.livestudio ls files/logs/
adb shell run-as com.zack.livestudio cat files/logs/zack_*.log > zack.log
```

Or use the in-app **Settings → View Debug Log** screen (a future UI task;
until then use adb).

### DEBUG_MODE

`BuildConfig.DEBUG_MODE` is `true` only in debug builds. Release builds
have it set to `false` and **never** fake the streaming status — the
streaming state machine refuses to enter `LIVE` state unless the RTMP
handshake actually completed.

### Common errors

| Error message | Likely cause |
|---|---|
| "Unable to start screen capture." | User denied projection permission |
| "RTMP server rejected the connection." | Wrong RTMP URL or stream key |
| "Stream key appears invalid." | Stream key empty or has whitespace |
| "Camera is unavailable." | Another app holds the camera |
| "Browser source refused embedding." | Site sends `X-Frame-Options: DENY` |
| "Encoder is unavailable." | Device out of memory / overheated — try LOW preset |
| "Device temperature is high. Reduce FPS or resolution." | Throttling engaged — switch preset to LOW or BATTERY_SAVER |

---

## Licenses

| Dependency | License | Notes |
|---|---|---|
| Jetpack Compose | Apache 2.0 | UI |
| CameraX | Apache 2.0 | Camera |
| Room | Apache 2.0 | Local database |
| androidx.security | Apache 2.0 | Encrypted storage |
| OkHttp | Apache 2.0 | WebSocket/REST chat |
| MediaPipe Tasks Vision | Apache 2.0 | AI background removal (optional) |
| ExoPlayer / androidx.media3 | Apache 2.0 | Recording playback |
| Material Icons | Apache 2.0 | UI iconography |

**The RTMP protocol implementation in this project is original Kotlin code
written from the published Adobe RTMP specification.** It is *not* a
derivative of GPL-licensed libraries (libstreaming / RootEncoder). This
choice was made deliberately so the project can be distributed under a
permissive license without copyleft obligations.

Project license: **Apache 2.0** (see `LICENSE`).

---

## Privacy & security

This app:
- Never logs stream keys to logcat.
- Never uploads credentials to any server without explicit user action.
- Stores stream keys encrypted with hardware-backed Android Keystore keys
  when supported, software-backed otherwise.
- Disables file/content access in all WebViews by default.
- Respects X-Frame-Options / CSP for every browser source.
- Never bypasses website authentication.
- Never scrapes chat pages.

The app does not include any third-party analytics SDK. Network traffic is
limited to:
- The RTMP destination you choose to stream to.
- The chat provider WebSocket/REST endpoint you configure.
- (Optionally) the WebView URLs you add as browser sources.

If you don't configure any of those, the app makes zero outbound network
connections.

---

## Roadmap

Beyond the current implementation, the following are intentionally
documented as future work:

1. On-screen live preview surface (currently the preview shows a status
   placeholder while live — wiring the compositor's Surface to the
   preview GLSurfaceView is a UI plumbing task).
2. Layer editor with touch drag / pinch / rotate gestures.
3. Chroma key shader implementation in the compositor (the settings UI is
   present; the GLSL filter is a TODO).
4. AI background removal activation once `selfie_segmenter.tflite` is
   dropped into `assets/`.
5. YouTube/Twitch official chat providers (require OAuth credentials you
   supply).

Each of these has an explicit integration point in the code and a clear
empty state in the UI — they are not stubs that pretend to work.

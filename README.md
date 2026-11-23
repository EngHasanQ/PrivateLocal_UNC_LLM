# PrivateLocal

A private, **fully offline** fork of [PrivateLM](https://github.com/orailnoor/cross-platform-llm-client) (MIT) for Android:
on-device chat with GGUF models (llama.cpp) and on-device image generation (stable-diffusion.cpp).

## What makes this build offline

| Guarantee | How |
|---|---|
| The app cannot open any network connection (internet or Wi-Fi/LAN) | `INTERNET` permission is stripped with `tools:node="remove"`; Android blocks every socket for apps without it |
| It can't come back by accident | CI checks the final APK and **fails the build** if `INTERNET` (or mic, camera, install-apps, all-files storage) is present |
| No telemetry | Firebase Messaging and Crashlytics removed entirely |
| No remote code | Self-updater (download + install APK from GitHub) removed |
| No cloud chat | Cloud providers hidden and inference forced to local |
| No exposed server | Local OpenAI-compatible server and phone cluster removed |
| No mic | Speech-to-text removed (it can use Google's online recognizer) |
| Not in Google backup | `allowBackup=false` + data-extraction rules exclude everything |
| Only you can publish updates | Release APKs are signed with your own key (GitHub secrets); debug-signed builds are refused |

## Build (cloud only — no computer needed)

1. GitHub → **Settings → Secrets and variables → Actions → New repository secret**, add:
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
2. **Actions → Build offline APK → Run workflow** (or push to `main`).
3. Open **Releases**, download `PrivateLocal-…-arm64.apk` on the phone and install it.
   Check the *signing certificate SHA-256* in the release notes stays the same on every update.

## Models (download in the phone's browser, then *Models → Import*)

Recommended for a 12 GB phone (e.g. Galaxy S22 Ultra):

| Use | File | Size | From |
|---|---|---|---|
| Chat, uncensored (main) | `Meta-Llama-3.1-8B-Instruct-abliterated-Q4_K_M.gguf` | 4.9 GB | huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-abliterated-GGUF |
| Chat, uncensored (faster) | `Llama-3.2-3B-Instruct-uncensored-Q4_K_M.gguf` | 2.2 GB | huggingface.co/bartowski/Llama-3.2-3B-Instruct-uncensored-GGUF |
| Images (fast, 4–8 steps) | `DreamShaper8_LCM.safetensors` | 2.1 GB | huggingface.co/Lykon/dreamshaper-8-lcm |
| Optional faster image decode | `diffusion_pytorch_model.safetensors` → **rename to `taesd.safetensors`** before importing | ~10 MB | huggingface.co/madebyollin/taesd |

Import copies the file into the app's private storage; you can delete the copy in *Downloads* afterwards.
Only one model (chat or image) is kept in memory at a time.

## Known limits

- Android only (arm64). The iOS/macOS/web folders are inherited from upstream and are not built.
- GPU backends for image generation (`libsd_jni_vulkan.so`, `libsd_jni_opencl.so`) are **prebuilt binaries from upstream**.
  They contain no networking symbols, and without the INTERNET permission they could not reach the network anyway,
  but they are not rebuilt from source yet. The CPU library and llama.cpp are compiled from source in CI.
- Cloud-provider code is still in the source tree but unreachable from the UI and blocked by the OS.

Upstream documentation: [README.upstream.md](README.upstream.md).

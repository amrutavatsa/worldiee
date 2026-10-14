# DEPLOY.md â€” World Companion (Phase 1): Complete Setup & Run Guide

This guide takes a completely fresh machine (nothing installed) to a running
Django backend and an installed Android APK. It reflects a tested, working
setup path â€” including the specific version pins needed to avoid known build
failures with newer Flutter/Java/Gradle combinations. Follow the versions
specified here exactly; using newer versions than recommended is the single
biggest source of build failures with this project.

Written for Windows. Notes for Mac/Linux are called out where steps differ.

---

## Table of Contents

1. [Prerequisites & Required Versions](#1-prerequisites--required-versions)
2. [Backend Setup (Django)](#2-backend-setup-django)
3. [Running & Testing the Backend](#3-running--testing-the-backend)
4. [Flutter SDK Installation](#4-flutter-sdk-installation)
5. [Android Studio & SDK Installation](#5-android-studio--sdk-installation)
6. [JDK Setup (Critical â€” Read Before Building)](#6-jdk-setup-critical--read-before-building)
7. [Frontend Setup (Flutter)](#7-frontend-setup-flutter)
8. [Connecting the App to Your Backend](#8-connecting-the-app-to-your-backend)
9. [Building & Installing the APK](#9-building--installing-the-apk)
10. [Troubleshooting](#10-troubleshooting)
11. [Next Steps After Setup](#11-next-steps-after-setup)

---

## 1. Prerequisites & Required Versions

| Tool | Required Version | Why This Version Specifically |
|---|---|---|
| Python | 3.11+ | Runs the Django backend |
| Flutter SDK | **3.24.5** (not the latest stable) | Newer Flutter versions (3.4x+) pull in a Gradle/AGP combination with known, hard-to-diagnose build failures on Windows. 3.24.5 is proven working for this project. |
| JDK | **17â€“21** (not 25 or newer) | Gradle 8.x (used by Flutter 3.24.5) does not reliably support very new JDK versions. JDK 21 LTS is the safest choice. |
| Android Studio + SDK | Latest | Provides the Android SDK, Build-Tools, and Platform-Tools |
| VS Code or Antigravity | Latest | Code editor (optional but recommended) |

**Do not substitute newer versions of Flutter or Java unless you're prepared to debug Gradle configuration issues.** This is not a general caution â€” it reflects an actual, reproduced failure chain on this exact project.

---

## 2. Backend Setup (Django)

### 2.1 Install Python
- Download from [python.org/downloads](https://python.org/downloads)
- **Windows:** check **"Add Python to PATH"** during install
- Verify:
  ```powershell
  python --version
  ```

### 2.2 Open the project
- Extract the project zip (e.g. to `Downloads\worldcompanion_phase1_build`)
- Open the `worldcompanion` folder in your editor: **File â†’ Open Folder**

### 2.3 Install backend dependencies
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```
Installs Django, Django REST Framework, NetworkX (routing engine), scikit-learn and joblib (intent classifier).

### 2.4 Train the intent classifier
```powershell
.\.venv\Scripts\python.exe ml/intent_classifier.py
```
Expected: a trained-model summary with an accuracy score, and a new file at `data/intent_model.joblib`. (~60% accuracy is expected with the small starter dataset of ~39 examples â€” see Section 11 for how to improve this.)

### 2.5 Set up the database
```powershell
.\.venv\Scripts\python.exe manage.py migrate
```
Expected: several `Applying ... OK` lines.

---

## 3. Running & Testing the Backend

### 3.1 Start the server
```powershell
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```
This does not return â€” it runs continuously. **Leave this terminal open** for the entire time you need the backend available (including during any demo).

### 3.2 Test it's working
Open a **second terminal** (don't close the server's terminal).

**Browser test:** visit `http://localhost:8000/api/pois/` â€” expect JSON with location names.

**Terminal test (Windows PowerShell):**
```powershell
Invoke-RestMethod -Uri "http://localhost:8000/api/intent/" -Method Post -ContentType "application/json" -Body '{"text": "take me to lalbagh"}'
```
**Terminal test (Mac/Linux):**
```bash
curl -X POST http://localhost:8000/api/intent/ -H "Content-Type: application/json" -d '{"text": "take me to lalbagh"}'
```
Expected: `{"success": true, "data": {"intent": "navigation", "confidence": ...}}`

If both pass, the backend is fully working â€” move to the frontend.

---

## 4. Flutter SDK Installation

### 4.1 Download and extract
- Go to [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- Extract to a simple path, e.g. `C:\Users\<you>\Desktop\flutter` (avoid `Program Files` â€” permission issues)

### 4.2 Switch to the required stable version (3.24.5)
```powershell
cd C:\Users\<you>\Desktop\flutter
git checkout 3.24.5
```
Confirm:
```powershell
flutter --version
```
Must show `3.24.5`, not a newer version.

### 4.3 Add Flutter to your system PATH (Windows)
1. Windows key â†’ **"Environment Variables"** â†’ **"Edit the system environment variables"**
2. **"Environment Variables..."**
3. Under **"User variables"**, select **"Path"** â†’ **"Edit"** â†’ **"New"**
4. Add the path to Flutter's `bin` folder, e.g. `C:\Users\<you>\Desktop\flutter\bin` â€” **must include `\bin`**
5. OK on all dialogs

### 4.4 Restart your editor completely
Close it entirely (not just the terminal) â€” PATH changes only apply to freshly opened windows.

### 4.5 Verify
```powershell
flutter --version
```

### 4.6 Install the Flutter and Dart VS Code extensions
Extensions panel â†’ search "Flutter" â†’ install (auto-installs Dart too).

---

## 5. Android Studio & SDK Installation

### 5.1 Install Android Studio
- Download from [developer.android.com/studio](https://developer.android.com/studio), run the installer with default options â€” installs the Android SDK, Platform-Tools, and an emulator image
- Large download â€” let it finish completely

### 5.2 Complete first-time setup
Launch once, complete the setup wizard if prompted, then close â€” no project needed.

### 5.3 Install required SDK components
Open Android Studio â†’ **More Actions â†’ SDK Manager** (or **File â†’ Settings â†’ Languages & Frameworks â†’ Android SDK**):

**"SDK Tools" tab** â€” check **"Show Package Details"**, then ensure these are installed:
- Android SDK Build-Tools (latest)
- **Android SDK Command-line Tools (latest)** â€” required; without this, license acceptance and builds fail
- Android SDK Platform-Tools
- NDK (Side by side) â€” install whatever version is available; if a build later asks for a specific version you don't have, install that exact version from this list

**"SDK Platforms" tab** â€” check at least one recent Android version (e.g. Android 14).

Click **Apply**, let everything download.

### 5.4 Verify
```powershell
flutter doctor
```
You want a checkmark next to **"Android toolchain."** A Visual Studio warning is safe to ignore â€” it's only for building native Windows desktop apps, not Android APKs.

**Known issue:** on some newer SDK tool versions, `flutter doctor --android-licenses` may show a deprecation notice and license status may still show as unknown even after accepting. If `flutter build apk` completes successfully despite this warning, it's cosmetic â€” proceed.

---

## 6. JDK Setup (Critical â€” Read Before Building)

**This step prevents the most common and hardest-to-diagnose build failure in this project.**

If your machine's default Java version is newer than 21 (check with `java -version`), do not use it for Flutter builds â€” Gradle 8.x (used by Flutter 3.24.5) is not reliably compatible with very new JDKs, and the resulting errors are generic and misleading (e.g. `"Cannot query the value of this provider because it has no value available"` on unrelated tasks).

### 6.1 Install JDK 21 (LTS)
- Download from [adoptium.net](https://adoptium.net) â€” select **Java 21 (LTS)**, Windows, x64, `.msi`
- Run with default options

### 6.2 Point Flutter specifically at this JDK
This avoids changing your system-wide Java â€” Flutter uses this JDK only for its own builds:
```powershell
flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-21.x.x.x-hotspot"
```
(Replace the version folder name with whatever Adoptium actually installed â€” check with `dir "C:\Program Files\Eclipse Adoptium"`.)

### 6.3 Verify
```powershell
flutter doctor -v
```
Confirm it references the JDK 21 path, not a newer version.

---

## 7. Frontend Setup (Flutter)

### 7.1 Install dependencies
```powershell
cd frontend
flutter pub get
```

### 7.2 Regenerate native project files for your Flutter version
If `android/` was previously generated under a different Flutter version (or doesn't exist), regenerate it fresh so all native build files match your installed Flutter 3.24.5:
```powershell
flutter create .
```
This is safe â€” it does not overwrite your Dart code in `lib/`, only the native platform scaffolding.

### 7.3 Enable symlink support (Windows)
Flutter plugins need symlink support on Windows, via either Developer Mode or an elevated terminal:
- **Option A:** run `start ms-settings:developers` and enable Developer Mode, **or**
- **Option B:** run your terminal "as Administrator" for the build steps below

### 7.4 Keep the plugin dependency list minimal
This project currently uses only what Phase 1 needs (`http`) to reach the backend. Packages like `record`, `permission_handler`, and `google_maps_flutter` are **not required for the current build** and have caused Gradle/Kotlin-plugin compatibility failures in testing â€” leave them out of `pubspec.yaml` until you're specifically ready to build and test each one individually.

---

## 8. Connecting the App to Your Backend

`localhost` does not work from a phone â€” the app needs your computer's actual network address.

### 8.1 Find your computer's local IP
```powershell
ipconfig
```
Look for **IPv4 Address** under your active WiFi adapter, e.g. `192.168.1.4`.

**This address can change** (different WiFi network, router reassigning addresses) â€” re-check it if the app stops connecting after previously working.

### 8.2 Update the app's API address
Open `frontend/lib/services/api_service.dart`:
```dart
static const String baseUrl = "http://<YOUR_CURRENT_IP>:8000";
```
Save.

**Important:** this address is compiled into the app at build time. Any time your IP changes, you must update this line **and rebuild the APK** â€” the already-installed app won't pick up the change on its own.

### 8.3 Requirements
- Phone and computer on the **same WiFi network**
- Django server (Section 3.1) **running** at the time you use the app
- Windows Firewall may prompt to allow Python/Django â€” allow it

---

## 9. Building & Installing the APK

### 9.1 Build (debug â€” recommended for testing and demos)
```powershell
flutter clean
flutter build apk --debug
```
A debug build is fully installable and functionally identical to a release build for demo purposes, and avoids release-only build steps (code minification) that have caused failures in testing. Output:
```
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

**First build only:** this step downloads Gradle, SDK components, and NDK as needed â€” it can take 5â€“15+ minutes and will look idle at times. Let it run.

**If Gradle's automatic download times out** (a `Connection timed out` error referencing `services.gradle.org`, despite normal internet access) â€” this is typically antivirus or firewall blocking Java specifically, not a real network outage. Workaround:
1. Check `frontend/android/gradle/wrapper/gradle-wrapper.properties` for the exact Gradle version/URL needed
2. Download that exact `.zip` manually via your browser (browsers are rarely blocked the same way)
3. Edit `gradle-wrapper.properties`, replacing the `distributionUrl` line with a local file path:
   ```properties
   distributionUrl=file\:///C:/Users/<you>/Downloads/gradle-8.3-all.zip
   ```
   (forward slashes required, even on Windows)
4. Rebuild

### 9.2 Install on a phone
- Copy the APK to your phone (USB, Google Drive, WhatsApp-to-self, etc.)
- Open the file, allow **"install from unknown sources"** if prompted, install

### 9.3 Before demoing
- Confirm the Django server is running (Section 3.1)
- Confirm the phone is on the same WiFi
- Confirm `api_service.dart`'s IP matches your **current** `ipconfig` output â€” rebuild if it doesn't
- Open the app, test a query (e.g. "take me to lalbagh then cubbon park")

---

## 10. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `flutter` not recognized | PATH not set, or editor not restarted | Section 4.3â€“4.5 |
| `flutter doctor` shows Android toolchain issue | cmdline-tools missing, or licenses not accepted | Section 5.3â€“5.4 |
| Generic Gradle error: "Cannot query the value of this provider..." on any task | JDK too new for this Gradle version | Section 6 â€” install and configure JDK 21 |
| `Package ndk not found` / NDK version mismatch | Project requests a specific NDK version not installed | Install that exact version via SDK Manager â†’ SDK Tools â†’ NDK (Side by side), with "Show Package Details" checked; or override `ndkVersion` in `android/app/build.gradle` to match what's actually installed |
| `Failed to find target with hash string 'android-XX'` | SDK path mismatch (e.g. `Sdk` vs `sdk` capitalization) | Confirm `ANDROID_HOME` and `local.properties`' `sdk.dir` both point to the exact same, correctly-capitalized path; use double backslashes (`\\`) in `local.properties` on Windows |
| Kotlin Gradle Plugin (KGP) warning naming a specific plugin | An installed plugin (e.g. `record`) uses an outdated Kotlin integration incompatible with your Flutter version | Remove the plugin from `pubspec.yaml` if not yet in use (Section 7.4), or wait for an updated plugin release |
| `flutter build apk --release` fails on minification (R8) | Known flaky step with some AGP versions | Add `isMinifyEnabled = false` and `isShrinkResources = false` to the `release` block in `android/app/build.gradle(.kts)`, or build `--debug` instead (Section 9.1) |
| Gradle download times out despite working internet | Antivirus/firewall blocking Java specifically | Manual local-file workaround, Section 9.1 |
| App can't reach the backend | Wrong/stale IP, different WiFi networks, server not running, firewall | Recheck Section 8; re-run `ipconfig`; confirm server terminal is still open |
| `pip install` fails | `pip` not mapped, or Python not on PATH | Try `pip3`; reinstall Python with "Add to PATH" checked |
| Symlink error on `flutter pub get` / `flutter create` | Windows Developer Mode not enabled and not running as Administrator | Section 7.3 |
| Voice/microphone feature doesn't respond | Vosk model not yet downloaded (expected in Phase 1) | See `backend/ml/speech_to_text.py` for setup |

---

## 11. Next Steps After Setup

1. **Expand the intent training dataset** (`backend/data/intent_training_data.csv`) from ~39 to 200â€“500+ labeled examples â€” the single highest-impact improvement to classifier accuracy and confidence.
2. **Set up Vosk locally** for real voice transcription (`backend/ml/speech_to_text.py` has the setup steps).
3. **Wire the computed route onto an actual map** â€” add back `google_maps_flutter` deliberately, one package at a time, once Phase 1's core flow is stable, using your own Google Maps API key.
4. **Expand the POI dataset** (`backend/api/poi_data.py`) beyond the current 12 seed locations.
5. **Improve the frontend UI/UX** â€” the current screens are functional but minimal; polish typography, spacing, and visual design before any public-facing demo.



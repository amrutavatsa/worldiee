# WorldCompanion

WorldCompanion is a Flutter application with a Django REST Framework backend. It brings together map exploration, nearby places, route planning, accommodation features, user profiles, and travel companion functionality.

**Repository:** https://github.com/amrutavatsa/worldiee

---

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Clone the Repository](#1-clone-the-repository)
- [Set Up the Django Backend](#2-set-up-the-django-backend)
- [Run the Flutter Application in a Browser](#3-run-the-flutter-application-in-a-browser)
- [Build an Android APK](#4-build-an-android-apk)
- [Configure Google Sign-In](#5-configure-google-sign-in)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)
- [Contributing](#contributing)

---

## Features

WorldCompanion brings together a set of travel-oriented features, including:

- Interactive map exploration
- Nearby places and points of interest
- Route planning and navigation-related features
- Accommodation and stay-related functionality
- User authentication and profiles
- Travel companion features and API integrations

The exact availability of individual features depends on the current implementation and configuration of the application.

## Project Structure

The relevant project structure is:

```text
worldiee/
└── world-companion/
    ├── backend/
    │   ├── api/
    │   ├── config/
    │   ├── core/
    │   ├── data/
    │   ├── ml/
    │   ├── places/
    │   ├── .env.example
    │   ├── requirements.txt
    │   └── manage.py
    ├── frontend/
    │   └── ...
    ├── deploy.md
    └── README.md
```

The Django backend is located in `backend/`. The Flutter application is located in `frontend/`.

The `backend/.env` file, virtual environment, local database, and generated build files are local development artifacts and should not be committed to Git.

## Prerequisites

Install the following tools before starting:

- **Git** — to clone the repository
- **Python** — a version compatible with the pinned dependencies in `backend/requirements.txt`
- **Flutter SDK** — for running and building the frontend
- **Android Studio and Android SDK** — for Android development and APK builds
- **A compatible JDK** — usually provided or configured through Android Studio
- **Google Chrome** — if you want to run the Flutter web application in Chrome

Verify your installations in PowerShell:

```powershell
git --version
python --version
flutter --version
flutter doctor
```

Resolve any required Flutter or Android SDK setup issues reported by `flutter doctor`.

> Use a Python version compatible with all packages in `backend/requirements.txt`. If a dependency fails to install, check its Python-version requirements before changing package versions.

## 1. Clone the Repository

Open PowerShell and navigate to the directory where you want the project.

```powershell
git clone https://github.com/amrutavatsa/worldiee.git
```

Open the cloned repository:

```powershell
Set-Location .\worldiee
```

If your repository contains the application in a nested `world-companion` directory, enter it:

```powershell
Set-Location .\world-companion
```

Continue from the directory containing both `backend/` and `frontend/`.

Confirm that you are in the correct directory:

```powershell
Get-ChildItem
```

You should see the `backend` and `frontend` directories.

> If the repository itself already contains `backend/` and `frontend/` at its root, do not enter an additional `world-companion` directory.

## 2. Set Up the Django Backend

All commands in this section start from the project root unless otherwise specified.

### 2.1 Create a virtual environment

```powershell
python -m venv .\backend\.venv
```

### 2.2 Install backend dependencies

Upgrade pip and install the pinned dependencies:

```powershell
.\backend\.venv\Scripts\python.exe -m pip install --upgrade pip
.\backend\.venv\Scripts\python.exe -m pip install -r .\backend\requirements.txt
```

The requirements file contains the Python dependencies needed by the backend. If installation fails, check the Python version and the error message before modifying the dependency file.

### 2.3 Configure environment variables

Create your local environment file from the example:

```powershell
Copy-Item .\backend\.env.example .\backend\.env
```

Open it for editing:

```powershell
notepad .\backend\.env
```

Configure the required settings using the example below:

```dotenv
DJANGO_SECRET_KEY=replace-with-your-own-random-secret
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,YOUR_LAPTOP_LAN_IP
```

Replace the placeholder values with your own development settings.

**Important:** `DJANGO_ALLOWED_HOSTS` contains hostnames and IP addresses, not full URLs. For example, use `192.168.1.25`, not `http://192.168.1.25:8000`.

Keep any additional optional settings already documented in `backend/.env.example`. Configure database, CORS, or CSRF settings only when required by your setup.

Never share or commit your real `.env` file.

### 2.4 Run database migrations

From the project root:

```powershell
Set-Location .\backend
```

Apply database migrations:

```powershell
.\.venv\Scripts\python.exe manage.py migrate
```

Django should apply the required migrations and report their status.

If the project requires additional application-specific initialization, follow the instructions documented in the relevant backend modules.

### 2.5 Start the Django backend

Start the development server:

```powershell
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

Keep this terminal open while using the application.

The server listens on port `8000`. Binding to `0.0.0.0` allows other devices on your local network to connect, subject to firewall and network configuration.

> Django's development server is for development and testing only. Do not expose it directly to the public internet.

### 2.6 Test the backend

On the same computer, open a browser and visit:

`http://127.0.0.1:8000/`

A Django 404 response at the root URL can be normal if no root page is configured. Test an actual API endpoint used by your application to confirm the backend is responding.

Keep the server terminal open during these tests.

## 3. Run the Flutter Application in a Browser

Open a **second PowerShell terminal**.

From the project root, run:

```powershell
Set-Location .\frontend
```

Download the Flutter dependencies:

```powershell
flutter pub get
```

Run the application in Chrome:

```powershell
flutter run -d chrome --web-port 5000
```

The browser application must be able to reach the Django backend.

If the frontend uses `127.0.0.1:8000` as its default API address, that address refers to the same computer running Chrome and the backend. If your frontend has a configurable API base URL, use the configuration supported by the application.

If browser requests fail, check the browser console, backend logs, API address, and Django CORS configuration.

## 4. Build an Android APK

### 4.1 Find your laptop's local IP address

This step is necessary when the Android phone will connect to Django running on your laptop over Wi-Fi.

Open a separate PowerShell terminal and run:

```powershell
ipconfig
```

Find the IPv4 address of the network adapter connected to your Wi-Fi.

For example:

```text
192.168.1.25
```

This is only an example. Use your laptop's actual current IPv4 address.

Connect your Android phone and laptop to the same trusted Wi-Fi network.

### 4.2 Allow local network access

If Windows Firewall blocks Django, allow Python/Django on your private network or configure a narrowly scoped inbound TCP port `8000` rule for your private network.

Avoid exposing port `8000` to public networks.

### 4.3 Test connectivity from your phone

With Django running, open the following URL in your phone's browser, replacing the example IP with your laptop's actual IPv4 address:

```text
http://192.168.1.25:8000/
```

A Django 404 response can indicate that the server is reachable even though no page is configured at the root URL. A timeout or connection failure may indicate an incorrect IP address, firewall restriction, Wi-Fi isolation, or a stopped backend.

### 4.4 Build the APK

In the Flutter frontend directory, build the release APK using your laptop's actual IP address:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.25:8000
```

Replace `192.168.1.25` with the actual IPv4 address of your laptop.

The API base URL must use the configuration key supported by the Flutter application. If the application uses a different compile-time variable, use the one implemented in the source code.

When the build succeeds, the APK is located at:

```text
frontend\build\app\outputs\flutter-apk\app-release.apk
```

This path is relative to the project root.

Copy the APK to your Android phone and install it. Android may ask you to allow installation from the file manager or browser used to open the APK.

### 4.5 Install using ADB (optional)

If your Android phone is connected by USB and USB debugging is enabled, you can install the APK using ADB.

From the `frontend` directory:

```powershell
adb install -r .\build\app\outputs\flutter-apk\app-release.apk
```

### 4.6 Keep the phone and backend connected

For the installed APK to communicate with Django:

1. Keep the backend server running on your laptop.
2. Keep the phone and laptop on the same Wi-Fi network.
3. Make sure the configured API address uses the laptop's reachable LAN IP, not `127.0.0.1`.
4. Allow the required local network traffic through the firewall.
5. Rebuild the APK if the configured API address changes.

On Android, `127.0.0.1` refers to the phone itself, not your laptop.

## 5. Configure Google Sign-In

Google authentication requires correctly configured OAuth credentials. A successful local build does not guarantee that Google Sign-In will work on another developer's computer or Android device.

Check the following:

- The Android OAuth client matches the Android application ID.
- The Android OAuth client has the appropriate signing-certificate SHA-1 fingerprint.
- The correct web and Android OAuth clients are configured in Google Cloud Console.
- The backend accepts the audience associated with the web client ID used by the frontend.
- Debug and release signing certificates are configured as required.
- Any required frontend client IDs and backend environment variables are configured without committing private credentials.

The Android application ID currently documented by the project is:

`com.example.frontend`

Verify this value against the current Android Gradle configuration before creating OAuth credentials.

Do not commit service-account keys, private signing keystores, access tokens, or real `.env` files.

## Troubleshooting

### Python dependencies fail to install

1. Run `python --version`.
2. Confirm that the installed Python version is compatible with the pinned packages.
3. Read the specific pip error to identify the failing package.
4. Use the virtual environment's Python executable for backend commands.
5. Avoid installing dependencies into the global Python environment unnecessarily.

### Django reports `DisallowedHost`

Add the hostname or IP address used by the request to `DJANGO_ALLOWED_HOSTS` in `backend/.env`.

For a local phone connection, the list may need the laptop's LAN IP address. Do not include `http://` or a port number in the allowed-hosts entries.

Restart Django after changing environment settings.

### The phone cannot connect to Django

1. Confirm Django is running on `0.0.0.0:8000`.
2. Confirm the laptop's current IPv4 address.
3. Check that the phone and laptop are on the same Wi-Fi network.
4. Check Windows Firewall and router client-isolation settings.
5. Confirm that `DJANGO_ALLOWED_HOSTS` includes the host used by the phone.
6. Confirm that the APK was built with the correct API base URL.

### The API works in the browser but not in the APK

Verify the API base URL compiled into the APK and confirm that the phone can reach the laptop over the local network. A URL using `127.0.0.1` will point to the phone itself.

Also check Django logs and Android application logs for connection errors.

### Flutter or Android build errors

From the `frontend` directory, run:

```powershell
flutter doctor
flutter pub get
flutter analyze
```

Resolve any SDK, dependency, or source-code issues reported before building again.

### Google Sign-In fails

Check the Android application ID, OAuth client configuration, signing-certificate SHA-1 fingerprints, backend accepted audience, and frontend client ID. Debug and release builds may require different signing fingerprints.

## Security Notes

- Keep `backend/.env` private and untracked by Git.
- Generate a unique development secret key for each local environment.
- Never commit API keys, private credentials, service-account files, or signing keystores.
- Use HTTP only for appropriate local-network development and testing.
- Use HTTPS and production-grade Django deployment settings before hosting publicly.
- Do not expose Django's development server to the public internet.
- Configure release signing appropriately before distributing a production APK.
- Review firewall rules and allow only the network access required for development.

## Contributing

1. Fork or clone the repository.
2. Create a feature branch.
3. Make changes in the relevant backend or frontend directory.
4. Install the required dependencies.
5. Test the affected functionality locally.
6. Review your changes with `git status` before committing.
7. Never commit credentials, local databases, virtual environments, generated build output, or temporary backups.

---

**Note:** These instructions describe a local development setup. Before sharing the repository with another developer, test the complete setup from a clean clone on a separate environment. This confirms that the repository contains the required source files and that the documented installation steps work without relying on your existing local configuration.

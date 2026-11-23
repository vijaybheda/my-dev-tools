# 🚀 Mobile Deployment Engine (`deploy.sh`) — Developer Guide

Welcome to **`the_birth_code`** Mobile Compilation & Release CLI Engine! This tool automates the entire Flutter build and release pipeline for both Android and iOS across multiple environment flavors and distribution gateways.

---

## 📋 Table of Contents
- [Quick Start](#-quick-start)
- [Interactive Wizard & Workflow](#-interactive-wizard--workflow)
- [Key Features](#-key-features)
- [Google Drive Folder Structure](#-google-drive-folder-structure)
- [CLI Command Flags (Headless & CI/CD)](#-cli-command-flags-headless--cicd)
- [Configuration & Credentials (`.build-config.env`)](#-configuration--credentials-build-configenv)
- [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## ⚡ Quick Start

To launch the interactive deployment wizard:

```bash
./deploy.sh
```

> **Note:** The CLI uses `fvm` (`fvm flutter`) automatically if detected on your system.

---

## 🧙‍♂️ Interactive Wizard & Workflow

When running `./deploy.sh` without flags:

1. **Session Memory Card**:
   - If a previous session exists, `deploy.sh` displays your previous run settings (Environment, Platforms, Versions, Distribution Gateways, Timestamp).
   - Choose **Fast Deploy** to re-run your previous setup with auto-incremented build numbers, or **Interactive Wizard** to customize settings.

2. **Step 1: Select Environment Flavor**:
   - `staging`: Staging Environment
   - `qa`: QA Environment
   - `prod`: Production Environment
   - `ngrok`: Local Ngrok Tunnel

3. **Step 2: Select Compilation Platform Packages (Multi-Select)**:
   - Use `Space` to toggle, `a` to toggle all, `1-4` for direct selection, and `Enter` to confirm:
     - `[ ]` **Android APK** (Direct device install & Google Drive QA link)
     - `[ ]` **Android App Bundle (AAB)** (Google Play Console Release)
     - `[ ]` **iOS Signed IPA** (App Store / TestFlight & Diawi QA link)
     - `[ ]` **iOS Unsigned Archive** (Xcode Organizer export / No-codesign)

4. **Step 3: Platform Version Configurations**:
   - Baseline versions are automatically read from `pubspec.yaml`.
   - The CLI pre-fills the auto-incremented build version (e.g. `1.0.0+24`). Press **Enter** to accept or type a custom version string.

5. **Step 4: Distribution & Store Gateways (Multi-Select)**:
   - Select one or more automated release destinations:
     - **Google Play Console** (Internal Track)
     - **Google Drive** (Direct download link)
     - **Apple App Store / TestFlight**
     - **Diawi** (Internal testing link)

6. **Pre-Flight Summary**:
   - Review your configuration. Press **Enter** (defaults to `[Y]`) to start compilation.

---

## ⭐ Key Features

- **⚡ Single-Option Auto-Proceed**: If a menu step has only 1 available choice, the CLI automatically selects it and proceeds without blocking you.
- **🚀 Immediate QA Link Generation**: Fast beta uploads (Google Drive and Diawi) complete first so you get shareable download links in under 20 seconds, while long store processing (TestFlight/Play Store) continues.
- **🛡️ Resilient iOS Signing Fallback**: If code signing fails during build, the script automatically falls back to Unsigned Archive export (`--no-codesign`) for Xcode Organizer rather than crashing.
- **💾 Session Memory**: Saves all settings to `.deploy_last_session.conf` for 1-click re-runs.

---

## 📂 Google Drive Folder Structure

When uploading APKs to Google Drive, the CLI automatically creates and organizes files in the following nested hierarchy:

```text
<Google_Drive_Root>/
└── impero/
    └── the_birth_code/
        └── apk/
            ├── staging/
            │   └── TBC_staging_1.0.0_24_11-15_AM_16_Sep.apk
            ├── qa/
            │   └── TBC_qa_1.0.0_24_11-15_AM_16_Sep.apk
            └── prod/
                └── TBC_prod_1.0.0_24_11-15_AM_16_Sep.apk
```

---

## 💻 CLI Command Flags (Headless & CI/CD)

You can pass command-line flags to run `deploy.sh` headlessly in CI/CD pipelines:

| Flag | Description | Allowed Values |
| :--- | :--- | :--- |
| `-f, --flavor` | Target Environment | `staging`, `qa`, `prod`, `ngrok` |
| `-p, --platform` | Target Packages | `apk`, `appbundle`, `ipa`, `nosign` |
| `-v, --version` | Explicit Version | `a1.0.0+24` (Android), `i1.0.0+24` (iOS) |
| `-u, --upload` | Distribution Destinations | `playstore`, `gdrive`, `appstore`, `diawi`, `none` |
| `--dry-run` | Validate configs without building | N/A |
| `--no-clean` | Skip `flutter clean` step | N/A |
| `-V, --verbose` | Stream raw Flutter logs | N/A |
| `-h, --help` | Display CLI help menu | N/A |

### CI/CD Examples:

```bash
# Validate settings without compiling:
./deploy.sh --dry-run -f staging -p apk ipa

# Build Staging APK & IPA for local testing:
./deploy.sh -f staging -p apk ipa -u gdrive diawi

# Build Production AAB & IPA and upload to App Stores:
./deploy.sh -f prod -p appbundle ipa -u playstore appstore -v a1.0.0+24 i1.0.0+24
```

---

## 🔐 Configuration & Credentials (`.build-config.env`)

Project credentials and store API keys are managed in `.build-config.env` (auto-generated on first run if missing):

```ini
# App Identifiers
IOS_BUNDLE_ID="com.thebirthcode.sqr.dev"
ANDROID_PACKAGE_NAME="com.thebirthcode.sqr"

# Apple App Store Connect API Key (.p8)
APPLE_API_KEY_ID="TPZCQM5978"
APPLE_API_ISSUER_ID="YOUR_ISSUER_UUID"
APPLE_API_KEY_PATH="output/secret/AuthKey_TPZCQM5978.p8"

# Google Play Service Account JSON
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="output/secret/google-play-service-account.json"

# Distribution Gateways
GDRIVE_BASE_FOLDER_ID=""
DIAWI_TOKEN=""
```

---

## ❓ Troubleshooting & FAQs

### Q1: Xcode Organizer throws "Team is not selected" error.
- **Cause**: The archive was built with `--no-codesign` or your Apple Developer account is not signed in inside Xcode.
- **Solution**:
  1. Open Xcode ➜ **Settings** ➜ **Accounts** ➜ Sign in with your Apple ID.
  2. In `deploy.sh`, select **iOS Signed IPA** instead of Unsigned Archive.

### Q2: Google Drive upload session expired.
- Run Google Workspace CLI setup:
  ```bash
  ./deploy.sh --gdrive-setup
  ```
- Or reset auth:
  ```bash
  ./deploy.sh --gdrive-reset
  ```

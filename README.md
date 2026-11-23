<div align="center">
  <h1>🛠 My Dev Tools</h1>
  <p><strong>A Cross-Platform Automated Mobile Build & Release Engine</strong></p>
</div>

Welcome to the central repository for the automated Mobile Build & Release Engine! This tool streamlines generating Android (APK/AAB) and iOS (IPA/Archive) builds across your Flutter projects and automatically deploys them to local directories or third-party distribution gateways like Google Drive and Diawi.

---

## ⚡ Quick Start (Remote Installation)

You do not need to clone this entire repository into your project. Simply run the command below inside any Flutter project's root directory to download and launch the build engine.

### 🍎 macOS / Linux (Bash)
*Compiles Android and iOS. Uploads to Google Drive and Diawi.*

```bash
curl -fsSL https://raw.githubusercontent.com/vijayimpero-flutter/my-dev-tools/refs/heads/main/build-mac.sh -o build-mac.sh && chmod +x build-mac.sh && ./build-mac.sh
```

### 🪟 Windows (PowerShell)
*Compiles Android only. Uploads to Google Drive.*

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vijayimpero-flutter/my-dev-tools/refs/heads/main/build-windows.ps1" -OutFile "build-windows.ps1"; .\build-windows.ps1
```

---

## ⚙️ How to Use the Build Engine (3-Step Setup)

The scripts are completely **project-agnostic**. They do not contain any hardcoded bundle IDs, package names, or API tokens. 

### Step 1: Download the Script
Run the `curl` or `Invoke-WebRequest` command above inside your project's root folder. This downloads the script and tries to execute it.

### Step 2: Setup Configuration
Because this is the first time you are running the script in this project, it will pause and automatically generate a `.build-config.env` template file in your project root.
1. Open `.build-config.env` in your editor.
2. Fill out your project's specific bundle IDs, Google Drive Folder IDs, Diawi Token, and point to your API key files.

> [!CAUTION]
> **Important:** Ensure you add `.build-config.env` to your project's `.gitignore` to avoid leaking your tokens!

### Step 3: Run the Engine
Now that your credentials are saved, simply run the script again:

**Mac:**
```bash
./build-mac.sh
```

**Windows:**
```powershell
.\build-windows.ps1
```

The interactive menu will appear, and you can compile and upload your builds!

---

## 🚀 Supported Distribution Gateways

### 1. Google Drive (APK)
Uploads builds directly to a specified Google Drive folder using the Google Workspace CLI (`gws`). 

**Step A: Get your Google Drive Folder ID**
1. Open Google Drive in your web browser.
2. Navigate to or create the specific folder where you want your APKs to be uploaded.
3. Look at the URL in your browser's address bar. It will look like `https://drive.google.com/drive/folders/1V1K_A...`
4. Copy that long string of characters at the end of the URL.
5. Paste it into your `.build-config.env` as `GDRIVE_BASE_FOLDER_ID`.

**Step B: Google Cloud OAuth & Permissions**
Because the CLI uses Google Workspace APIs, it must be authenticated as an approved user.
1. Your Google Cloud Administrator must go to the Google Cloud Console and add your exact email address under **APIs & Services > OAuth consent screen > Test users**. (If you skip this, you will get an `Error 403: access_denied` when you try to log in).
2. Run the build script with the `--integrate-gdrive` flag to authorize your terminal.
> [!IMPORTANT]  
> During the OAuth web consent, you **MUST explicitly check the box** for *"See, edit, create, and delete all of your Google Drive files"*.

### 2. Diawi (iOS IPA Only)
Uploads iOS builds to Diawi for quick internal sharing.

**Step A: Get your Diawi API Token**
1. Go to the Diawi Dashboard (https://dashboard.diawi.com).
2. In the top right menu, go to **Profile > API** (https://dashboard.diawi.com/profile/api).
3. Generate and copy your API token.
4. Paste it into your `.build-config.env` as `DIAWI_TOKEN`.

> [!WARNING]  
> Diawi's free tier has a strict **50MB** file limit. Because Flutter Android APKs typically exceed 80MB, Diawi distribution is strictly restricted to iOS `.ipa` files in this engine. Use Google Drive for your Android APKs.

### 3. Google Play Console & Apple App Store (Official Releases)
For official store releases, the script requires secure API keys to bypass manual uploads. Because these are highly sensitive, they should be stored in a dedicated `private_keys/` folder.

**Step A: Setup Private Keys Directory**
1. Create a folder named `private_keys/` in the root of your Flutter project.
2. Add `private_keys/` to your `.gitignore` file immediately.

**Step B: Google Play Console (Android)**
1. Go to the Google Cloud Console and generate a **Service Account JSON Key** with permissions to publish apps on Google Play.
2. Download the `.json` file and place it inside your `private_keys/` folder.
3. Add the filename (e.g., `google-play.json`) to your `.build-config.env` under `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.

**Step C: Apple App Store Connect (iOS)**
1. Go to **App Store Connect > Users and Access > Keys**.
2. Generate a new API Key with **App Manager** access.
3. Download the `.p8` file and place it inside your `private_keys/` folder.
4. Copy the **Key ID** and **Issuer ID** from the App Store Connect page.
5. Paste them into your `.build-config.env` under `APPLE_API_KEY_ID` and `APPLE_API_ISSUER_ID`.

---

## 💻 Advanced Command Line Flags

You can bypass the interactive wizard for specific maintenance tasks by passing arguments:

| Flag | Description |
| :--- | :--- |
| `-p, --platform` | Target platforms. Accepts `apk`, `appbundle`, `ipa`, `nosign`. (e.g. `-p apk,ipa`) |
| `-f, --flavor` | Specify build flavor (e.g., `-f production`) |
| `-v, --version` | Explicitly override versions. Prefix `a` for Android, `i` for iOS. (e.g. `-v a1.0.0+2,i1.0.0+9`) |
| `-u, --upload` | Specify upload gateways. Accepts `playstore`, `appstore`, `gdrive`, `diawi`. |
| `-i, --interactive`| Force the interactive wizard to appear, overriding other CLI selections. |
| `--no-clean` | Skip the `flutter clean` phase to speed up consecutive local builds. |
| `--dry-run` | Validate paths, configurations, and tools without actually executing the flutter build. |
| `-V, --verbose` | Disable the loading spinner and stream raw `flutter build` output directly to the terminal. |
| `--integrate-gdrive`| Force Google Drive OAuth setup and API validation. |
| `--deintegrate-gdrive`| Safely wipe all Google Drive CLI credentials from the machine. |
| `-h, --help` | Display the command manual directly in your terminal. |

*(For Windows, use `.\build-windows.ps1` with the same flags).*

### 🛠 Example Workflows (Bypassing the Interactive Menu)

You can completely bypass the UI and automate builds (perfect for CI/CD pipelines or fast local testing) by combining these flags.

**Example 1: Build an APK and upload to Google Drive immediately**
```bash
./build-mac.sh -p apk -u gdrive
```

**Example 2: Build a production AppBundle and push to Google Play Console**
```bash
./build-mac.sh -p appbundle -f production -u playstore
```

**Example 3: Build an iOS IPA, skip the workspace clean (faster), and upload to Diawi**
```bash
./build-mac.sh -p ipa --no-clean -u diawi
```

**Example 4: Full CI/CD Release (Android AAB + iOS IPA to App Stores)**
```bash
./build-mac.sh -p appbundle,ipa -f production -u playstore,appstore -v a1.0.2+15,i1.0.2+15
```

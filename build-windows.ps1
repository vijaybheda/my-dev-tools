# Requires -Version 5.1
$ErrorActionPreference = "Stop"

function Write-Heading ($text) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Info ($text) { Write-Host "[ℹ] $text" -ForegroundColor Blue }
function Write-Success ($text) { Write-Host "[✔] $text" -ForegroundColor Green }
function Write-Warning ($text) { Write-Host "[⚠] $text" -ForegroundColor Yellow }
function Write-ErrorCard ($title, $cause) { 
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║  ✘ BUILD PIPELINE ERROR: $title" -ForegroundColor Red
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "║  Reason: $cause" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    exit 1
}

$ConfigFile = ".build-config.env"
if (-not (Test-Path $ConfigFile)) {
    Write-Warning "No .build-config.env found! Generating a template..."
    @"
# ==============================================================================
#  BUILD ENGINE CONFIGURATION
#  Fill this out with your project-specific credentials before running the build.
# ==============================================================================

# App Identifiers
IOS_BUNDLE_ID="com.yourcompany.app"
ANDROID_PACKAGE_NAME="com.yourcompany.app"

# Apple App Store Connect API Key (.p8)
APPLE_API_KEY_ID=""
APPLE_API_ISSUER_ID=""

# Google Play Service Account (Place JSON in private_keys/)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=""

# Distribution Gateways
GDRIVE_BASE_FOLDER_ID=""
DIAWI_TOKEN=""
"@ | Out-File $ConfigFile -Encoding UTF8
    Write-Info "Please fill out $ConfigFile and run the script again."
    exit 1
}

# Parse env file manually
Get-Content $ConfigFile | Foreach-Object {
    if ($_ -match '^\s*([^#\s][^=]+)="?(.*?)"?\s*$') {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
    }
}

$GDRIVE_BASE_FOLDER_ID = $Env:GDRIVE_BASE_FOLDER_ID

# Check for args (integration)
if ($args[0] -eq "--integrate-gdrive" -or $args[0] -eq "--gdrive-setup") {
    Write-Info "Launching Google Workspace Setup..."
    if (-not (Get-Command gws -ErrorAction SilentlyContinue)) {
        Write-Info "Installing @googleworkspace/cli via npm..."
        npm install -g @googleworkspace/cli
    }
    gws auth setup
    exit 0
}
if ($args[0] -eq "--deintegrate-gdrive" -or $args[0] -eq "--gdrive-reset") {
    Write-Info "Resetting Google Workspace configuration..."
    $gwsPath = Join-Path $HOME ".config\gws"
    if (Test-Path $gwsPath) { Remove-Item -Recurse -Force $gwsPath }
    Write-Success "Done. Google Drive upload has been de-integrated locally."
    exit 0
}

Write-Heading "Vesper Capital — MOBILE BUILD ENGINE (Windows)"

$flutterCmd = if (Get-Command fvm -ErrorAction SilentlyContinue) { "fvm flutter" } else { "flutter" }

# Target Selection
Write-Host "Select Target Architecture:" -ForegroundColor Cyan
Write-Host "1. Android (APK Only)"
Write-Host "2. Android (AppBundle - AAB) (Requires Play Console configuration)"
$targetChoice = Read-Host "Enter option (1 or 2)"

$BUILD_APK = $false
$BUILD_AAB = $false
if ($targetChoice -eq '1') { $BUILD_APK = $true }
elseif ($targetChoice -eq '2') { $BUILD_AAB = $true }
else { Write-ErrorCard "Invalid Selection" "You must select a valid target." }

# Distribution Selection
Write-Host ""
Write-Host "Select automated release distribution destination:" -ForegroundColor Cyan
Write-Host "1. Local Build Only (Do not upload)"
Write-Host "2. Google Drive (APK Only)"
$distChoice = Read-Host "Enter option (1 or 2)"

$UPLOAD_GDRIVE = $false
if ($distChoice -eq '2') {
    $UPLOAD_GDRIVE = $true
    if (-not $BUILD_APK) { $BUILD_APK = $true }
}

# Phase 1: Sanitation
Write-Heading "Phase 1: Workspace Sanitation & Dependency Sync"
Write-Info "Purging build telemetry and project caches..."
Invoke-Expression "$flutterCmd clean"
Write-Info "Resolving remote pub dependency tree mappings..."
Invoke-Expression "$flutterCmd pub get"

# Phase 2: Compilation
Write-Heading "Phase 2: Platform Engine Native Compilation"
$FINAL_APK_PATH = ""
$FINAL_AAB_PATH = ""

if ($BUILD_APK) {
    Write-Info "Compiling Android Release Package (APK)..."
    try {
        Invoke-Expression "$flutterCmd build apk --release"
    } catch {
        Write-ErrorCard "Compilation Failed" "Flutter failed to build the APK."
    }
    
    $defaultApk = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $defaultApk) {
        $timestamp = Get-Date -Format "hh-mm_tt_dd_MMM"
        $newApkPath = "output\android\VC_$timestamp.apk"
        if (-not (Test-Path "output\android")) { New-Item -ItemType Directory -Force -Path "output\android" | Out-Null }
        Copy-Item $defaultApk -Destination $newApkPath
        $FINAL_APK_PATH = $newApkPath
        Write-Success "APK Saved: $newApkPath"
    } else {
        Write-ErrorCard "Compilation Failed" "APK artifact was not generated in $defaultApk."
    }
}

if ($BUILD_AAB) {
    Write-Info "Compiling Android App Bundle (AAB)..."
    try {
        Invoke-Expression "$flutterCmd build appbundle --release"
    } catch {
        Write-ErrorCard "Compilation Failed" "Flutter failed to build the AppBundle."
    }

    $defaultAab = "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $defaultAab) {
        $timestamp = Get-Date -Format "hh-mm_tt_dd_MMM"
        $newAabPath = "output\android\VC_$timestamp.aab"
        if (-not (Test-Path "output\android")) { New-Item -ItemType Directory -Force -Path "output\android" | Out-Null }
        Copy-Item $defaultAab -Destination $newAabPath
        $FINAL_AAB_PATH = $newAabPath
        Write-Success "AAB Saved: $newAabPath"
    } else {
        Write-ErrorCard "Compilation Failed" "AAB artifact was not generated in $defaultAab."
    }
}

# Phase 3: Distribution
if ($UPLOAD_GDRIVE) {
    Write-Heading "Phase 3: Gateway Store Distribution Pipeline"
    if (-not $FINAL_APK_PATH) {
        Write-ErrorCard "Missing Artifact" "No APK found to upload to Google Drive."
    }
    
    if (-not (Get-Command gws -ErrorAction SilentlyContinue)) {
        Write-Info "Google Workspace CLI not found. Installing now..."
        npm install -g @googleworkspace/cli
    }
    
    Write-Info "Uploading binary to Google Drive..."
    $gdriveOut = "gdrive_out_$PID.txt"
    $gwsCmd = "gws drive files upload --upload ""$FINAL_APK_PATH"" --params '{""parents"":[""$GDRIVE_BASE_FOLDER_ID""]}'"
    
    try {
        Invoke-Expression "$gwsCmd > $gdriveOut 2>&1"
    } catch {
        Write-ErrorCard "Google Drive Upload Failed" "Failed to execute gws command."
    }
    
    $GDRIVE_LINK = ""
    if (Test-Path $gdriveOut) {
        $output = Get-Content $gdriveOut
        foreach ($line in $output) {
            if ($line -match "https://[^\s]+" -and $line -match "drive.google.com") {
                $GDRIVE_LINK = $matches[0]
                break
            }
        }
        Remove-Item -Force $gdriveOut -ErrorAction SilentlyContinue
    }
    
    if ($GDRIVE_LINK) {
        Write-Success "Google Drive Link: $GDRIVE_LINK"
    } else {
        Write-ErrorCard "Google Drive Upload Failed" "No shareable link found in output. Ensure your Folder ID is correct and you have run --integrate-gdrive."
    }
}

Write-Heading "🎉 PIPELINE SUITE EXECUTED SUCCESSFULLY"

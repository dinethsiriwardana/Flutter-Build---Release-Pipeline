# 🚀 Flutter CI/CD — Unified Multi-Platform Release (iOS & Android)

This document explains how to set up, configure, and use the **`release.yml`** GitHub Actions workflow for your **Flutter Mobile** project.

---

## 📋 Overview

The workflow automates the full Android and iOS release pipeline whenever code is pushed to the `release` branch:

```mermaid
graph TD
    push[Push to release] --> setup["setup <br> (deps, lint/test, code-gen, version bump)"]
    
    setup --> build_android["build-android <br> (Dev APK & Prod AAB)"]
    setup --> build_ios["build-ios <br> (Dev/Prod & TestFlight)"]
    
    build_android --> distribute["distribute-firebase <br> (Firebase App Distribution)"]
    distribute --> upload_playstore["upload-playstore <br> (Play Store Internal Track)"]
    
    upload_playstore --> release["release <br> (GitHub Release with artifacts)"]
    build_ios --> release
```

| Job | Purpose | Environment |
|-----|---------|-------------|
| `setup` | Increments version, resolves deps, runs tests/lints, `build_runner` | — |
| `build-android` | Builds Dev APK and Prod AAB | **Dev/Prod** (`.env` / `.prod.env`) |
| `build-ios` | Builds Dev and Prod IPA, uploads to TestFlight | **Dev/Prod** (`.env` / `.prod.env`) |
| `distribute-firebase`| Uploads APK to Firebase App Distribution | — |
| `upload-playstore`| Uploads AAB to Google Play Store (Internal Track) | — |
| `release` | Creates a tagged GitHub Release with zipped artifacts | — |

---

## ⚙️ Prerequisites

### 1. Android Keystore
Generate a release keystore and encode it to Base64 for the `KEYSTORE_BASE64` secret.

### 2. Apple Code Signing
You need an Apple Developer account with Distribution certificates and Provisioning Profiles for the main app and any extensions (e.g., Live Activities).
Encode the `.p12` certificate and `.mobileprovision` profiles to Base64.

### 3. Firebase & Play Store
- Firebase App ID and CI token for App Distribution.
- Google Play Store Service Account JSON for automated uploads.

### 4. GitHub Repository Secrets

Navigate to your repo → **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret Name | Description |
|---|---|
| `REPO_ACCESS_TOKEN` | GitHub PAT for updating repository variables (version bump) |
| `KEYSTORE_BASE64` | Base64-encoded `.jks` keystore file |
| `KEY_STORE_PASSWORD` | Keystore store password |
| `KEY_ALIAS` | Keystore key alias |
| `KEY_PASSWORD` | Keystore key password |
| `BUILD_CERTIFICATE_BASE64` | Base64 Apple Distribution `.p12` certificate |
| `P12_PASSWORD` | Password for the `.p12` certificate |
| `KEYCHAIN_PASSWORD` | Temporary password for the macOS runner keychain |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 provisioning profile for the main app |
| `BUILD_PROVISION_PROFILE_LIVE_BASE64` | Base64 provisioning profile for Live Activities |
| `APPSTORE_ISSUER_ID` | App Store Connect API Issuer ID |
| `APPSTORE_API_KEY_ID` | App Store Connect API Key ID |
| `APPSTORE_API_PRIVATE_KEY` | App Store Connect API Private Key |
| `FIREBASE_APP_ID` | Firebase Android App ID |
| `FIREBASE_TOKEN` | Firebase CI token |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play Store Service Account JSON |
| `ANDROID_PACKAGE_NAME` | Android application package name |
| `DEV_ENV_FILE` | Full contents of the **dev** `.env` file |
| `ENV_FILE` | Full contents of the **prod** `.prod.env` file |

> [!NOTE]
> `DEV_ENV_FILE` and `ENV_FILE` must contain the **raw plaintext contents** of your environment files (do not base64 encode them). You can push them easily using the GitHub CLI:
> ```bash
> gh secret set DEV_ENV_FILE < .env
> gh secret set ENV_FILE < .prod.env
> ```

### 5. GitHub Repository Variables
Add these under **Settings → Secrets and variables → Actions → Variables**:
- `APP_V_MAJOR` (e.g., `1`)
- `APP_V_MINOR` (e.g., `0`)
- `APP_V_PATCH` (e.g., `5`)
- `APP_V_BUILDNO` (e.g., `42`)
- `FLUTTER_VERSION` (e.g., `3.41.3`)
- `IOS_TEAM_ID` (e.g., `JWAJ23K392`)
- `IOS_MAIN_PROFILE` (e.g., `App Distribution`)

#### CLI Command to initialize all variables:
Alternatively, you can run this single command to create all repository variables at once (replace value placeholders as needed):
```bash
for var in \
  "APP_V_MAJOR=1" \
  "APP_V_MINOR=0" \
  "APP_V_PATCH=0" \
  "APP_V_BUILDNO=1" \
  "FLUTTER_VERSION=3.41.3" \
  "IOS_TEAM_ID=JWAJ23K392" \
  "IOS_MAIN_PROFILE=App Distribution"
do
  gh variable set "${var%%=*}" -b "${var#*=}"
done
```

---

# Template Setup Guide

This guide explains how to integrate this CI/CD release template into any Flutter application. The pipeline automates building and releasing for both Android (Play Store/Firebase App Distribution) and iOS (TestFlight).

## 1. Copy Workflow Files
Copy the `.github` directory from this template to the root of your Flutter project repository.
This includes:
- `.github/workflows/`: Contains the main `release.yml` and reusable modular jobs.
- `.github/actions/`: Contains composite actions for environment setup and failure reporting.

## 2. Update Branch Name (Optional)
By default, the unified release workflow triggers on pushes to the `release` branch. 
If your release branch has a different name (e.g., `main` or `production`), open `.github/workflows/release.yml` and update the branch name under the `on: push: branches:` section.

## 3. Configure Repository Variables
Go to your GitHub Repository Settings > Secrets and variables > Actions > Variables, and create the following:

- `APP_V_MAJOR` (e.g., `1`)
- `APP_V_MINOR` (e.g., `0`)
- `APP_V_PATCH` (e.g., `0`)
- `APP_V_BUILDNO` (e.g., `1`)
- `FLUTTER_VERSION` (e.g., `3.19.0`)
- `IOS_TEAM_ID` (Your Apple Developer Team ID, e.g., `JWAJ11K392`)
- `IOS_MAIN_PROFILE` (The name of your main provisioning profile, e.g., `App Distribution`)

*Note: For a quick setup script, refer to the [README.md](README.md) CLI command section.*

## 4. Configure Repository Secrets
Go to your GitHub Repository Settings > Secrets and variables > Actions > Secrets, and create the required secrets:

**Android & General:**
- `DEV_ENV_FILE`: Base64 encoded contents of your `.env` (Development) file.
- `ENV_FILE`: Base64 encoded contents of your `.prod.env` (Production) file.
- `FIREBASE_APP_ID`: Your Firebase App ID.
- `FIREBASE_TOKEN`: Your Firebase CLI token.
- `KEYSTORE_BASE64`: Base64 encoded `.jks` keystore file for Android signing.
- `KEY_ALIAS`: Keystore alias.
- `KEY_PASSWORD`: Keystore key password.
- `STORE_PASSWORD`: Keystore store password.
- `PLAY_STORE_CONFIG_JSON`: Base64 encoded Google Play Service Account JSON.

**iOS Specific:**
- `BUILD_CERTIFICATE_BASE64`: Base64 encoded `.p12` iOS distribution certificate.
- `P12_PASSWORD`: Password for the `.p12` certificate.
- `KEYCHAIN_PASSWORD`: A random password for the temporary GitHub Actions keychain.
- `BUILD_PROVISION_PROFILE_BASE64`: Base64 encoded `.mobileprovision` file for the main app.
- `APPSTORE_ISSUER_ID`: App Store Connect API Issuer ID.
- `APPSTORE_API_KEY_ID`: App Store Connect API Key ID.
- `APPSTORE_API_PRIVATE_KEY`: App Store Connect API Private Key (`.p8` file content).

*For a detailed step-by-step on generating the iOS certificates and profiles, see the [iOS Secrets Setup Guide](setup_ios_secrets_guide.md).*

## 5. Firebase App Distribution Groups
By default, the `job_distribute_firebase.yml` workflow distributes the Android APK to a tester group named `testers`. 
If you use a different group name in Firebase App Distribution, open `.github/workflows/job_distribute_firebase.yml` and update the `groups:` field to match yours.

## 6. Run Your First Pipeline
Commit and push your code to the `release` branch. Monitor the "Actions" tab in your GitHub repository to watch the pipeline execute!

---

---

## 🔄 Triggering the Workflow

The workflow triggers **automatically** on every push to the `release` branch. 
It uses a `concurrency` group to ensure simultaneous pushes queue safely, preventing version bumping race conditions.

---

## 🧩 Key Design Decisions & Optimizations

### Modular Architecture
- **Reusable Workflows**: The pipeline is broken down into isolated `job_*.yml` workflows (located directly in `.github/workflows/`). The main `release.yml` serves purely as an orchestrator.
- **Composite Actions**: We extract repetitive tasks to `.github/actions/` to reduce boilerplate:
  - `setup-flutter-env`: Installs Java, Flutter, and handles all caching (`pub`, `cocoapods`, `DerivedData`).
  - `bump-version`: Evaluates and persists the new version to GitHub repository variables.
  - `report-failure`: Standardized issue creation and run cancellation.
  - `setup-env-files`: Injects `.env` and `.prod.env` files reliably across jobs.

### Extracted Scripts
- **iOS Signing**: Instead of inline YAML scripts, the complex `xcodeproj` logic is extracted to `scripts/configure_ios_signing.rb`. This makes it highly readable and testable.

### Quality Gates
- The `setup` job executes `flutter analyze --fatal-infos` and `flutter test`. If these fail, expensive mobile builds are preemptively skipped.

### ✨ Unique Pipeline Features

We implemented several advanced techniques to solve common Flutter CI/CD pain points. Below is a detailed look at the unique solutions in this pipeline:

#### 1. Stateful Versioning via GitHub Variables
**The Problem:** Traditional pipelines often increment versions by modifying `pubspec.yaml` and committing it back to the repository. This causes messy git histories, merge conflicts, and can trigger infinite CI loops.
<br/>
**Our Solution:** We completely decoupled the version from the repository files. We use GitHub Repository Variables (`APP_V_PATCH`, `APP_V_BUILDNO`) to track the state. 
During the `setup` phase, a script uses `gh variable set` (authenticated via a PAT) to increment these numbers. The workflow then injects them directly into the build tools using `--build-name` and `--build-number`. The repository remains pristine, and the version is always accurate.

#### 2. iOS Extension Version Syncing (Live Activities)
**The Problem:** Apple enforces strict rules that any App Extension (like iOS Widgets or Live Activities) must have the exact same `CFBundleVersion` and `CFBundleShortVersionString` as the main application. When Flutter builds an iOS app using `--build-number=X`, it *only* updates the main `Runner` target, leaving the extensions with mismatched versions (resulting in a TestFlight rejection).
<br/>
**Our Solution:** Right before executing `flutter build ipa`, the workflow explicitly runs Apple's native command-line tool, `agvtool`:
```bash
agvtool new-marketing-version "$VERSION_NAME"
agvtool new-version -all $BUILD_NUMBER
```
The `-all` flag forcefully synchronizes every nested target in the Xcode workspace to the exact version we need, completely eliminating TestFlight mismatch errors.

#### 3. Fail-Fast Workflow Cancellation
**The Problem:** By default, if you have parallel jobs running in GitHub Actions (e.g., Android and iOS building concurrently) and the iOS build fails, the Android build will *continue* to run for another 20 minutes, wasting expensive Action minutes.
<br/>
**Our Solution:** We implemented custom `if: failure()` steps at the end of critical jobs. If a job fails, it doesn't just fail silently—it creates a high-priority GitHub Issue tagging the developer, and then executes:
```bash
gh run cancel ${{ github.run_id }}
```
This API call tells GitHub to instantly abort the entire workflow run, immediately killing any sibling parallel jobs and saving valuable resources.

#### 4. Unified Dual-Environment Build
**The Problem:** Building Dev and Prod environments usually requires maintaining two separate pipelines, or running the pipeline twice, doubling the build time.
<br/>
**Our Solution:** We orchestrated a single pipeline that manages both concurrently. The workflow decodes the `DEV_ENV_FILE` and `ENV_FILE` secrets into local `.env` and `.prod.env` files on the runner. 
It then triggers parallel matrix builds (or sequential steps) injecting the correct variables using `--dart-define-from-file`. For Android, this yields a Dev `.apk` and a Prod `.aab` in a single run. For iOS, it builds and uploads the Dev and Prod `.ipa` files back-to-back, drastically reducing total deployment time.

---

## 🔍 Deep Dive: Jobs & Actions

To maintain clean code and prevent a massive 1,000-line YAML file, the pipeline is heavily modularized. Here is exactly what each component does.

### 🏗️ Jobs (`.github/workflows/`)

1. **`job_setup.yml` (Setup & Quality Gates)**
   - **Trigger:** Runs first.
   - **Action:** Triggers the `bump-version` action to calculate the next release version. It runs `flutter analyze` and `flutter test` to ensure code quality. It also runs `build_runner` to generate any missing code (like Freezed or JSON Serializable classes).
   - **Output:** Passes the `version_name` and `build_number` to all downstream jobs.

2. **`job_build_android.yml` (Android Build)**
   - **Dependencies:** Waits for `setup`.
   - **Action:** Uses the `setup-env-files` action to decode the base64 `.env` secrets. It configures the Java Keystore, builds a Development `.apk` (using `.env`), and a Production `.aab` (using `.prod.env`) in the same run.
   - **Artifacts:** Uploads the `apk` and `aab` to the workflow artifact storage for later jobs.

3. **`job_build_ios.yml` (iOS Build & TestFlight)**
   - **Dependencies:** Waits for `setup`.
   - **Action:** Installs Apple Distribution Certificates and Provisioning Profiles (both Main and Live Activities) into a temporary macOS keychain. It executes the `agvtool` extension version sync, builds the Dev `.ipa`, and uploads it via the App Store Connect API. It then cleans the build folder, builds the Prod `.ipa`, and uploads it.

4. **`job_distribute_firebase.yml` (Firebase QA)**
   - **Dependencies:** Waits for `build-android`.
   - **Action:** Downloads the Dev `.apk` artifact and pushes it to Firebase App Distribution so internal QA testers can test the new build immediately.

5. **`job_upload_playstore.yml` (Play Store Production)**
   - **Dependencies:** Waits for `build-android`.
   - **Action:** Downloads the Prod `.aab` artifact and pushes it to the Google Play Console (Internal Track) using a Service Account JSON key.

6. **`job_release.yml` (GitHub Release)**
   - **Dependencies:** Waits for ALL previous jobs to succeed.
   - **Action:** Zips the Android APK and AAB together with auto-generated release notes, creates a new Git Tag (e.g., `v3.0.16`), and publishes a GitHub Release.

### 🛠️ Composite Actions (`.github/actions/`)

Instead of repeating setup steps across every job, we created custom reusable "Composite Actions":

1. **`setup-flutter-env`**
   - **Purpose:** A single action that installs Java (Zulu 17), downloads the exact Flutter version, and manages aggressive caching for `~/.pub-cache` and CocoaPods to make subsequent builds blazing fast.
   
2. **`bump-version`**
   - **Purpose:** Connects to the GitHub API using a Personal Access Token (`REPO_ACCESS_TOKEN`). It reads the `APP_V_PATCH` and `APP_V_BUILDNO` variables, increments them mathematically, and writes them back to the repository settings so they persist forever without needing a git commit.
   
3. **`setup-env-files`**
   - **Purpose:** Securely reads the `DEV_ENV_FILE` and `ENV_FILE` Base64 secrets, decodes them, and writes `.env` and `.prod.env` into the runner's workspace so `--dart-define-from-file` can read them.
   
4. **`report-failure`**
   - **Purpose:** A fail-fast handler placed at the end of critical jobs. If `if: failure()` is triggered, this action creates a high-priority bug Issue on GitHub with the failure logs and executes `gh run cancel` to terminate any sibling parallel jobs instantly.

---

## 📁 Related Files

| File | Description |
|---|---|
| [`release.yml`](./release.yml) | The main CI/CD workflow orchestrator |
| [`job_*.yml`](./) | Reusable workflows for each platform/task |
| [`../actions/setup-flutter-env/action.yml`](../actions/setup-flutter-env/action.yml) | Flutter setup composite action |
| [`../actions/bump-version/action.yml`](../actions/bump-version/action.yml) | Version bump composite action |
| [`../../scripts/configure_ios_signing.rb`](../../scripts/configure_ios_signing.rb) | Xcode manual signing Ruby script |
| [`../../pubspec.yaml`](../../pubspec.yaml) | Flutter project dependencies |

# Guide to Setting Up iOS Secrets for GitHub Actions

Since GitHub Action runners start fresh every time, they don't have your Xcode credentials. We need to manually provide the Apple certificates and provisioning profiles as GitHub Secrets.

Here is the step-by-step process for getting each of the 7 new secrets. 

*(Note: `ENV_FILE` is already set up from your Android workflow, so we skip it here!)*

### Step 1: Create & Export your Apple Distribution Certificate (`.p12`)
This certificate proves you are authorized to build the app for production.

> **Note:** If you already have an `Apple Distribution` cert visible under `My Certificates` in Keychain Access (with a private key arrow), you can skip to sub-step 7 and export it directly. If not (e.g. the limit is reached or it was created on another machine), follow the full CLI flow below.

#### Option A — Full CLI Flow (when cert doesn't exist locally)

**1a. Generate a CSR and private key on your Mac:**
```bash
openssl req -nodes -newkey rsa:2048 \
  -keyout ~/Downloads/distribution.key \
  -out ~/Downloads/distribution.csr \
  -subj "/emailAddress=YOUR@EMAIL.com/CN=App Distribution/C=US"
```

**1b. Upload the CSR to Apple Developer Portal:**
1. Go to [developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list)
2. If the `+` button says **"Maximum number of certificates generated"**, revoke one of the existing API Key Distribution certs (safe to revoke — they are auto-managed)
3. Click `+` → select **Apple Distribution** → **Continue**
4. Upload `~/Downloads/distribution.csr` → **Continue** → **Download**
5. Save the downloaded `.cer` file to `~/Downloads/distribution.cer`

**1c. Convert the `.cer` + `.key` into a `.p12` bundle:**
```bash
# Convert .cer to PEM
openssl x509 -in ~/Downloads/distribution.cer -inform DER \
  -out ~/Downloads/distribution.pem -outform PEM

# Bundle .pem + private key into a .p12
# Choose your own password — it becomes P12_PASSWORD
openssl pkcs12 -export \
  -out ~/Downloads/distribution.p12 \
  -inkey ~/Downloads/distribution.key \
  -in ~/Downloads/distribution.pem \
  -name "Apple Distribution: Equine Network, LLC" \
  -passout pass:YOUR_CHOSEN_PASSWORD
```

**1d. Base64 encode the `.p12` and copy to clipboard:**
```bash
base64 -i ~/Downloads/distribution.p12 | pbcopy
```
- **The clipboard contents become your `BUILD_CERTIFICATE_BASE64` secret.**
- **The password you chose above becomes your `P12_PASSWORD` secret.**

#### Option B — Keychain Export (if cert already exists locally)
1. Open **Keychain Access** → **My Certificates**
2. Find **"Apple Distribution: Equine Network, LLC"** (must have a ▶ arrow showing the private key)
3. Right-click the certificate → **Export** → save as `distribution.p12` → set a password
4. Run:
   ```bash
   base64 -i ~/Downloads/distribution.p12 | pbcopy
   ```
   - **Clipboard = `BUILD_CERTIFICATE_BASE64`**, password = **`P12_PASSWORD`**

---

### Step 2: Download your Provisioning Profile (`.mobileprovision`)
This file tells Apple that your app ID is allowed to be signed by the certificate above.

1. Log into your [Apple Developer Account](https://developer.apple.com/account/).
2. Go to **Certificates, Identifiers & Profiles**.
3. Click on **Profiles** on the left sidebar.
4. Find the **App Store** (Distribution) profile for your app's bundle ID. 
   
   > [!IMPORTANT]
   > **Certificate Linkage:** Ensure the profile is linked to the **correct, active Distribution Certificate** (the one from Step 1). 
   > - If you generated a *new* certificate to replace an old/expired one (e.g., changing from an older cert to a newly generated one expiring in July 2027), you must edit the existing profile, **uncheck the old certificate**, **check the new certificate**, click **Save**, and then download the new profile. 
   > - If this is not done, Xcode will fail with a mismatch error (i.e., the profile will not recognize the new signing certificate).

5. Click **Download** and save the `.mobileprovision` file to your Desktop.
6. Open your Terminal and run this command to convert it to Base64:
    ```bash
    base64 -i ~/Desktop/YourProfile.mobileprovision -o ~/Desktop/Profile_Base64.txt
    ```
7. Open `Profile_Base64.txt`. Copy the ENTIRE block of text.
    - **This text becomes your `BUILD_PROVISION_PROFILE_BASE64` secret.**

---

### Step 3: Generate an App Store Connect API Key (`.p8`)
This allows the GitHub Action to upload the built `.ipa` directly to TestFlight without needing 2-Factor Authentication (SMS).

1. Log into [App Store Connect](https://appstoreconnect.apple.com/).
2. Go to **Users and Access**, then click the **Integrations** tab at the top.
3. Click on **App Store Connect API** on the left sidebar.
4. If you haven't requested access to the API yet, do so. Otherwise, click the **`+`** button to generate a new key.
5. Name it something like `GitHub Actions CI` and give it the **App Manager** role.
6. Once created, you will see a table with your new key.
7. Note the **Issuer ID** at the top of the page.
   - **This becomes your `APPSTORE_ISSUER_ID` secret.**
8. Note the **Key ID** in the row of the key you just made.
   - **This becomes your `APPSTORE_API_KEY_ID` secret.**
9. Click **Download API Key**. (You can only do this once!). It will download an `.p8` file.
10. Open the `.p8` file in a text editor (like VS Code or TextEdit). Copy ALL the contents, including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.
    - **This text becomes your `APPSTORE_API_PRIVATE_KEY` secret.**

---

### Step 4: Add them all to GitHub

1. Go to your GitHub Repository in your browser.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret** and add them one by one:

| Secret Name | What to put in the value box |
| :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | Output of `base64 -i ~/Downloads/distribution.p12 \| pbcopy` (paste from clipboard) |
| `P12_PASSWORD` | The password you used with `-passout pass:YOUR_CHOSEN_PASSWORD` when creating the `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | The giant text block from `Profile_Base64.txt` |
| `KEYCHAIN_PASSWORD` | Type any random password like `github123` (the runner needs this to unlock the temporary keychain) |
| `APPSTORE_ISSUER_ID` | The Issuer ID from App Store Connect |
| `APPSTORE_API_KEY_ID` | The Key ID from App Store Connect |
| `APPSTORE_API_PRIVATE_KEY` | The exact contents of the `.p8` file |

You're done! Once these 7 secrets are added, any push to `release` will successfully build the app and push it straight to TestFlight.

---

# Guide to Setting up Firebase and Google Play Console

### Firebase App Distribution Integration

The pipeline uses Firebase App Distribution to seamlessly push Development APKs to your QA team.

#### Step 1: Obtain the Firebase App ID
1. Navigate to your Firebase Console > Project Settings > General.
2. Scroll down to your "Your apps" section and select the Android App.
3. Copy the **App ID** (format: `1:1234567890:android:abcdef123456`).
4. Save this in GitHub as the Secret: **`FIREBASE_APP_ID`**.

#### Step 2: Obtain the Firebase CI Token
1. Open your terminal and run `curl -sL https://firebase.tools | bash` to install the Firebase CLI.
2. Run `firebase login:ci`.
3. Complete the authentication flow in your browser. The terminal will output a long refresh token (e.g., `1//0gA...`).
4. Save this in GitHub as the Secret: **`FIREBASE_TOKEN`**.

### Google Play Console Integration

To automate production releases, the workflow uploads the Production AAB directly to the Google Play Store's Internal Track.

#### Step 1: Create a Google Cloud Service Account
1. Go to the [Google Cloud Console](https://console.cloud.google.com/) and select the project linked to your Google Play Console.
2. Navigate to **IAM & Admin > Service Accounts** and click **Create Service Account**.
3. Provide a recognizable name (e.g., `play-store-ci`), grant it the **Service Account User** role, and save.
4. Click on the newly created service account, go to the **Keys** tab > **Add Key** > **Create new key** > **JSON**.
5. Download the JSON file to your local machine.

#### Step 2: Configure the GitHub Secret
1. Open the downloaded JSON file, copy ALL of its contents, and base64 encode it:
   ```bash
   base64 -i play-store-key.json | pbcopy
   ```
2. Save the clipboard output as the GitHub Secret: **`PLAY_STORE_SERVICE_ACCOUNT_JSON`**.

#### Step 3: Grant Play Console Permissions
Ensure that this new Service Account is invited to your Google Play Console. It must be granted "Release" permissions to be able to upload App Bundles to the Internal Track.

---

# 🧩 Template Add-ons

This repository is designed as a core CI/CD template for Flutter apps. Depending on your project's architecture, you may need to add back certain features. This document explains how to re-integrate common add-ons.

---

## 1. Live Activities / iOS App Extensions

If your application uses iOS App Extensions (such as Live Activities, Notification Service Extensions, or WatchOS apps), Apple treats them as separate sub-applications. This means you must sign them with their own provisioning profiles.

### Setup Instructions

1. **Create the Provisioning Profile:**
   Go to your Apple Developer Account, create an App Store Distribution profile for your extension's specific Bundle ID (e.g., `com.yourcompany.app.live-activities`).
2. **Export as Base64:**
   Download the `.mobileprovision` file and run:
   ```bash
   base64 -i ~/Downloads/YourExtensionProfile.mobileprovision | pbcopy
   ```
3. **Add GitHub Secret:**
   Create a new GitHub Repository Secret named `BUILD_PROVISION_PROFILE_LIVE_BASE64` and paste the copied text.
4. **Add GitHub Variable:**
   Create a new GitHub Repository Variable named `IOS_LIVE_PROFILE` with the exact name of the profile (e.g., `com.yourcompany.app.live-activities`).
5. **Modify `job_build_ios.yml`:**
   In `.github/workflows/job_build_ios.yml`, add this step right after installing the main provisioning profile:
   ```yaml
      - name: Install Provisioning Profile (Live Activities Extension)
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.BUILD_PROVISION_PROFILE_LIVE_BASE64 }}" | base64 --decode > /tmp/live.mobileprovision
          UUID=$(security cms -D -i /tmp/live.mobileprovision | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
          cp /tmp/live.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/${UUID}.mobileprovision
   ```
   Then, pass the profile name to your Xcode signing script:
   ```yaml
      - name: Configure Xcode Project for Manual Signing
        env:
          DEVELOPMENT_TEAM: ${{ vars.IOS_TEAM_ID }}
          MAIN_PROFILE_SPECIFIER: ${{ vars.IOS_MAIN_PROFILE }}
          LIVE_ACTIVITY_PROFILE_SPECIFIER: ${{ vars.IOS_LIVE_PROFILE }}
        run: |
          gem install xcodeproj --quiet
          ruby scripts/configure_ios_signing.rb
   ```

---

## 2. Code Generation (`build_runner`)

By default, the `job_setup.yml` file runs `flutter pub run build_runner build --delete-conflicting-outputs`. 

If your Flutter project **does not** use code generation (e.g., `freezed`, `json_serializable`, `riverpod`), this step is unnecessary and will slow down your build or even fail.

### How to Remove
Open `.github/workflows/job_setup.yml` and delete the following lines:
```yaml
      - name: Run build_runner
        run: flutter pub run build_runner build --delete-conflicting-outputs
```
*(You may also remove the `Upload generated code` step in `job_setup.yml` and the `Download generated code` steps in the Android/iOS build jobs to speed up your pipeline even further).*

---

## 3. Dev vs. Prod Environments

This template is configured for a robust enterprise flow: it builds both a **Development** version (using `.env`) and a **Production** version (using `.prod.env`) of your app.

- **Android:** Builds a Dev APK (for Firebase Distribution) and a Prod AAB (for Play Store).
- **iOS:** Builds a Dev IPA and a Prod IPA, both uploaded to TestFlight.

### How to simplify to a single Production build
If you only need a single release build:
1. Provide the same base64 string for both `DEV_ENV_FILE` and `ENV_FILE` secrets.
2. OR manually delete the `Build APK (Dev)` step in `job_build_android.yml` and the `Build iOS IPA (Dev)` step in `job_build_ios.yml`.
3. If you remove the Dev builds, remember to update `job_release.yml` so it only expects and zips the production artifacts.

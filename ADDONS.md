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

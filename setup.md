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

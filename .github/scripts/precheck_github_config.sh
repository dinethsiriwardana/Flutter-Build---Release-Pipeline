#!/bin/bash

echo "============================================="
echo "   GitHub CI/CD Pre-flight Check Tool        "
echo "============================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null
then
    echo "❌ Error: GitHub CLI (gh) is not installed."
    echo "Please install it from https://cli.github.com/ and authenticate using 'gh auth login'."
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null
then
    echo "❌ Error: You are not authenticated with GitHub CLI."
    echo "Please run 'gh auth login' to authenticate before running this script."
    exit 1
fi

echo "🔍 Fetching repository configuration from GitHub..."

# Get list of existing secrets and variables
# Ensure we only get the names (first column) to avoid false positives
EXISTING_SECRETS=$(gh secret list | awk '{print $1}')
EXISTING_VARS=$(gh variable list | awk '{print $1}')

MISSING_VARS=0
MISSING_SECRETS=0

# Define required variables
REQUIRED_VARS=(
  "APP_V_MAJOR"
  "APP_V_MINOR"
  "APP_V_PATCH"
  "APP_V_BUILDNO"
  "FLUTTER_VERSION"
  "IOS_TEAM_ID"
  "IOS_MAIN_PROFILE"
)

# Define required secrets
REQUIRED_SECRETS=(
  "DEV_ENV_FILE"
  "ENV_FILE"
  "FIREBASE_APP_ID"
  "FIREBASE_TOKEN"
  "KEYSTORE_BASE64"
  "KEY_ALIAS"
  "KEY_PASSWORD"
  "STORE_PASSWORD"
  "PLAY_STORE_CONFIG_JSON"
  "BUILD_CERTIFICATE_BASE64"
  "P12_PASSWORD"
  "KEYCHAIN_PASSWORD"
  "BUILD_PROVISION_PROFILE_BASE64"
  "APPSTORE_ISSUER_ID"
  "APPSTORE_API_KEY_ID"
  "APPSTORE_API_PRIVATE_KEY"
)

echo ""
echo "--- Checking Variables ---"
for var in "${REQUIRED_VARS[@]}"; do
  # Use grep with -x for exact match on the line
  if echo "$EXISTING_VARS" | grep -qx "$var"; then
    echo "✅ [OK] $var"
  else
    echo "❌ [MISSING] Variable: $var"
    MISSING_VARS=$((MISSING_VARS + 1))
  fi
done

echo ""
echo "--- Checking Secrets ---"
for secret in "${REQUIRED_SECRETS[@]}"; do
  if echo "$EXISTING_SECRETS" | grep -qx "$secret"; then
    echo "✅ [OK] $secret"
  else
    echo "❌ [MISSING] Secret: $secret"
    MISSING_SECRETS=$((MISSING_SECRETS + 1))
  fi
done

echo ""
echo "============================================="
if [ $MISSING_VARS -eq 0 ] && [ $MISSING_SECRETS -eq 0 ]; then
  echo "🎉 SUCCESS! Your repository is fully configured."
  echo "You are ready to push to the release branch."
  exit 0
else
  echo "⚠️  WARNING: Your repository is missing configuration!"
  echo "Missing Variables: $MISSING_VARS"
  echo "Missing Secrets: $MISSING_SECRETS"
  echo ""
  
  if [ $MISSING_VARS -gt 0 ]; then
      echo "👉 To fix missing variables, run: ./.github/scripts/setup_github_variables.sh"
  fi
  if [ $MISSING_SECRETS -gt 0 ]; then
      echo "👉 To fix missing secrets, manually add them via GitHub Settings."
      echo "   Reference 'setup.md' and 'setup_ios_secrets_guide.md' for instructions."
  fi
  exit 1
fi

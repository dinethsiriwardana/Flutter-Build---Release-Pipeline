#!/bin/bash

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null
then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install it from https://cli.github.com/ and authenticate using 'gh auth login'."
    exit 1
fi

echo "============================================="
echo "   GitHub Repository Variables Setup Tool    "
echo "============================================="
echo "Press Enter to keep the default value in brackets."
echo ""

# Function to prompt for input with a default value
prompt_var() {
  local prompt_text=$1
  local default_val=$2
  local var_name=$3
  
  read -p "$prompt_text [$default_val]: " input
  if [ -z "$input" ]; then
    eval $var_name=\"$default_val\"
  else
    eval $var_name=\"$input\"
  fi
}

prompt_var "Enter APP_V_MAJOR" "1" APP_V_MAJOR
prompt_var "Enter APP_V_MINOR" "0" APP_V_MINOR
prompt_var "Enter APP_V_PATCH" "0" APP_V_PATCH
prompt_var "Enter APP_V_BUILDNO" "1" APP_V_BUILDNO
prompt_var "Enter FLUTTER_VERSION" "3.24.0" FLUTTER_VERSION
prompt_var "Enter IOS_TEAM_ID" "JWAJ11K392" IOS_TEAM_ID
prompt_var "Enter IOS_MAIN_PROFILE" "App Distribution" IOS_MAIN_PROFILE

echo ""
echo "Setting up variables on GitHub..."

gh variable set APP_V_MAJOR -b "$APP_V_MAJOR"
gh variable set APP_V_MINOR -b "$APP_V_MINOR"
gh variable set APP_V_PATCH -b "$APP_V_PATCH"
gh variable set APP_V_BUILDNO -b "$APP_V_BUILDNO"
gh variable set FLUTTER_VERSION -b "$FLUTTER_VERSION"
gh variable set IOS_TEAM_ID -b "$IOS_TEAM_ID"
gh variable set IOS_MAIN_PROFILE -b "$IOS_MAIN_PROFILE"

echo ""
echo "✅ All repository variables have been successfully configured!"

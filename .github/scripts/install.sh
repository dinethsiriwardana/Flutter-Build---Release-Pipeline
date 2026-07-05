#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define styles for printing
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0;0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}======================================================="
echo -e "   Unified Flutter CI/CD Release Pipeline Setup Tool   "
echo -e "=======================================================${NC}"

# Check for required commands
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: Required command '$1' is not installed.${NC}"
        echo "Please install '$1' and try again."
        exit 1
    fi
}

check_command unzip

# Determine download tool
DOWNLOAD_CMD=""
if command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -L -s -o"
elif command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -q -O"
else
    echo -e "${RED}Error: Neither curl nor wget was found on your system.${NC}"
    echo "Please install curl or wget to proceed."
    exit 1
fi

TEMP_ZIP="release-pipeline-v1.0.0.zip"
EXTRACT_DIR="Unified-Flutter-CI-CD-Release-Pipeline-1.0.0"
REPO_URL="https://github.com/dinethsiriwardana/Unified-Flutter-CI-CD-Release-Pipeline/archive/refs/tags/v1.0.0.zip"

echo -e "\n📥 Downloading release files (v1.0.0)..."
if [ "$DOWNLOAD_CMD" = "curl -L -s -o" ]; then
    curl -L -s -o "$TEMP_ZIP" "$REPO_URL"
else
    wget -q -O "$TEMP_ZIP" "$REPO_URL"
fi

echo -e "📦 Extracting files..."
unzip -q "$TEMP_ZIP"

echo -e "📂 Copying pipeline files to project root..."
# Ensure .github structure exists
mkdir -p .github/workflows
mkdir -p .github/actions
mkdir -p .github/scripts

# Copy files
cp -R "$EXTRACT_DIR"/.github/workflows/ .github/workflows/
cp -R "$EXTRACT_DIR"/.github/actions/ .github/actions/
cp -R "$EXTRACT_DIR"/.github/scripts/ .github/scripts/

echo -e "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_ZIP" "$EXTRACT_DIR"

echo -e "🔐 Setting executable permissions on scripts..."
chmod +x .github/scripts/*.sh

echo -e "\n${GREEN}✅ Installation complete!${NC}"
echo -e "The workflows, composite actions, and setup scripts have been installed.\n"

# Check if gh CLI is available for variables configuration
if command -v gh &> /dev/null; then
    echo -e "${BLUE}GitHub CLI (gh) is installed.${NC}"
    read -p "Would you like to run the repository variables configuration script now? (y/N): " run_setup
    if [[ "$run_setup" =~ ^[Yy]$ ]]; then
        ./.github/scripts/setup_github_variables.sh
    else
        echo -e "\nTo set up variables later, run:\n  ${BOLD}./.github/scripts/setup_github_variables.sh${NC}"
        echo -e "  (This script interactively sets up all required repository variables on GitHub using the GitHub CLI)."
    fi
else
    echo -e "To configure repository variables, install the GitHub CLI (gh) and run:\n  ${BOLD}./.github/scripts/setup_github_variables.sh${NC}"
    echo -e "  (This script interactively sets up all required repository variables on GitHub using the GitHub CLI)."
fi

echo -e "\nTo verify your configuration on GitHub, run the precheck script:\n  ${BOLD}./.github/scripts/precheck_github_config.sh${NC}"
echo -e "  (This script validates that all necessary secrets and variables are fully configured on your remote repository).\n"


@echo off
setlocal EnableDelayedExpansion

echo =======================================================
echo    Unified Flutter CI/CD Release Pipeline Setup Tool   
echo =======================================================
echo.

:: Determine if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: PowerShell is required to run this script.
    exit /b 1
)

echo 📥 Downloading release files (v1.0.0)...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/dinethsiriwardana/Unified-Flutter-CI-CD-Release-Pipeline/archive/refs/tags/v1.0.0.zip' -OutFile 'release-pipeline-v1.0.0.zip'"
if %errorlevel% neq 0 (
    echo Error: Failed to download the release zip file.
    exit /b %errorlevel%
)

echo 📦 Extracting files...
powershell -NoProfile -Command "Expand-Archive -Path 'release-pipeline-v1.0.0.zip' -DestinationPath '.'"
if %errorlevel% neq 0 (
    echo Error: Failed to extract the release zip file.
    del /Q "release-pipeline-v1.0.0.zip"
    exit /b %errorlevel%
)

echo 📂 Copying pipeline files to project root...
xcopy /E /I /Y "Unified-Flutter-CI-CD-Release-Pipeline-1.0.0\.github" ".github" >nul

echo 🧹 Cleaning up temporary files...
del /Q "release-pipeline-v1.0.0.zip"
rmdir /S /Q "Unified-Flutter-CI-CD-Release-Pipeline-1.0.0"

echo.
echo ✅ Installation complete!
echo The workflows, composite actions, and setup scripts have been installed.
echo.

:: Check for GitHub CLI
where gh >nul 2>nul
if %errorlevel% eq 0 (
    echo GitHub CLI (gh) is installed.
    set /p "run_setup=Would you like to run the repository variables configuration script now? (y/N): "
    if /I "!run_setup!"=="y" (
        call .\.github\scripts\setup_github_variables.bat
    ) else (
        echo.
        echo To set up variables later, run: .\.github\scripts\setup_github_variables.bat
        echo (This script interactively sets up all required repository variables on GitHub using the GitHub CLI).
    )
) else (
    echo To configure repository variables, install the GitHub CLI (gh) and run: .\.github\scripts\setup_github_variables.bat
    echo (This script interactively sets up all required repository variables on GitHub using the GitHub CLI).
)

echo.
echo To verify your configuration on GitHub, run the pre-check script:
echo   .\.github\scripts\precheck_github_config.bat
echo (This script validates that all necessary secrets and variables are fully configured on your remote repository).
echo.
pause

@echo off
setlocal EnableDelayedExpansion

echo =============================================
echo    GitHub CI/CD Pre-flight Check Tool        
echo =============================================

:: Check if GitHub CLI is installed
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [X] Error: GitHub CLI ^(gh^) is not installed.
    echo Please install it from https://cli.github.com/ and authenticate using 'gh auth login'.
    pause
    exit /b 1
)

:: Check if user is authenticated
gh auth status >nul 2>nul
if %errorlevel% neq 0 (
    echo [X] Error: You are not authenticated with GitHub CLI.
    echo Please run 'gh auth login' to authenticate before running this script.
    pause
    exit /b 1
)

echo [i] Fetching repository configuration from GitHub...
echo.

:: We dump the output of gh to temporary files
gh variable list > temp_vars.txt
gh secret list > temp_secrets.txt

set MISSING_VARS=0
set MISSING_SECRETS=0

echo --- Checking Variables ---
for %%V in (APP_V_MAJOR APP_V_MINOR APP_V_PATCH APP_V_BUILDNO FLUTTER_VERSION IOS_TEAM_ID IOS_MAIN_PROFILE) do (
    :: Find string at the beginning of the line followed by a space (to ensure exact match of the key name)
    findstr /B /C:"%%V " temp_vars.txt >nul
    if !errorlevel! equ 0 (
        echo [OK] %%V
    ) else (
        echo [MISSING] Variable: %%V
        set /a MISSING_VARS+=1
    )
)

echo.
echo --- Checking Secrets ---
for %%S in (DEV_ENV_FILE ENV_FILE FIREBASE_APP_ID FIREBASE_TOKEN KEYSTORE_BASE64 KEY_ALIAS KEY_PASSWORD STORE_PASSWORD PLAY_STORE_CONFIG_JSON BUILD_CERTIFICATE_BASE64 P12_PASSWORD KEYCHAIN_PASSWORD BUILD_PROVISION_PROFILE_BASE64 APPSTORE_ISSUER_ID APPSTORE_API_KEY_ID APPSTORE_API_PRIVATE_KEY) do (
    findstr /B /C:"%%S " temp_secrets.txt >nul
    if !errorlevel! equ 0 (
        echo [OK] %%S
    ) else (
        echo [MISSING] Secret: %%S
        set /a MISSING_SECRETS+=1
    )
)

:: Clean up temp files
del temp_vars.txt
del temp_secrets.txt

echo.
echo =============================================
if %MISSING_VARS% equ 0 if %MISSING_SECRETS% equ 0 (
    echo [SUCCESS] All good! Your repository is fully configured.
    echo You are ready to push to the release branch.
) else (
    echo [WARNING] Your repository is missing configuration!
    echo Missing Variables: %MISSING_VARS%
    echo Missing Secrets: %MISSING_SECRETS%
    echo.
    if %MISSING_VARS% gtr 0 (
        echo - To fix missing variables, run: scripts\setup_github_variables.bat
    )
    if %MISSING_SECRETS% gtr 0 (
        echo - To fix missing secrets, manually add them via GitHub Settings.
        echo   Reference 'setup.md' and 'setup_ios_secrets_guide.md' for instructions.
    )
)

pause

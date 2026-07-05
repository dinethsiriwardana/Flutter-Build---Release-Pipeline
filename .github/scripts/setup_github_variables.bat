@echo off
setlocal EnableDelayedExpansion

echo =============================================
echo    GitHub Repository Variables Setup Tool    
echo =============================================
echo Press Enter to keep the default value shown in brackets.
echo.

:: Check if GitHub CLI is installed
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: GitHub CLI (gh) is not installed.
    echo Please install it from https://cli.github.com/ and authenticate using 'gh auth login'.
    pause
    exit /b 1
)

:: Prompt for variables with defaults
set "APP_V_MAJOR=1"
set /p "APP_V_MAJOR=Enter APP_V_MAJOR [!APP_V_MAJOR!]: "

set "APP_V_MINOR=0"
set /p "APP_V_MINOR=Enter APP_V_MINOR [!APP_V_MINOR!]: "

set "APP_V_PATCH=0"
set /p "APP_V_PATCH=Enter APP_V_PATCH [!APP_V_PATCH!]: "

set "APP_V_BUILDNO=1"
set /p "APP_V_BUILDNO=Enter APP_V_BUILDNO [!APP_V_BUILDNO!]: "

set "FLUTTER_VERSION=3.24.0"
set /p "FLUTTER_VERSION=Enter FLUTTER_VERSION [!FLUTTER_VERSION!]: "

set "IOS_TEAM_ID=JWAJ11K392"
set /p "IOS_TEAM_ID=Enter IOS_TEAM_ID [!IOS_TEAM_ID!]: "

set "IOS_MAIN_PROFILE=App Distribution"
set /p "IOS_MAIN_PROFILE=Enter IOS_MAIN_PROFILE [!IOS_MAIN_PROFILE!]: "

echo.
echo Setting up variables on GitHub...

gh variable set APP_V_MAJOR -b "!APP_V_MAJOR!"
gh variable set APP_V_MINOR -b "!APP_V_MINOR!"
gh variable set APP_V_PATCH -b "!APP_V_PATCH!"
gh variable set APP_V_BUILDNO -b "!APP_V_BUILDNO!"
gh variable set FLUTTER_VERSION -b "!FLUTTER_VERSION!"
gh variable set IOS_TEAM_ID -b "!IOS_TEAM_ID!"
gh variable set IOS_MAIN_PROFILE -b "!IOS_MAIN_PROFILE!"

echo.
echo ✅ All repository variables have been successfully configured!
pause

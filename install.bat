@echo off
setlocal enabledelayedexpansion

REM Dartango Framework SDK Installer for Windows
REM Installs Dartango globally on your Windows system

set DARTANGO_VERSION=1.0.0
set DARTANGO_HOME=%USERPROFILE%\.dartango
set DARTANGO_BIN=%DARTANGO_HOME%\bin
set DARTANGO_PACKAGES=%DARTANGO_HOME%\packages

echo.
echo ================================================================
echo                    Dartango Framework SDK
echo                   Django for Dart Developers  
echo ================================================================
echo.
echo Installing Dartango SDK v%DARTANGO_VERSION%...

REM Check if Dart is installed
dart --version >nul 2>&1
if errorlevel 1 (
    echo Error: Dart SDK not found!
    echo Please install Dart SDK first: https://dart.dev/get-dart
    pause
    exit /b 1
)

REM Check if Flutter is installed (optional but recommended)
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Warning: Flutter not found. Flutter is required for admin interface.
    echo Install Flutter from: https://flutter.dev/docs/get-started/install
)

echo Creating Dartango SDK directory...
if not exist "%DARTANGO_HOME%" mkdir "%DARTANGO_HOME%"
if not exist "%DARTANGO_BIN%" mkdir "%DARTANGO_BIN%"
if not exist "%DARTANGO_PACKAGES%" mkdir "%DARTANGO_PACKAGES%"

echo Installing Dartango packages...

REM Copy the entire dartango project to SDK location
xcopy /E /I /Y "%~dp0packages" "%DARTANGO_HOME%\packages"
xcopy /E /I /Y "%~dp0examples" "%DARTANGO_HOME%\examples"
xcopy /E /I /Y "%~dp0docs" "%DARTANGO_HOME%\docs"

REM Create the global dartango CLI batch script
(
echo @echo off
echo setlocal
echo.
echo REM Dartango Framework CLI
echo REM Global entry point for Dartango commands
echo.
echo set DARTANGO_HOME=%%DARTANGO_HOME%%
echo if "%%DARTANGO_HOME%%"=="" set DARTANGO_HOME=%%USERPROFILE%%\.dartango
echo set DARTANGO_CLI=%%DARTANGO_HOME%%\packages\dartango_cli\bin\dartango.dart
echo.
echo if not exist "%%DARTANGO_CLI%%" ^(
echo     echo Error: Dartango SDK not found at %%DARTANGO_HOME%%
echo     echo Please reinstall Dartango SDK
echo     exit /b 1
echo ^)
echo.
echo REM Run the Dartango CLI with all arguments
echo dart run "%%DARTANGO_CLI%%" %%*
) > "%DARTANGO_BIN%\dartango.bat"

echo Installing dependencies...

REM Install CLI dependencies
cd /d "%DARTANGO_HOME%\packages\dartango_cli"
dart pub get >nul 2>&1

REM Install core framework dependencies
cd /d "%DARTANGO_HOME%\packages\dartango"
dart pub get >nul 2>&1

REM Install admin dependencies
cd /d "%DARTANGO_HOME%\packages\dartango_admin"
flutter pub get >nul 2>&1

echo Setting up PATH...

REM Add to system PATH (requires admin privileges)
REM For user PATH, we'll add it to the registry
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set CurrentPath=%%B
if not defined CurrentPath set CurrentPath=

REM Check if DARTANGO_BIN is already in PATH
echo !CurrentPath! | findstr /i "%DARTANGO_BIN%" >nul
if errorlevel 1 (
    REM Add DARTANGO_BIN to PATH
    if defined CurrentPath (
        set NewPath=!CurrentPath!;%DARTANGO_BIN%
    ) else (
        set NewPath=%DARTANGO_BIN%
    )
    reg add "HKCU\Environment" /v PATH /t REG_SZ /d "!NewPath!" /f >nul
    echo Added Dartango to user PATH
) else (
    echo Dartango already in PATH
)

REM Set DARTANGO_HOME environment variable
reg add "HKCU\Environment" /v DARTANGO_HOME /t REG_SZ /d "%DARTANGO_HOME%" /f >nul

REM Create version file
echo %DARTANGO_VERSION% > "%DARTANGO_HOME%\VERSION"

REM Create SDK info file
(
echo Dartango Framework SDK
echo Version: %DARTANGO_VERSION%
echo Install Date: %DATE% %TIME%
echo Install Path: %DARTANGO_HOME%
echo.
echo Packages:
echo - dartango ^(core framework^)
echo - dartango_cli ^(command line tools^)
echo - dartango_admin ^(Flutter admin interface^)
echo - dartango_shared ^(shared utilities^)
echo.
echo Documentation: %DARTANGO_HOME%\docs\
echo Examples: %DARTANGO_HOME%\examples\
) > "%DARTANGO_HOME%\SDK_INFO"

echo.
echo ================================================================
echo                  🎉 Installation Complete! 🎉
echo ================================================================
echo.
echo ✅ Dartango SDK v%DARTANGO_VERSION% installed successfully!
echo 📍 Installation directory: %DARTANGO_HOME%
echo.
echo Next steps:
echo 1. Restart your Command Prompt or PowerShell
echo 2. Verify installation: dartango --version
echo 3. Create your first project: dartango create my_project
echo 4. Start developing: cd my_project ^&^& dartango serve
echo.
echo 🚀 Happy coding with Dartango!
echo.
echo Documentation: https://dartango.dev/docs
echo Examples: %DARTANGO_HOME%\examples\
echo.
pause
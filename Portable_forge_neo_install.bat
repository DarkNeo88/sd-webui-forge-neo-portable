@echo off
setlocal enabledelayedexpansion
title SD WebUI Forge Neo Portable Installer

:: Ensure we are in the directory of the script
cd /d "%~dp0"

echo ========================================================
echo   SD FORGE NEO + Portable Python + Portable Git Installer
echo ========================================================

:: --- Configuration ---
set "FOLDER_NAME=sd-webui-forge-neo"
set "PYTHON_URL=https://www.python.org/ftp/python/3.13.12/python-3.13.12-embed-amd64.zip"
set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.1/MinGit-2.53.0-64-bit.zip"

:: ----------------------------------------------------------
:: Step 1: Prepare Git (Bootstrap)
:: ----------------------------------------------------------
:check_git
if exist "git_temp\cmd\git.exe" goto :prepare_clone
if exist "git.zip" del "git.zip"

echo [INFO] Downloading Portable Git...
curl -L -o git.zip "%GIT_URL%"
if %errorlevel% neq 0 (
    echo [ERROR] Download failed. Check internet connection.
    pause
    exit /b
)

echo [INFO] Extracting Git...
if not exist "git_temp" mkdir "git_temp"
powershell -Command "Expand-Archive -Path 'git.zip' -DestinationPath 'git_temp' -Force"
del git.zip

:: ----------------------------------------------------------
:: Step 2: Clone Repository
:: ----------------------------------------------------------
:prepare_clone
set "GIT_CMD=%~dp0git_temp\cmd\git.exe"

if exist "%FOLDER_NAME%" (
    echo [INFO] Folder %FOLDER_NAME% already exists. Skipping clone.
    goto :move_git
)

echo [INFO] Cloning SD NEO...
"%GIT_CMD%" clone https://github.com/Haoming02/sd-webui-forge-classic "%FOLDER_NAME%" --branch neo
if %errorlevel% neq 0 (
    echo [ERROR] Git Clone failed.
    pause
    exit /b
)

:: ----------------------------------------------------------
:: Step 3: Move Git into Installation
:: ----------------------------------------------------------
:move_git
:: If the internal git already exists, delete the temp one and move on
if exist "%FOLDER_NAME%\system\git" (
    echo [INFO] Git already installed internally. Cleaning temp...
    if exist "git_temp" rmdir /s /q "git_temp"
    goto :check_python
)

echo [INFO] Moving Git into installation folder...
if not exist "%FOLDER_NAME%\system" mkdir "%FOLDER_NAME%\system"
move "git_temp" "%FOLDER_NAME%\system\git"

:: ----------------------------------------------------------
:: Step 4: Python Setup
:: ----------------------------------------------------------
:check_python
cd "%FOLDER_NAME%"
if not exist "system\python" mkdir "system\python"
cd "system\python"

if exist "python.exe" goto :patch_pth

echo [INFO] Downloading Python 3.13.12...
curl -L -o python.zip "%PYTHON_URL%"
echo [INFO] Extracting Python...
powershell -Command "Expand-Archive -Path 'python.zip' -DestinationPath '.' -Force"
del python.zip

:: ----------------------------------------------------------
:: Step 5: Patch .pth (Critical Fix for Portable Mode)
:: ----------------------------------------------------------
:patch_pth
echo [INFO] Patching configuration...
(
    echo python313.zip
    echo .
    echo ..\..
    echo import site
) > python313._pth

:: ----------------------------------------------------------
:: Step 6: Install PIP
:: ----------------------------------------------------------
:install_pip
if exist "Lib\site-packages\pip" goto :create_bats

echo [INFO] Installing PIP...
curl -L -o get-pip.py https://bootstrap.pypa.io/get-pip.py
.\python.exe get-pip.py --no-warn-script-location
del get-pip.py

:: ----------------------------------------------------------
:: Step 7: Create Launcher Files
:: ----------------------------------------------------------
:create_bats
cd ..\..\..

echo [INFO] Creating launchers...

:: 1. webui-user.bat (Internal)
(
echo @echo off
echo set PYTHON=system\python\python.exe
echo set GIT=system\git\cmd\git.exe
echo set VENV_DIR=-
echo set COMMANDLINE_ARGS=
echo call webui.bat
echo :: --xformers --sage --flash
echo :: --pin-shared-memory --cuda-malloc --cuda-stream
) > "%FOLDER_NAME%\webui-user.bat"

:: 2. run.bat (External)
(
echo @echo off
echo cd /d "%%~dp0%FOLDER_NAME%"
echo call webui-user.bat
) > run.bat

:: 3. update.bat (External)
(
echo @echo off
echo cd /d "%%~dp0"
echo set "GIT_CMD=%%~dp0%FOLDER_NAME%\system\git\cmd\git.exe"
echo cd "%FOLDER_NAME%"
echo "%%GIT_CMD%%" pull
echo pause
) > update.bat

:: ----------------------------------------------------------
:: Step 8: Final Cleanup
:: ----------------------------------------------------------
:cleanup
echo [INFO] Cleaning up temporary files...
if exist "git_temp" rmdir /s /q "git_temp"
if exist "git.zip" del "git.zip"

:: ----------------------------------------------------------
:: Step 9: Download Python libs...
:: ----------------------------------------------------------
echo.

set "URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.13.2_include_libs.zip"
set "ARCHIVE=python_3.13.2_include_libs.zip"
set "DEST=sd-webui-forge-neo\system\python"

echo Downloading...
powershell -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%ARCHIVE%'"

if not exist "%ARCHIVE%" (
    echo Error!
    pause
    exit /b 1
)

echo Creat folder...
mkdir "%DEST%" 2>nul

echo Ziping...
powershell -Command "Expand-Archive -Path '%ARCHIVE%' -DestinationPath '%DEST%' -Force"

echo Cleaning...
del "%ARCHIVE%" 2>nul

echo Success!
echo.

echo ========================================================
echo Installation Successful!
echo ========================================================
echo.
echo 1. To Start: Run "run.bat"
echo 2. To Update: Run "update.bat"
echo.
pause
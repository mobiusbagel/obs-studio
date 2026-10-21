@echo off
setlocal EnableDelayedExpansion
title Build Portable OBS 33 (mobiusbagel/obs-studio @ obs-33-portable)

REM ============================================================
REM  Builds stock OBS 33.0.0-rc2 from your fork, portable mode.
REM  Requires: Git, CMake 3.28+, Visual Studio 2026 (v18) with
REM  the "Desktop development with C++" workload.
REM  (OBS 33's windows-x64 preset uses the VS 2026 generator.)
REM  CMake bundled with Visual Studio is found automatically.
REM ============================================================

set "REPO_URL=https://github.com/mobiusbagel/obs-studio.git"
set "BRANCH=obs-33-portable"
set "SRC_DIR=%~dp0obs-studio-33"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

echo.
echo === Portable OBS 33 build ===
echo Source folder: %SRC_DIR%
echo.

REM ---------- Prerequisite checks ----------
where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Git not found on PATH. Install Git for Windows first:
    echo         https://git-scm.com/download/win
    goto :fail
)

REM --- Find CMake: PATH first, then the copy bundled with Visual Studio ---
where cmake >nul 2>nul
if errorlevel 1 (
    if exist "%VSWHERE%" (
        for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -property installationPath 2^>nul`) do (
            if exist "%%i\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" (
                set "PATH=%%i\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;!PATH!"
            )
        )
    )
)
if not defined CMAKE_FOUND (
    where cmake >nul 2>nul && set "CMAKE_FOUND=1"
)
if not defined CMAKE_FOUND (
    if exist "C:\Program Files\CMake\bin\cmake.exe" (
        set "PATH=C:\Program Files\CMake\bin;%PATH%"
        set "CMAKE_FOUND=1"
    )
)
if not defined CMAKE_FOUND (
    echo [ERROR] CMake not found. Install CMake 3.28+ and tick "Add to PATH":
    echo         https://cmake.org/download
    echo         ^(Visual Studio's bundled CMake is also searched automatically.^)
    goto :fail
)
for /f "tokens=*" %%v in ('cmake --version ^| findstr /R "^cmake"') do echo Using %%v

REM --- Visual Studio 2026 check (OBS 33 preset needs the VS 2026 generator) ---
if exist "%VSWHERE%" (
    "%VSWHERE%" -version "[18.0,19.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.VC.ATL -property installationPath >nul 2>nul
    if errorlevel 1 (
        echo [WARNING] Visual Studio 2026 with C++ tools AND the ATL component
        echo           was not detected. OBS 33 requires both ^(captions,
        echo           QuickSync and the virtual camera need ATL headers^).
        echo           VS Installer -^> Modify -^> Individual components -^>
        echo           "C++ ATL for latest build tools (x86 & x64)"
        echo.
        choice /M "Continue anyway"
        if errorlevel 2 goto :fail
    )
)

REM ---------- Clone or update ----------
if exist "%SRC_DIR%\.git" (
    echo --- Updating existing clone ---
    git -C "%SRC_DIR%" fetch origin %BRANCH%
    if errorlevel 1 goto :fail
    git -C "%SRC_DIR%" checkout %BRANCH%
    if errorlevel 1 goto :fail
    git -C "%SRC_DIR%" pull --ff-only
    if errorlevel 1 goto :fail
    git -C "%SRC_DIR%" submodule update --init --recursive
    if errorlevel 1 goto :fail
) else (
    echo --- Cloning your fork ^(branch %BRANCH%^) ---
    git clone -b %BRANCH% --recursive "%REPO_URL%" "%SRC_DIR%"
    if errorlevel 1 goto :fail
)

cd /d "%SRC_DIR%"

REM ---------- Configure (first run downloads obs-deps + Qt) ----------
echo.
echo --- Configuring (cmake --preset windows-x64) ---
echo First run downloads several GB of prebuilt dependencies. One-time cost.
cmake --preset windows-x64
if errorlevel 1 (
    echo [ERROR] Configure failed. Scroll up for the first error line.
    goto :fail
)

REM ---------- Build ----------
echo.
echo --- Building (cmake --build --preset windows-x64) ---
echo First build is the long one. Later runs are incremental.
cmake --build --preset windows-x64
if errorlevel 1 (
    echo [ERROR] Build failed. Scroll up for the first error line.
    goto :fail
)

REM ---------- Make it portable ----------
echo.
echo --- Enabling portable mode ---
powershell -NoProfile -Command "$exe = Get-ChildItem -Path '%SRC_DIR%\build_x64\rundir' -Recurse -Filter obs64.exe | Select-Object -First 1; if ($exe) { $root = $exe.Directory.Parent.Parent.FullName; New-Item -ItemType File -Force -Path (Join-Path $root 'portable_mode.txt') | Out-Null; Write-Host ('portable_mode.txt created in ' + $root); Write-Host ('PORTABLE OBS: ' + $exe.FullName) } else { Write-Host '[ERROR] obs64.exe not found under build_x64\rundir'; exit 1 }"
if errorlevel 1 goto :fail

echo.
echo === DONE ===
echo Your portable OBS 33 folder is:
echo   %SRC_DIR%\build_x64\rundir\RelWithDebInfo
echo All config, profiles, scenes and plugins live inside it (config subfolder).
echo Your existing OBS install is untouched.
echo.
pause
exit /b 0

:fail
echo.
echo Build did not finish. Fix the issue above and run this .bat again -
echo it picks up where it left off.
pause
exit /b 1

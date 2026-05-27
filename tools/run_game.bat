@echo off
setlocal enabledelayedexpansion

REM Resolve the project root (where project.godot lives).
set "PROJECT_DIR=%BUILD_WORKSPACE_DIRECTORY%"
if "!PROJECT_DIR!"=="" set "PROJECT_DIR=."

REM Locate the hermetic Godot binary via Bazel runfiles.
REM On Windows, Bazel uses manifest files instead of directory trees
set "RUNFILES=%~dp0%~nx0.runfiles"
set "MANIFEST=!RUNFILES!\MANIFEST"

if not exist "!MANIFEST!" (
    echo ERROR: Could not find runfiles manifest >&2
    exit /b 1
)

REM Find the real path of godot_bin_path.txt from the manifest
for /f "tokens=2" %%L in ('findstr "godot_bin_path.txt" "!MANIFEST!"') do (
    set "BIN_PATH_FILE=%%L"
    goto :found_file
)

:found_file
if not defined BIN_PATH_FILE (
    echo ERROR: Could not find godot_bin_path.txt in manifest >&2
    exit /b 1
)

if not exist "!BIN_PATH_FILE!" (
    echo ERROR: godot_bin_path.txt not found at !BIN_PATH_FILE! >&2
    exit /b 1
)

REM Read Godot filename from the file
for /f "usebackq delims=" %%L in ("!BIN_PATH_FILE!") do (
    set "GODOT_FILENAME=%%L"
)

REM Get directory of godot_bin_path.txt and build Godot path
for %%F in ("!BIN_PATH_FILE!") do set "GODOT_DIR=%%~dpF"
set "GODOT_BIN=!GODOT_DIR!godot_extracted\!GODOT_FILENAME!"

if not exist "!GODOT_BIN!" (
    echo ERROR: Godot binary not found at: !GODOT_BIN! >&2
    exit /b 1
)

echo Launching CitySlop with hermetic Godot
"!GODOT_BIN!" --path "!PROJECT_DIR!"
exit /b !ERRORLEVEL!

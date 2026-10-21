@echo off
title Update Portable OBS 33 Plugins
REM ============================================================
REM  One-click updater for the portable OBS 33 plugin set.
REM  Pulls the latest GitHub release of each plugin and
REM  installs it into the portable build (new or legacy
REM  layout, as each plugin requires). Close OBS first!
REM  Details: update-plugins.ps1
REM ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-plugins.ps1"
pause

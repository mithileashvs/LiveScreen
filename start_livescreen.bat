@echo off
REM ============================================================
REM LiveScreen Startup Script
REM
REM Double-click this file to run the app - no need to open
REM VS Code or type commands manually.
REM
REM IMPORTANT: This file must sit in your project's ROOT folder
REM (the same folder as pubspec.yaml) - i.e.
REM C:\Users\USER\Desktop\livescreen\start_livescreen.bat
REM ============================================================

REM %~dp0 = the folder this .bat file is actually sitting in,
REM so this works no matter where the project folder is located.
cd /d "%~dp0"

echo ============================================
echo   LiveScreen - Starting...
echo ============================================
echo.
echo Project folder: %cd%
echo.

echo Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo.
    echo [ERROR] flutter pub get failed. See the message above.
    pause
    exit /b 1
)

echo.
echo Launching in Chrome...
echo (Closing this window will stop the app.)
echo.
call flutter run -d chrome

echo.
echo ============================================
echo   LiveScreen has stopped.
echo ============================================
pause

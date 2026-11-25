@echo off
rem Called from the project launchers; GODOT_EXE may be pre-set by the user.
if defined GODOT_EXE if exist "%GODOT_EXE%" exit /b 0
set "GODOT_EXE="
for %%F in ("%~dp0Godot_v4.7.2-stable_win64_console.exe" "%~dp0Godot_v4.7.2-stable_win64.exe" "%~dp0godot.exe" "%~dp0..\Godot_v4.7.2-stable_win64_console.exe" "%~dp0..\Godot_v4.7.2-stable_win64.exe") do if not defined GODOT_EXE if exist "%%~fF" set "GODOT_EXE=%%~fF"
if not defined GODOT_EXE for /f "delims=" %%F in ('where godot.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%F"
if defined GODOT_EXE exit /b 0
echo Godot was not found. Install Godot 4.7.2 and enter the executable path.
echo A console executable is recommended for tests.
set /p "GODOT_EXE=Full path to Godot .exe: "
set "GODOT_EXE=%GODOT_EXE:"=%"
if not defined GODOT_EXE exit /b 1
if not exist "%GODOT_EXE%" (
  echo The file was not found: "%GODOT_EXE%"
  exit /b 1
)
exit /b 0

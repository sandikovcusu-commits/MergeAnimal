@echo off
setlocal
cd /d "%~dp0"
call "%~dp0FIND_GODOT.bat"
if errorlevel 1 goto :fail
if not exist "%~dp0project.godot" (
  echo project.godot not found.
  goto :fail
)
"%GODOT_EXE%" --version
if errorlevel 1 goto :fail
echo Starting Merge Animals from "%~dp0"...
"%GODOT_EXE%" --headless --path "%~dp0" --editor --quit
if errorlevel 1 goto :fail
"%GODOT_EXE%" --path "%~dp0"
if errorlevel 1 goto :fail
exit /b 0
:fail
echo Could not start the project. Check the Godot path and version.
pause
exit /b 1

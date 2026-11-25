@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
call "%~dp0FIND_GODOT.bat"
if errorlevel 1 goto :setup_failed
set "LOGDIR=%~dp0test-results"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "FAILURES=0"
echo Godot executable: "%GODOT_EXE%"
"%GODOT_EXE%" --version > "%LOGDIR%\version.txt" 2>&1
if errorlevel 1 goto :setup_failed
type "%LOGDIR%\version.txt"
findstr /b /c:"4.7.2" "%LOGDIR%\version.txt" >nul
if errorlevel 1 echo WARNING: tests were designed for Godot 4.7.2. Proceeding with detected version.
call :test "editor-import" --editor --quit
call :test "integration" --script res://tests/integration/day2_suite.gd
call :test "day3-evolution" --script res://tests/integration/day3_suite.gd
call :test "input-recovery" --script res://tests/integration/input_recovery.gd
call :test "multitouch" --script res://tests/integration/input_multitouch.gd
call :test "restart" --script res://tests/integration/restart.gd
call :test "contact-chain" --script res://tests/physics/chain_contact.gd
call :test "walls" --script res://tests/physics/wall_collision.gd
call :test "natural-collision" --script res://tests/physics/natural_collision.gd
call :test "real-gameplay" --script res://tests/physics/real_gameplay.gd
call :test "drop-100" --script res://tests/physics/drop_100.gd
call :test "stress" --script res://tests/physics/stress.gd
echo.
if not "%FAILURES%"=="0" (
  echo FAILED: %FAILURES% step^(s^). See "%LOGDIR%".
  pause
  exit /b 1
)
echo Runtime steps completed without reported errors. See "%LOGDIR%".
echo Stress measurements and mobile touch still require manual review.
pause
exit /b 0

:test
set "NAME=%~1"
shift
echo Running %NAME%...
rem SHIFT changes %%1... but not %%*, so reconstruct the Godot arguments.
if "%NAME%"=="editor-import" (
  "%GODOT_EXE%" --headless --path "%~dp0" --editor --quit > "%LOGDIR%\%NAME%.log" 2>&1
) else (
  "%GODOT_EXE%" --headless --path "%~dp0" --script "%~2" > "%LOGDIR%\%NAME%.log" 2>&1
)
set "RC=!errorlevel!"
findstr /l /c:"SCRIPT ERROR" /c:"Parse Error" /c:"ERROR:" "%LOGDIR%\%NAME%.log" >nul
if not errorlevel 1 set "RC=1"
findstr /b /l /c:"FAIL" "%LOGDIR%\%NAME%.log" >nul
if not errorlevel 1 set "RC=1"
if not "!RC!"=="0" (
  set /a FAILURES+=1
  echo FAILED %NAME% - see "%LOGDIR%\%NAME%.log"
) else (
  echo Completed %NAME%
)
exit /b 0

:setup_failed
echo Godot setup failed. No runtime tests were run.
pause
exit /b 1

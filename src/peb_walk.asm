; PEB Walk API Resolution (x64 NASM)
; Resolves Windows APIs without IAT imports
; Author: Matheus Sobral

bits 64
default rel

section .text

global peb_get_module
global get_export_by_hash
global djb2_hash

; DJB2 Hash Function
; RDI = string pointer
; Returns: RAX = hash
djb2_hash:
    push rbp
    mov rbp, rsp
    
    mov rax, 5381
    xor rcx, rcx
    
.hash_loop:
    movzx rdx, byte [rdi + rcx]
    test dl, dl
    jz .done
    
    shl rax, 5
    add rax, rax
    xor rax, rdx
    
    inc rcx
    jmp .hash_loop
    
.done:
    leave
    ret

; Get Module Base by Hash
; RDI = name_hash (djb2)
; Returns: RAX = module base or 0
peb_get_module:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi
    
    ; Get PEB
    mov rax, qword [gs:0x60]
    
    ; Get Ldr
    mov rax, [rax + 0x18]
    
    ; Get InMemoryOrderModuleList
    mov rax, [rax + 0x20]
    mov r13, rax
    
.module_loop:
    ; Get next entry
    mov rax, [rax]
    
    ; Check if back at head
    cmp rax, r13
    je .not_found
    
    ; Get LDR_DATA_TABLE_ENTRY
    sub rax, 0x10
    
    ; Get BaseDllName.Buffer
    mov r14, [rax + 0x58]
    test r14, r14
    jz .next_module
    
    ; Convert wide string to narrow and lowercase
    xor rcx, rcx
    lea rdi, [rsp]
    
.convert_loop:
    cmp rcx, 63
    jge .convert_done
    
    movzx rdx, word [r14 + rcx*2]
    test dx, dx
    jz .convert_done
    
    ; Lowercase
    or dl, 0x20
    mov [rdi + rcx], dl
    
    inc rcx
    jmp .convert_loop
    
.convert_done:
    mov byte [rdi + rcx], 0
    
    ; Hash the name
    lea rdi, [rsp]
    push rax
    call djb2_hash
    pop r15
    
    ; Compare hash
    cmp rax, r12
    je .found
    
.next_module:
    mov rax, r15
    add rax, 0x10
    jmp .module_loop
    
.found:
    ; Get DllBase
    mov rax, [r15 + 0x30]
    jmp .done
    
.not_found:
    xor rax, rax
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

; Get Export by Hash
; RDI = module_base
; RSI = function_hash (djb2)
; Returns: RAX = function address or 0
get_export_by_hash:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi
    mov r13, rsi
    
    ; Get DOS header
    cmp word [r12], 0x5A4D
    jne .not_found
    
    ; Get NT headers
    mov eax, [r12 + 0x3C]
    add rax, r12
    
    ; Check PE signature
    cmp dword [rax], 0x00004550
    jne .not_found
    
    ; Get export directory RVA
    mov eax, [rax + 0x88]
    test eax, eax
    jz .not_found
    
    add rax, r12
    mov r14, rax
    
    ; Get export tables
    mov eax, [r14 + 0x20]
    add rax, r12
    mov r15, rax
    
    mov eax, [r14 + 0x24]
    add rax, r12
    push rax
    
    mov eax, [r14 + 0x1C]
    add rax, r12
    push rax
    
    ; Get number of names
    mov ecx, [r14 + 0x18]
    xor rbx, rbx
    
.export_loop:
    cmp rbx, rcx
    jge .not_found
    
    ; Get name RVA
    mov eax, [r15 + rbx*4]
    add rax, r12
    
    ; Hash the name
    mov rdi, rax
    push rcx
    push rbx
    call djb2_hash
    pop rbx
    pop rcx
    
    ; Compare hash
    cmp rax, r13
    je .found_export
    
    inc rbx
    jmp .export_loop
    
.found_export:
    ; Get ordinal
    pop r15
    pop r14
    
    movzx rax, word [r14 + rbx*2]
    
    ; Get function RVA
    mov eax, [r15 + rax*4]
    add rax, r12
    jmp .done
    
.not_found:
    xor rax, rax
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

; Resolve API by name
; RDI = dll_name
; RSI = function_name
; Returns: RAX = function address or 0
global resolve_api
resolve_api:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    push rbx
    push r12
    
    mov r12, rsi
    
    ; Hash DLL name
    call djb2_hash
    mov rbx, rax
    
    ; Get module base
    mov rdi, rbx
    call peb_get_module
    test rax, rax
    jz .failed
    
    ; Hash function name
    mov rdi, r12
    push rax
    call djb2_hash
    pop rdi
    
    ; Get export
    mov rsi, rax
    call get_export_by_hash
    
.failed:
    pop r12
    pop rbx
    
    leave
    ret

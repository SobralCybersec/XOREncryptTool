; PBKDF2-HMAC-SHA256 Implementation (x64 NASM)
; Based on RFC 2898
; Author: Matheus Sobral

bits 64
default rel

section .text

extern hmac_sha256_init
extern hmac_sha256_update
extern hmac_sha256_final

global pbkdf2_hmac_sha256

; PBKDF2-HMAC-SHA256
; RDI = password
; RSI = password_len
; RDX = salt
; RCX = salt_len
; R8  = iterations
; R9  = output
; [rsp+8] = output_len
pbkdf2_hmac_sha256:
    push rbp
    mov rbp, rsp
    sub rsp, 256
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    
    mov rax, [rbp + 16]
    mov [rsp + 240], rax
    
    xor r10, r10
    
.block_loop:
    mov rax, [rsp + 240]
    cmp r10, rax
    jge .done
    
    ; U1 = HMAC(password, salt || block_index)
    lea rdi, [rsp]
    mov rsi, r12
    mov rdx, r13
    call hmac_sha256_init
    
    lea rdi, [rsp]
    mov rsi, r14
    mov rdx, r15
    call hmac_sha256_update
    
    inc r10d
    push r10
    lea rdi, [rsp + 8]
    lea rsi, [rsp + 4]
    mov rdx, 4
    call hmac_sha256_update
    pop r10
    
    lea rdi, [rsp]
    lea rsi, [rsp + 64]
    call hmac_sha256_final
    
    ; Copy U1 to result
    mov rcx, 32
    lea rsi, [rsp + 64]
    lea rdi, [rsp + 96]
    rep movsb
    
    ; Iterate
    mov r11, 1
.iter_loop:
    cmp r11, rbx
    jge .block_done
    
    ; Un = HMAC(password, Un-1)
    lea rdi, [rsp]
    mov rsi, r12
    mov rdx, r13
    call hmac_sha256_init
    
    lea rdi, [rsp]
    lea rsi, [rsp + 64]
    mov rdx, 32
    call hmac_sha256_update
    
    lea rdi, [rsp]
    lea rsi, [rsp + 64]
    call hmac_sha256_final
    
    ; XOR with result
    xor rax, rax
.xor_loop:
    cmp rax, 32
    jge .xor_done
    mov cl, [rsp + 64 + rax]
    xor [rsp + 96 + rax], cl
    inc rax
    jmp .xor_loop
    
.xor_done:
    inc r11
    jmp .iter_loop
    
.block_done:
    ; Copy to output
    mov rcx, 32
    mov rax, [rsp + 240]
    sub rax, r10
    cmp rcx, rax
    jle .copy_full
    mov rcx, rax
    
.copy_full:
    lea rsi, [rsp + 96]
    mov rdi, r9
    rep movsb
    add r9, rcx
    
    jmp .block_loop
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

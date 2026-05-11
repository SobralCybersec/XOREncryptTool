section .text

extern xor_crypt_rotating
extern rc4_init
extern rc4_crypt
extern chacha20_encrypt

global encrypt_pipeline
global decrypt_pipeline

encrypt_pipeline:
    push rbp
    mov rbp, rsp
    sub rsp, 320
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov [rbp - 8], rdi
    mov [rbp - 16], rsi
    mov [rbp - 24], rdx
    mov [rbp - 32], rcx
    mov [rbp - 40], r8
    call xor_crypt_rotating
    lea rdi, [rbp - 288]
    mov rsi, [rbp - 32]
    mov rdx, 16
    call rc4_init
    lea rdi, [rbp - 288]
    mov rsi, [rbp - 8]
    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call rc4_crypt
    mov rdi, [rbp - 8]
    mov rsi, [rbp - 16]
    mov rdx, [rbp - 40]
    call chacha20_encrypt
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 320
    pop rbp
    ret

decrypt_pipeline:
    push rbp
    mov rbp, rsp
    sub rsp, 320
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov [rbp - 8], rdi
    mov [rbp - 16], rsi
    mov [rbp - 24], rdx
    mov [rbp - 32], rcx
    mov [rbp - 40], r8
    mov rdi, [rbp - 8]
    mov rsi, [rbp - 16]
    mov rdx, [rbp - 40]
    call chacha20_encrypt
    lea rdi, [rbp - 288]
    mov rsi, [rbp - 32]
    mov rdx, 16
    call rc4_init
    lea rdi, [rbp - 288]
    mov rsi, [rbp - 8]
    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call rc4_crypt
    mov rdi, [rbp - 8]
    mov rsi, [rbp - 8]
    mov rdx, [rbp - 16]
    call xor_crypt_rotating
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 320
    pop rbp
    ret

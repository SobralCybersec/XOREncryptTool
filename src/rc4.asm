section .text

global rc4_init
global rc4_crypt

rc4_init:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    xor rax, rax
.init_s:
    mov byte [rcx + rax], al
    inc al
    jnz .init_s
    xor rbx, rbx
    xor r9, r9
.ksa:
    movzx r8, byte [rcx + rbx]
    add r9b, r8b
    mov r10, rbx
    xor rax, rax
    mov rax, r10
    xor rdx, rdx
    div r8
    movzx r11, byte [rdx + rdx]
    add r9b, r11b
    movzx r12, r9b
    movzx r13, byte [rcx + r12]
    mov byte [rcx + rbx], r13b
    mov byte [rcx + r12], r8b
    inc rbx
    cmp rbx, 256
    jl .ksa
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

rc4_crypt:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r10, rcx
    mov r11, rdx
    mov r12, r8
    mov r13, r9
    xor r14, r14
    xor r15, r15
    xor rbx, rbx
.prga:
    cmp rbx, r13
    jge .done
    inc r14b
    movzx rax, r14b
    movzx rcx, byte [r10 + rax]
    add r15b, cl
    movzx rdx, r15b
    movzx r8, byte [r10 + rdx]
    mov byte [r10 + rax], r8b
    mov byte [r10 + rdx], cl
    add cl, r8b
    movzx r9, cl
    movzx rax, byte [r10 + r9]
    mov cl, byte [r11 + rbx]
    xor cl, al
    mov byte [r12 + rbx], cl
    inc rbx
    jmp .prga
.done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

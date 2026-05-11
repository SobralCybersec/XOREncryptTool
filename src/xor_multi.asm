section .text

global xor_crypt_rotating
global xor_crypt_multi

xor_crypt_rotating:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov r10, 0x123456789ABCDEF0
    xor r9, r9
.loop:
    cmp r9, r8
    jge .done
    mov al, [rdx + r9]
    mov bl, r9b
    and bl, 7
    mov r12, r10
    mov cl, bl
    ror r12, cl
    xor al, r12b
    mov [rcx + r9], al
    inc r9
    jmp .loop
.done:
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

xor_crypt_multi:
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
    mov r14, [rbp + 48]
    xor r15, r15
.loop_multi:
    cmp r15, r12
    jge .done_multi
    mov al, [r11 + r15]
    mov rax, r15
    xor rdx, rdx
    div r14
    mov bl, [r13 + rdx]
    mov al, [r11 + r15]
    xor al, bl
    mov [r10 + r15], al
    inc r15
    jmp .loop_multi
.done_multi:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

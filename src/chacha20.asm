; ChaCha20 Stream Cipher Implementation
; Modern XOR encryption using ARX operations
; x86-64 optimized - Full 20-round implementation

section .data
    ; ChaCha20 constants "expand 32-byte k"
    align 16
    chacha_const dd 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574

section .text
global chacha20_init_state
global chacha20_block
global chacha20_encrypt

; Initialize ChaCha20 state
; Args: rdi = state (64 bytes), rsi = key (32 bytes), rdx = nonce (12 bytes), rcx = counter
chacha20_init_state:
    push rbp
    mov rbp, rsp
    
    ; Constants (words 0-3)
    mov eax, [rel chacha_const]
    mov [rdi], eax
    mov eax, [rel chacha_const + 4]
    mov [rdi + 4], eax
    mov eax, [rel chacha_const + 8]
    mov [rdi + 8], eax
    mov eax, [rel chacha_const + 12]
    mov [rdi + 12], eax
    
    ; Key (words 4-11)
    mov rax, [rsi]
    mov [rdi + 16], rax
    mov rax, [rsi + 8]
    mov [rdi + 24], rax
    mov rax, [rsi + 16]
    mov [rdi + 32], rax
    mov rax, [rsi + 24]
    mov [rdi + 40], rax
    
    ; Counter (word 12)
    mov [rdi + 48], ecx
    
    ; Nonce (words 13-15)
    mov eax, [rdx]
    mov [rdi + 52], eax
    mov eax, [rdx + 4]
    mov [rdi + 56], eax
    mov eax, [rdx + 8]
    mov [rdi + 60], eax
    
    pop rbp
    ret

; ChaCha20 quarter round macro (inline for speed)
%macro QROUND 4
    ; a += b; d ^= a; d <<<= 16
    mov eax, [rsp + %1*4]
    add eax, [rsp + %2*4]
    mov [rsp + %1*4], eax
    xor eax, [rsp + %4*4]
    rol eax, 16
    mov [rsp + %4*4], eax
    
    ; c += d; b ^= c; b <<<= 12
    mov ebx, [rsp + %3*4]
    add ebx, eax
    mov [rsp + %3*4], ebx
    xor ebx, [rsp + %2*4]
    rol ebx, 12
    mov [rsp + %2*4], ebx
    
    ; a += b; d ^= a; d <<<= 8
    mov eax, [rsp + %1*4]
    add eax, ebx
    mov [rsp + %1*4], eax
    xor eax, [rsp + %4*4]
    rol eax, 8
    mov [rsp + %4*4], eax
    
    ; c += d; b ^= c; b <<<= 7
    mov ebx, [rsp + %3*4]
    add ebx, eax
    mov [rsp + %3*4], ebx
    xor ebx, [rsp + %2*4]
    rol ebx, 7
    mov [rsp + %2*4], ebx
%endmacro

; ChaCha20 block function (20 rounds)
; Args: rdi = output (64 bytes), rsi = input state (64 bytes)
chacha20_block:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi                ; Save output pointer
    mov r13, rsi                ; Save input pointer
    
    ; Copy input state to working state
    mov rcx, 8
.copy_loop:
    mov rax, [r13 + rcx*8 - 8]
    mov [rsp + rcx*8 - 8], rax
    loop .copy_loop
    
    ; 20 rounds (10 double rounds)
    mov r15d, 10
.round_loop:
    ; Column rounds
    QROUND 0, 4, 8, 12
    QROUND 1, 5, 9, 13
    QROUND 2, 6, 10, 14
    QROUND 3, 7, 11, 15
    
    ; Diagonal rounds
    QROUND 0, 5, 10, 15
    QROUND 1, 6, 11, 12
    QROUND 2, 7, 8, 13
    QROUND 3, 4, 9, 14
    
    dec r15d
    jnz .round_loop
    
    ; Add original state to working state
    mov rcx, 16
.add_loop:
    mov eax, [r13 + rcx*4 - 4]
    add [rsp + rcx*4 - 4], eax
    loop .add_loop
    
    ; Copy to output
    mov rcx, 8
.output_loop:
    mov rax, [rsp + rcx*8 - 8]
    mov [r12 + rcx*8 - 8], rax
    loop .output_loop
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

; Encrypt/Decrypt data with ChaCha20
; Args: rdi = output, rsi = input, rdx = length, rcx = key (32 bytes), r8 = nonce (12 bytes)
chacha20_encrypt:
    push rbp
    mov rbp, rsp
    sub rsp, 192                ; State (64) + keystream (64) + alignment
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi                ; Output
    mov r13, rsi                ; Input
    mov r14, rdx                ; Length
    mov r15, rcx                ; Key
    
    xor ebx, ebx                ; Counter = 0
    
.block_loop:
    test r14, r14
    jz .done
    
    ; Initialize state for this block
    lea rdi, [rsp]
    mov rsi, r15                ; Key
    mov rdx, r8                 ; Nonce
    mov rcx, rbx                ; Counter
    call chacha20_init_state
    
    ; Generate keystream block
    lea rdi, [rsp + 64]         ; Keystream output
    lea rsi, [rsp]              ; State input
    call chacha20_block
    
    ; XOR with input (up to 64 bytes)
    mov rcx, r14
    cmp rcx, 64
    jbe .xor_partial
    mov rcx, 64
    
.xor_partial:
    xor rax, rax
.xor_loop:
    cmp rax, rcx
    jge .xor_done
    
    mov dl, [r13 + rax]
    xor dl, [rsp + 64 + rax]
    mov [r12 + rax], dl
    
    inc rax
    jmp .xor_loop
    
.xor_done:
    add r12, rcx
    add r13, rcx
    sub r14, rcx
    inc ebx                     ; Increment counter
    jmp .block_loop
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

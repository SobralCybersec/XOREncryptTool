; HMAC-SHA256 Implementation (x64 NASM)
; Based on RFC 2104 and FIPS 180-4
; Author: Matheus Sobral

bits 64
default rel

section .text

global hmac_sha256_init
global hmac_sha256_update
global hmac_sha256_final
global sha256_transform

; SHA-256 Constants (first 32 bits of fractional parts of cube roots of first 64 primes)
section .data
align 16
K256:
    dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
    dd 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
    dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
    dd 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
    dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
    dd 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
    dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
    dd 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
    dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
    dd 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
    dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
    dd 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
    dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
    dd 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
    dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
    dd 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

; Initial hash values (first 32 bits of fractional parts of square roots of first 8 primes)
H256_INIT:
    dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    dd 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

section .text

; SHA-256 Transform
; RDI = state (8 DWORDs)
; RSI = block (64 bytes)
sha256_transform:
    push rbp
    mov rbp, rsp
    sub rsp, 320
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; W[0..15] = block
    mov rcx, 16
    xor rax, rax
.copy_block:
    mov edx, [rsi + rax*4]
    bswap edx
    mov [rsp + rax*4], edx
    inc rax
    loop .copy_block
    
    ; W[16..63] expansion
    mov rcx, 48
    mov rax, 16
.expand:
    mov r8d, [rsp + (rax-15)*4]
    mov r9d, r8d
    ror r9d, 7
    mov r10d, r8d
    ror r10d, 18
    xor r9d, r10d
    shr r8d, 3
    xor r9d, r8d
    
    mov r8d, [rsp + (rax-2)*4]
    mov r10d, r8d
    ror r10d, 17
    mov r11d, r8d
    ror r11d, 19
    xor r10d, r11d
    shr r8d, 10
    xor r10d, r8d
    
    mov r8d, [rsp + (rax-16)*4]
    add r9d, r8d
    mov r8d, [rsp + (rax-7)*4]
    add r9d, r8d
    add r9d, r10d
    mov [rsp + rax*4], r9d
    
    inc rax
    loop .expand
    
    ; Initialize working variables
    mov eax, [rdi]
    mov ebx, [rdi+4]
    mov ecx, [rdi+8]
    mov edx, [rdi+12]
    mov r8d, [rdi+16]
    mov r9d, [rdi+20]
    mov r10d, [rdi+24]
    mov r11d, [rdi+28]
    
    ; Main loop (64 rounds)
    xor r12, r12
.round_loop:
    ; T1 = h + Sigma1(e) + Ch(e,f,g) + K[i] + W[i]
    mov r13d, r8d
    ror r13d, 6
    mov r14d, r8d
    ror r14d, 11
    xor r13d, r14d
    mov r14d, r8d
    ror r14d, 25
    xor r13d, r14d
    
    mov r14d, r8d
    and r14d, r9d
    mov r15d, r8d
    not r15d
    and r15d, r10d
    xor r14d, r15d
    
    add r13d, r11d
    add r13d, r14d
    lea r14, [K256]
    add r13d, [r14 + r12*4]
    add r13d, [rsp + r12*4]
    
    ; T2 = Sigma0(a) + Maj(a,b,c)
    mov r14d, eax
    ror r14d, 2
    mov r15d, eax
    ror r15d, 13
    xor r14d, r15d
    mov r15d, eax
    ror r15d, 22
    xor r14d, r15d
    
    mov r15d, eax
    and r15d, ebx
    push rax
    mov eax, eax
    and eax, ecx
    xor r15d, eax
    pop rax
    push rbx
    mov ebx, ebx
    and ebx, ecx
    xor r15d, ebx
    pop rbx
    
    add r14d, r15d
    
    ; Update working variables
    mov r11d, r10d
    mov r10d, r9d
    mov r9d, r8d
    lea r8d, [rdx + r13d]
    mov edx, ecx
    mov ecx, ebx
    mov ebx, eax
    lea eax, [r13d + r14d]
    
    inc r12
    cmp r12, 64
    jl .round_loop
    
    ; Add to state
    add [rdi], eax
    add [rdi+4], ebx
    add [rdi+8], ecx
    add [rdi+12], edx
    add [rdi+16], r8d
    add [rdi+20], r9d
    add [rdi+24], r10d
    add [rdi+28], r11d
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

; HMAC-SHA256 Init
; RDI = context
; RSI = key
; RDX = key_len
hmac_sha256_init:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    
    push rbx
    push r12
    push r13
    
    mov r12, rdi
    mov r13, rsi
    
    ; Initialize hash state
    lea rsi, [H256_INIT]
    mov rcx, 8
    rep movsd
    
    ; Process key
    cmp rdx, 64
    jle .key_ok
    
    ; Hash key if > 64 bytes
    mov rdi, r12
    mov rsi, r13
    mov rcx, rdx
    call sha256_update
    call sha256_final
    mov rdx, 32
    
.key_ok:
    ; XOR key with ipad (0x36)
    xor rax, rax
.ipad_loop:
    cmp rax, rdx
    jge .ipad_pad
    mov bl, [r13 + rax]
    xor bl, 0x36
    mov [rsp + rax], bl
    inc rax
    jmp .ipad_loop
    
.ipad_pad:
    cmp rax, 64
    jge .ipad_done
    mov byte [rsp + rax], 0x36
    inc rax
    jmp .ipad_pad
    
.ipad_done:
    ; Update with ipad
    mov rdi, r12
    lea rsi, [rsp]
    mov rdx, 64
    call sha256_update
    
    pop r13
    pop r12
    pop rbx
    
    leave
    ret

; HMAC-SHA256 Update
; RDI = context
; RSI = data
; RDX = len
hmac_sha256_update:
    push rbp
    mov rbp, rsp
    
    ; Process data in 64-byte blocks
    mov rcx, rdx
    shr rcx, 6
    jz .remainder
    
.block_loop:
    call sha256_transform
    add rsi, 64
    dec rcx
    jnz .block_loop
    
.remainder:
    and rdx, 63
    jz .done
    
    ; Handle remaining bytes
    mov rcx, rdx
    rep movsb
    
.done:
    leave
    ret

; HMAC-SHA256 Final
; RDI = context
; RSI = output (32 bytes)
hmac_sha256_final:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    
    push rbx
    push r12
    
    mov r12, rdi
    
    ; Finalize inner hash
    call sha256_final
    
    ; XOR key with opad (0x5c)
    xor rax, rax
.opad_loop:
    cmp rax, 64
    jge .opad_done
    mov bl, [r12 + 32 + rax]
    xor bl, 0x5c
    mov [rsp + rax], bl
    inc rax
    jmp .opad_loop
    
.opad_done:
    ; Hash opad || inner_hash
    mov rdi, r12
    lea rsi, [rsp]
    mov rdx, 64
    call sha256_update
    
    mov rdi, r12
    mov rsi, r12
    mov rdx, 32
    call sha256_update
    
    call sha256_final
    
    ; Copy result
    mov rdi, rsi
    mov rsi, r12
    mov rcx, 32
    rep movsb
    
    pop r12
    pop rbx
    
    leave
    ret

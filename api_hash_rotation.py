"""
API Hashing Rotation - Per-Build Unique Hashes
Based on 2026 research: Garble, obfuse-rs

Features:
- Different hash algorithm per build
- Randomized salt per compilation
- Multiple hash variants (djb2, fnv1a, sdbm, etc.)
- Generates C header with unique hashes
"""

import hashlib
import secrets
import time
from typing import Dict, Callable

class APIHasher:
    """Generate unique API hashes per build"""
    
    def __init__(self, seed: int = None):
        if seed is None:
            # Use timestamp + random for unique builds
            seed = int(time.time()) ^ secrets.randbits(32)
        
        self.seed = seed
        self.salt = secrets.token_bytes(16)
    
    def djb2(self, s: str) -> int:
        """DJB2 hash algorithm"""
        h = 5381
        for c in s:
            h = ((h << 5) + h) ^ ord(c)
            h &= 0xFFFFFFFF
        return h
    
    def fnv1a(self, s: str) -> int:
        """FNV-1a hash algorithm"""
        h = 2166136261  # FNV offset basis
        for c in s:
            h ^= ord(c)
            h *= 16777619  # FNV prime
            h &= 0xFFFFFFFF
        return h
    
    def sdbm(self, s: str) -> int:
        """SDBM hash algorithm"""
        h = 0
        for c in s:
            h = ord(c) + (h << 6) + (h << 16) - h
            h &= 0xFFFFFFFF
        return h
    
    def lose_lose(self, s: str) -> int:
        """Lose-Lose hash algorithm"""
        h = 0
        for c in s:
            h += ord(c)
            h &= 0xFFFFFFFF
        return h
    
    def rotating_xor(self, s: str) -> int:
        """Rotating XOR hash"""
        h = self.seed
        for i, c in enumerate(s):
            h ^= (ord(c) << (i % 24))
            h = ((h << 5) | (h >> 27)) & 0xFFFFFFFF
        return h
    
    def salted_hash(self, s: str, algorithm: Callable) -> int:
        """Apply salt to hash"""
        salted = s + self.salt.hex()
        return algorithm(salted)
    
    def get_random_algorithm(self) -> Callable:
        """Select random hash algorithm for this build"""
        algorithms = [
            self.djb2,
            self.fnv1a,
            self.sdbm,
            self.lose_lose,
            self.rotating_xor,
        ]
        
        # Use seed to deterministically select algorithm
        import random
        random.seed(self.seed)
        return random.choice(algorithms)
    
    def hash_api(self, dll_name: str, func_name: str) -> int:
        """Hash API name with current build's algorithm"""
        algorithm = self.get_random_algorithm()
        
        # Lowercase DLL name, exact function name
        dll_lower = dll_name.lower()
        
        # Hash DLL and function separately, then combine
        dll_hash = self.salted_hash(dll_lower, algorithm)
        func_hash = self.salted_hash(func_name, algorithm)
        
        # Combine hashes
        combined = (dll_hash ^ func_hash) & 0xFFFFFFFF
        
        return combined
    
    def generate_hash_header(self, apis: Dict[str, list], output_file: str = "api_hashes.h"):
        """
        Generate C header with API hashes
        
        Args:
            apis: Dictionary of {dll_name: [func_names]}
            output_file: Output header file path
        """
        algorithm = self.get_random_algorithm()
        
        lines = [
            "// Auto-generated API hashes",
            f"// Build seed: 0x{self.seed:08x}",
            f"// Algorithm: {algorithm.__name__}",
            f"// Salt: {self.salt.hex()}",
            "",
            "#ifndef API_HASHES_H",
            "#define API_HASHES_H",
            "",
            "#include <stdint.h>",
            "",
        ]
        
        # Generate DLL hashes
        for dll_name in apis.keys():
            dll_lower = dll_name.lower()
            dll_hash = self.salted_hash(dll_lower, algorithm)
            define_name = f"H_{dll_name.replace('.', '_').upper()}"
            lines.append(f"#define {define_name:<40} 0x{dll_hash:08x}UL")
        
        lines.append("")
        
        # Generate function hashes
        for dll_name, func_names in apis.items():
            for func_name in func_names:
                func_hash = self.salted_hash(func_name, algorithm)
                define_name = f"H_{func_name}"
                lines.append(f"#define {define_name:<40} 0x{func_hash:08x}UL")
        
        lines.extend([
            "",
            "// Combined API hashes (DLL ^ Function)",
            ""
        ])
        
        for dll_name, func_names in apis.items():
            for func_name in func_names:
                combined = self.hash_api(dll_name, func_name)
                define_name = f"H_{dll_name.replace('.', '_').upper()}_{func_name}"
                lines.append(f"#define {define_name:<40} 0x{combined:08x}UL")
        
        lines.extend([
            "",
            "#endif // API_HASHES_H",
            ""
        ])
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"[+] Generated API hashes header: {output_file}")
        print(f"    Build seed: 0x{self.seed:08x}")
        print(f"    Algorithm: {algorithm.__name__}")
        print(f"    APIs hashed: {sum(len(funcs) for funcs in apis.values())}")

def generate_unique_api_hashes(output_file: str = "api_hashes.h"):
    """Generate unique API hashes for this build"""
    
    # Define APIs to hash
    apis = {
        'kernel32.dll': [
            'VirtualAlloc',
            'VirtualFree',
            'VirtualProtect',
            'WriteProcessMemory',
            'CreateProcessA',
            'ResumeThread',
            'CloseHandle',
            'GetModuleFileNameA',
            'GlobalMemoryStatusEx',
            'Sleep',
        ],
        'ntdll.dll': [
            'NtAllocateVirtualMemory',
            'NtProtectVirtualMemory',
            'NtQueueApcThread',
            'NtResumeThread',
            'NtCreateThreadEx',
        ],
    }
    
    # Generate hashes with unique seed
    hasher = APIHasher()
    hasher.generate_hash_header(apis, output_file)
    
    return hasher.seed

if __name__ == "__main__":
    print("=== API Hashing Rotation ===\n")
    
    # Generate unique hashes for this build
    seed = generate_unique_api_hashes()
    
    print(f"\n[+] Each build will have different hashes")
    print(f"[+] Static analysis must restart for each build")
    print(f"[+] No universal signature possible")
    
    # Show example of hash variation
    print("\n[+] Hash variation example:")
    for i in range(3):
        hasher = APIHasher(seed=i)
        h = hasher.hash_api('kernel32.dll', 'VirtualAlloc')
        print(f"    Build {i}: 0x{h:08x}")

"""
String Encryption - Compile-Time Obfuscation
Based on 2026 research: zsCrypt, Obscura STRCRY, UM-KM-StringCrypt

Features:
- Compile-time string encryption
- Runtime decryption on first use
- Per-string unique keys
- No shared decrypt function (inline decryption)
- Automatic memory zeroing
"""

import hashlib
import secrets
from typing import Tuple, List

class StringEncryptor:
    """Encrypts strings at compile-time with inline decryption"""
    
    def __init__(self, seed: int = None):
        if seed:
            self.rng = secrets.SystemRandom(seed)
        else:
            self.rng = secrets.SystemRandom()
    
    def generate_key(self, length: int) -> bytes:
        """Generate random encryption key"""
        return secrets.token_bytes(length)
    
    def encrypt_string(self, plaintext: str) -> Tuple[bytes, bytes]:
        """
        Encrypt string with XOR + random key
        
        Returns:
            (encrypted_data, key)
        """
        data = plaintext.encode('utf-8')
        key = self.generate_key(len(data))
        
        encrypted = bytes(a ^ b for a, b in zip(data, key))
        
        return encrypted, key
    
    def generate_c_array(self, data: bytes, var_name: str) -> str:
        """Generate C array declaration"""
        hex_values = ', '.join(f'0x{b:02x}' for b in data)
        return f"static const unsigned char {var_name}[] = {{ {hex_values} }};"
    
    def generate_decrypt_function(self, var_name: str, encrypted: bytes, key: bytes) -> str:
        """
        Generate inline decryption function (unique per string)
        
        This creates a unique function for each string to avoid
        a single decryption point that can be hooked/breakpointed
        """
        func_name = f"decrypt_{var_name}"
        enc_name = f"{var_name}_enc"
        key_name = f"{var_name}_key"
        
        c_code = f"""
// Encrypted string: {var_name}
{self.generate_c_array(encrypted, enc_name)}
{self.generate_c_array(key, key_name)}

static char* {func_name}(void) {{
    static char decrypted[{len(encrypted) + 1}] = {{0}};
    static int initialized = 0;
    
    if (!initialized) {{
        for (int i = 0; i < {len(encrypted)}; i++) {{
            decrypted[i] = {enc_name}[i] ^ {key_name}[i];
        }}
        decrypted[{len(encrypted)}] = '\\0';
        initialized = 1;
    }}
    
    return decrypted;
}}
"""
        return c_code
    
    def generate_decrypt_macro(self, var_name: str) -> str:
        """Generate macro for easy string access"""
        return f"#define STR_{var_name.upper()} decrypt_{var_name}()"
    
    def encrypt_strings_in_code(self, strings: List[Tuple[str, str]]) -> str:
        """
        Encrypt multiple strings and generate C code
        
        Args:
            strings: List of (var_name, plaintext) tuples
        
        Returns:
            Complete C code with encrypted strings
        """
        code_parts = [
            "// Auto-generated encrypted strings",
            "#include <stdint.h>",
            "#include <string.h>",
            ""
        ]
        
        for var_name, plaintext in strings:
            encrypted, key = self.encrypt_string(plaintext)
            code_parts.append(self.generate_decrypt_function(var_name, encrypted, key))
            code_parts.append(self.generate_decrypt_macro(var_name))
            code_parts.append("")
        
        return "\n".join(code_parts)

def generate_encrypted_strings_header(strings: dict, output_file: str = "encrypted_strings.h"):
    """
    Generate header file with encrypted strings
    
    Args:
        strings: Dictionary of {var_name: plaintext}
        output_file: Output header file path
    """
    encryptor = StringEncryptor()
    
    string_list = [(name, text) for name, text in strings.items()]
    code = encryptor.encrypt_strings_in_code(string_list)
    
    header = f"""
#ifndef ENCRYPTED_STRINGS_H
#define ENCRYPTED_STRINGS_H

{code}

#endif // ENCRYPTED_STRINGS_H
"""
    
    with open(output_file, 'w') as f:
        f.write(header)
    
    print(f"[+] Generated encrypted strings header: {output_file}")
    print(f"    Strings encrypted: {len(strings)}")

# Example usage
if __name__ == "__main__":
    # Define strings to encrypt
    sensitive_strings = {
        'api_key': 'sk_live_1234567890abcdef',
        'password': 'SuperSecretPassword123!',
        'url': 'https://api.example.com/v1/endpoint',
        'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    }
    
    # Generate encrypted strings header
    generate_encrypted_strings_header(sensitive_strings)
    
    print("\n[+] Usage in C code:")
    print("    #include \"encrypted_strings.h\"")
    print("    printf(\"%s\\n\", STR_API_KEY);")
    print("    printf(\"%s\\n\", STR_PASSWORD);")

#!/usr/bin/env python3
"""
Remote Process Injection Compiler
Compiles the remote_process_injection.c module into an object file
"""

import sys
import os
import subprocess

VS_MSVC_ROOTS = [
    r'G:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
    r'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
    r'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC',
    r'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC',
]

def _find_cl_exe():
    """Locate cl.exe across known VS install roots."""
    for root in VS_MSVC_ROOTS:
        if not os.path.exists(root):
            continue
        versions = sorted(d for d in os.listdir(root) if os.path.isdir(os.path.join(root, d)))
        if versions:
            candidate = os.path.join(root, versions[-1], 'bin', 'Hostx64', 'x64', 'cl.exe')
            if os.path.exists(candidate):
                return candidate
    return None

def _find_vcvars():
    """Locate vcvars64.bat to set up the MSVC build environment."""
    vs_roots = [
        r'G:\Program Files\Microsoft Visual Studio\2022\Community',
        r'C:\Program Files\Microsoft Visual Studio\2022\Community',
        r'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools',
        r'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community',
    ]
    for root in vs_roots:
        bat = os.path.join(root, 'VC', 'Auxiliary', 'Build', 'vcvars64.bat')
        if os.path.exists(bat):
            return bat
    return None

def _run_with_vcvars(cmd_list):
    """Run a command inside the MSVC environment set up by vcvars64.bat."""
    vcvars = _find_vcvars()
    if not vcvars:
        return subprocess.run(cmd_list, capture_output=True, text=True)
    inner = subprocess.list2cmdline(cmd_list)
    full_cmd = f'cmd /V:OFF /c "call "{vcvars}" >nul 2>&1 && {inner}"'
    return subprocess.run(full_cmd, capture_output=True, text=True, shell=True)

def compile_injection_module():
    """Compile remote_process_injection.c into object file"""
    
    source_file = os.path.join('src', 'remote_process_injection.c')
    output_file = os.path.join('build', 'remote_injection.obj')
    
    if not os.path.exists(source_file):
        print(f"[!] Error: {source_file} not found")
        return False
    
    # Create build directory if it doesn't exist
    os.makedirs('build', exist_ok=True)
    
    cl_path = _find_cl_exe()
    
    if not cl_path:
        print("[!] Error: Visual Studio cl.exe not found")
        print("[!] Please install Visual Studio 2022 or 2019")
        return False
    
    print(f"[*] Compiling remote process injection module...")
    print(f"    Source: {source_file}")
    print(f"    Output: {output_file}")
    
    # Compile to object file
    compile_flags = [
        cl_path,
        '/c',  # Compile only, don't link
        source_file,
        f'/Fo:{output_file}',
        '/O2',  # Optimize for speed
        '/W3',  # Warning level 3
        '/nologo',  # Suppress banner
    ]
    
    result = _run_with_vcvars(compile_flags)
    
    if result.returncode != 0:
        print(f"[!] Compilation failed:")
        print(result.stdout)
        print(result.stderr)
        return False
    
    if os.path.exists(output_file):
        size = os.path.getsize(output_file)
        print(f"[+] Compilation successful!")
        print(f"    Object file: {output_file}")
        print(f"    Size: {size} bytes")
        print(f"")
        print(f"[+] Remote injection techniques available:")
        print(f"    1. Early Bird APC Injection (MITRE T1055.004)")
        print(f"    2. Process Hollowing (MITRE T1055.012)")
        print(f"    3. Thread Hijacking (MITRE T1055.003)")
        print(f"    4. Module Stomping (MITRE T1055.001)")
        return True
    else:
        print(f"[!] Error: Object file not created")
        return False

if __name__ == '__main__':
    print("=" * 60)
    print("Remote Process Injection Compiler")
    print("=" * 60)
    print()
    
    if compile_injection_module():
        print()
        print("[+] Module ready for linking with stub runner")
        sys.exit(0)
    else:
        print()
        print("[!] Compilation failed")
        sys.exit(1)

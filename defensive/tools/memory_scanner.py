
"""
Memory Scanner - Real-time detection of crypter techniques in memory
Detects: RWX regions, PE headers in memory, hollowed processes, injected code
"""
import sys
import os
import ctypes
import struct
from ctypes import wintypes
import psutil
PROCESS_QUERY_INFORMATION = 0x0400
PROCESS_VM_READ = 0x0010
MEM_COMMIT = 0x1000
PAGE_EXECUTE_READWRITE = 0x40
PAGE_EXECUTE_READ = 0x20
PAGE_READWRITE = 0x04
class MEMORY_BASIC_INFORMATION(ctypes.Structure):
    _fields_ = [
        ("BaseAddress", ctypes.c_void_p),
        ("AllocationBase", ctypes.c_void_p),
        ("AllocationProtect", wintypes.DWORD),
        ("RegionSize", ctypes.c_size_t),
        ("State", wintypes.DWORD),
        ("Protect", wintypes.DWORD),
        ("Type", wintypes.DWORD),
    ]
kernel32 = ctypes.windll.kernel32
OpenProcess = kernel32.OpenProcess
VirtualQueryEx = kernel32.VirtualQueryEx
ReadProcessMemory = kernel32.ReadProcessMemory
CloseHandle = kernel32.CloseHandle
class MemoryScanner:
    """Scans process memory for crypter indicators"""
    def __init__(self, pid):
        self.pid = pid
        self.handle = None
        self.findings = []
    def open_process(self):
        """Open process with read permissions"""
        self.handle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, False, self.pid)
        if not self.handle:
            raise Exception(f"Failed to open process {self.pid}")
        return True
    def close_process(self):
        """Close process handle"""
        if self.handle:
            CloseHandle(self.handle)
    def scan_memory_regions(self):
        """Scan all memory regions for suspicious patterns"""
        address = 0
        max_address = 0x7FFFFFFF0000  
        while address < max_address:
            mbi = MEMORY_BASIC_INFORMATION()
            if VirtualQueryEx(self.handle, ctypes.c_void_p(address), ctypes.byref(mbi), ctypes.sizeof(mbi)) == 0:
                break
            if mbi.State == MEM_COMMIT:
                self.check_region(mbi)
            address += mbi.RegionSize
        return self.findings
    def check_region(self, mbi):
        """Check memory region for suspicious indicators"""
        if mbi.Protect == PAGE_EXECUTE_READWRITE:
            self.findings.append({
                'type': 'RWX_MEMORY',
                'severity': 'CRITICAL',
                'address': hex(mbi.BaseAddress),
                'size': mbi.RegionSize,
                'description': 'Executable + Writable memory (DEP bypass indicator)'
            })
        if mbi.Protect in [PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE] and mbi.Type != 0x1000000:  
            buffer = ctypes.create_string_buffer(2)
            bytes_read = ctypes.c_size_t()
            if ReadProcessMemory(self.handle, ctypes.c_void_p(mbi.BaseAddress), buffer, 2, ctypes.byref(bytes_read)):
                if buffer.raw[:2] == b'MZ':
                    self.findings.append({
                        'type': 'PE_IN_MEMORY',
                        'severity': 'HIGH',
                        'address': hex(mbi.BaseAddress),
                        'size': mbi.RegionSize,
                        'description': 'PE header in non-file memory (injected code)'
                    })
        if mbi.Protect == PAGE_EXECUTE_READ and mbi.Type == 0x20000:  
            self.findings.append({
                'type': 'PRIVATE_EXECUTABLE',
                'severity': 'MEDIUM',
                'address': hex(mbi.BaseAddress),
                'size': mbi.RegionSize,
                'description': 'Private executable memory (possible injection)'
            })
    def detect_hollowed_process(self):
        """Detect process hollowing by comparing disk vs memory"""
        try:
            proc = psutil.Process(self.pid)
            exe_path = proc.exe()
            with open(exe_path, 'rb') as f:
                disk_pe = f.read(1024)
            buffer = ctypes.create_string_buffer(1024)
            bytes_read = ctypes.c_size_t()
            base_address = 0x400000
            if ReadProcessMemory(self.handle, ctypes.c_void_p(base_address), buffer, 1024, ctypes.byref(bytes_read)):
                memory_pe = buffer.raw[:bytes_read.value]
                if disk_pe[:64] != memory_pe[:64]:
                    self.findings.append({
                        'type': 'PROCESS_HOLLOWING',
                        'severity': 'CRITICAL',
                        'address': hex(base_address),
                        'description': 'PE header mismatch (process hollowing detected)'
                    })
        except Exception as e:
            pass  
    def scan_for_shellcode(self):
        """Scan for common shellcode patterns"""
        patterns = [
            b'\x64\xa1\x30\x00\x00\x00',  
            b'\x65\x48\x8b\x04\x25\x60',  
            b'\xfc\xe8\x82\x00\x00\x00',  
            b'\x4d\x5a\x90\x00',          
        ]
        address = 0
        max_address = 0x7FFFFFFF0000
        while address < max_address:
            mbi = MEMORY_BASIC_INFORMATION()
            if VirtualQueryEx(self.handle, ctypes.c_void_p(address), ctypes.byref(mbi), ctypes.sizeof(mbi)) == 0:
                break
            if mbi.State == MEM_COMMIT and mbi.Protect in [PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE]:
                buffer = ctypes.create_string_buffer(min(mbi.RegionSize, 4096))
                bytes_read = ctypes.c_size_t()
                if ReadProcessMemory(self.handle, ctypes.c_void_p(mbi.BaseAddress), buffer, len(buffer), ctypes.byref(bytes_read)):
                    data = buffer.raw[:bytes_read.value]
                    for pattern in patterns:
                        if pattern in data:
                            self.findings.append({
                                'type': 'SHELLCODE_PATTERN',
                                'severity': 'HIGH',
                                'address': hex(mbi.BaseAddress),
                                'pattern': pattern.hex(),
                                'description': 'Shellcode pattern detected in executable memory'
                            })
                            break
            address += mbi.RegionSize
def scan_process(pid):
    """Scan a single process"""
    print(f"[*] Scanning process {pid}...")
    scanner = MemoryScanner(pid)
    try:
        scanner.open_process()
        scanner.scan_memory_regions()
        scanner.detect_hollowed_process()
        scanner.scan_for_shellcode()
        if scanner.findings:
            print(f"\n[!] Found {len(scanner.findings)} suspicious indicators:\n")
            for finding in scanner.findings:
                print(f"  [{finding['severity']}] {finding['type']}")
                print(f"    Address: {finding['address']}")
                print(f"    Description: {finding['description']}")
                if 'pattern' in finding:
                    print(f"    Pattern: {finding['pattern']}")
                print()
        else:
            print("[+] No suspicious indicators found")
        return scanner.findings
    except Exception as e:
        print(f"[!] Error: {e}")
        return []
    finally:
        scanner.close_process()
def scan_all_processes():
    """Scan all running processes"""
    print("[*] Scanning all processes...\n")
    total_findings = []
    for proc in psutil.process_iter(['pid', 'name']):
        try:
            pid = proc.info['pid']
            name = proc.info['name']
            if pid in [0, 4]:
                continue
            findings = scan_process(pid)
            if findings:
                total_findings.append({
                    'pid': pid,
                    'name': name,
                    'findings': findings
                })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    print(f"\n[*] Scan complete. Found {len(total_findings)} suspicious processes")
    for result in total_findings:
        print(f"\n  PID {result['pid']} ({result['name']}): {len(result['findings'])} indicators")
def main():
    if len(sys.argv) < 2:
        print("Memory Scanner - Crypter Detection Tool")
        print("\nUsage:")
        print("  python memory_scanner.py --pid <PID>     
        print("  python memory_scanner.py --all           
        print("  python memory_scanner.py --watch         
        return 1
    if sys.argv[1] == '--pid':
        if len(sys.argv) < 3:
            print("[!] Error: PID required")
            return 1
        pid = int(sys.argv[2])
        scan_process(pid)
    elif sys.argv[1] == '--all':
        scan_all_processes()
    elif sys.argv[1] == '--watch':
        print("[*] Starting continuous monitoring (Ctrl+C to stop)...")
        import time
        try:
            while True:
                scan_all_processes()
                print("\n[*] Waiting 60 seconds...")
                time.sleep(60)
        except KeyboardInterrupt:
            print("\n[*] Monitoring stopped")
    else:
        print(f"[!] Unknown option: {sys.argv[1]}")
        return 1
    return 0
if __name__ == '__main__':
    sys.exit(main())

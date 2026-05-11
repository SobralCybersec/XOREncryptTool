#!/usr/bin/env python3
"""
Metadata Spoofing Tool - Adds legitimate metadata to evade ML detection
No external dependencies - uses only struct module

Based on 2026 research and Stack Overflow solutions
"""

import sys
import os
import struct
from datetime import datetime

def modify_pe_timestamp(filename, new_timestamp):
    """
    Modify PE TimeDateStamp field without pefile library
    Based on: https://stackoverflow.com/questions/54286700
    """
    try:
        with open(filename, 'r+b') as f:
            # Check MZ signature
            magic = f.read(2)
            if magic != b'MZ':
                print(f"[!] Not a valid PE file (missing MZ signature)")
                return False
            
            # Get PE offset from DOS header at offset 0x3C (60)
            f.seek(60)
            pe_offset_bytes = f.read(4)
            pe_offset = struct.unpack('<I', pe_offset_bytes)[0]
            
            # Seek to PE signature
            f.seek(pe_offset)
            pe_sig = f.read(4)
            if pe_sig != b'PE\x00\x00':
                print(f"[!] Not a valid PE file (missing PE signature)")
                return False
            
            # TimeDateStamp is at PE_offset + 8
            # (PE signature: 4 bytes, Machine: 2 bytes, NumberOfSections: 2 bytes, then TimeDateStamp: 4 bytes)
            timestamp_offset = pe_offset + 8
            
            # Read current timestamp
            f.seek(timestamp_offset)
            old_timestamp = struct.unpack('<I', f.read(4))[0]
            
            # Write new timestamp
            f.seek(timestamp_offset)
            f.write(struct.pack('<I', new_timestamp))
            
            print(f"[+] Timestamp modified successfully")
            print(f"    Old: {datetime.fromtimestamp(old_timestamp)} ({hex(old_timestamp)})")
            print(f"    New: {datetime.fromtimestamp(new_timestamp)} ({hex(new_timestamp)})")
            
            return True
            
    except Exception as e:
        print(f"[!] Error: {e}")
        return False

def spoof_metadata(input_file, output_file, timestamp_year=2018):
    """Spoof PE metadata to look legitimate"""
    
    # Copy file first
    try:
        with open(input_file, 'rb') as f_in:
            data = f_in.read()
        with open(output_file, 'wb') as f_out:
            f_out.write(data)
    except Exception as e:
        print(f"[!] Error copying file: {e}")
        return False
    
    print(f"[*] Processing: {input_file}")
    print(f"    Output: {output_file}")
    
    # Calculate target timestamp (Jan 1, target_year)
    target_timestamp = int(datetime(timestamp_year, 1, 1).timestamp())
    
    # Modify timestamp
    return modify_pe_timestamp(output_file, target_timestamp)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python metadata_spoof.py <input.exe> <output.exe> [year]")
        print("")
        print("Examples:")
        print("  python metadata_spoof.py malware.exe spoofed.exe 2018")
        print("  python metadata_spoof.py malware.exe spoofed.exe 2015")
        print("")
        print("Note: No external dependencies required!")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    year = int(sys.argv[3]) if len(sys.argv) > 3 else 2018
    
    if spoof_metadata(input_file, output_file, year):
        print(f"\n[+] Success! File ready: {output_file}")
    else:
        print(f"\n[!] Failed to spoof metadata")
        sys.exit(1)

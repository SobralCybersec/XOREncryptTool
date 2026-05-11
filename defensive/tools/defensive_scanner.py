
"""
Defensive Scanner - Comprehensive crypter detection system
Integrates: YARA, entropy analysis, PE analysis, behavioral detection
"""
import sys
import os
import hashlib
import math
import struct
import pefile
import yara
from collections import Counter
class DefensiveScanner:
    """Main scanner class integrating all detection methods"""
    def __init__(self, yara_rules_path='yara_rules/crypter_detection.yar'):
        self.yara_rules_path = yara_rules_path
        self.yara_rules = None
        self.findings = []
        if os.path.exists(yara_rules_path):
            try:
                self.yara_rules = yara.compile(filepath=yara_rules_path)
                print(f"[+] Loaded YARA rules from {yara_rules_path}")
            except Exception as e:
                print(f"[!] Failed to load YARA rules: {e}")
    def scan_file(self, file_path):
        """Comprehensive file scan"""
        print(f"\n[*] Scanning: {file_path}\n")
        if not os.path.exists(file_path):
            print(f"[!] File not found: {file_path}")
            return False
        with open(file_path, 'rb') as f:
            data = f.read()
        self.check_entropy(data)
        self.check_pe_structure(file_path)
        self.check_yara_rules(file_path)
        self.check_strings(data)
        self.check_imports(file_path)
        self.check_sections(file_path)
        self.report_findings()
        return len(self.findings) > 0
    def check_entropy(self, data):
        """Calculate entropy (high entropy = encrypted)"""
        if len(data) == 0:
            return
        entropy = 0
        counter = Counter(data)
        for count in counter.values():
            p = count / len(data)
            entropy -= p * math.log2(p)
        print(f"[*] Entropy: {entropy:.2f}")
        if entropy > 7.5:
            self.add_finding('HIGH_ENTROPY', 'HIGH', 
                           f'High entropy detected ({entropy:.2f}) - likely encrypted')
        elif entropy > 7.0:
            self.add_finding('MEDIUM_ENTROPY', 'MEDIUM',
                           f'Medium-high entropy ({entropy:.2f}) - possibly packed')
    def check_pe_structure(self, file_path):
        """Analyze PE structure for anomalies"""
        try:
            pe = pefile.PE(file_path)
            timestamp = pe.FILE_HEADER.TimeDateStamp
            if 1514764800 <= timestamp <= 1546300799:  
                self.add_finding('TIMESTAMP_SPOOFING', 'LOW',
                               'Timestamp set to 2018 (common evasion technique)')
            overlay_offset = pe.get_overlay_data_start_offset()
            if overlay_offset:
                overlay_size = len(pe.__data__) - overlay_offset
                if overlay_size > 1000:
                    self.add_finding('LARGE_OVERLAY', 'MEDIUM',
                                   f'Large overlay detected ({overlay_size} bytes)')
            ep = pe.OPTIONAL_HEADER.AddressOfEntryPoint
            ep_section = None
            for section in pe.sections:
                if section.VirtualAddress <= ep < section.VirtualAddress + section.Misc_VirtualSize:
                    ep_section = section.Name.decode().rstrip('\x00')
                    break
            if ep_section and ep_section not in ['.text', 'CODE']:
                self.add_finding('SUSPICIOUS_ENTRY_POINT', 'HIGH',
                               f'Entry point in unusual section: {ep_section}')
            pe.close()
        except Exception as e:
            print(f"[!] PE analysis failed: {e}")
    def check_yara_rules(self, file_path):
        """Run YARA rules"""
        if not self.yara_rules:
            return
        try:
            matches = self.yara_rules.match(file_path)
            if matches:
                print(f"\n[!] YARA Matches: {len(matches)}\n")
                for match in matches:
                    severity = match.meta.get('severity', 'MEDIUM').upper()
                    description = match.meta.get('description', match.rule)
                    self.add_finding(f'YARA_{match.rule}', severity, description)
                    print(f"  Rule: {match.rule}")
                    print(f"  Severity: {severity}")
                    print(f"  Description: {description}")
                    if match.strings:
                        print(f"  Matched strings: {len(match.strings)}")
                    print()
            else:
                print("[+] No YARA matches")
        except Exception as e:
            print(f"[!] YARA scan failed: {e}")
    def check_strings(self, data):
        """Extract and analyze strings"""
        strings = []
        current = b''
        for byte in data:
            if 32 <= byte <= 126:  
                current += bytes([byte])
            else:
                if len(current) >= 4:
                    strings.append(current.decode('ascii'))
                current = b''
        suspicious_keywords = [
            'VirtualAlloc', 'VirtualProtect', 'WriteProcessMemory',
            'CreateRemoteThread', 'NtQueueApcThread', 'NtUnmapViewOfSection',
            'kernel32', 'ntdll', 'MEMFLUC', 'SELFMOD', 'xorcrypt'
        ]
        found_keywords = []
        for keyword in suspicious_keywords:
            if any(keyword.lower() in s.lower() for s in strings):
                found_keywords.append(keyword)
        if found_keywords:
            self.add_finding('SUSPICIOUS_STRINGS', 'MEDIUM',
                           f'Found suspicious strings: {", ".join(found_keywords)}')
    def check_imports(self, file_path):
        """Analyze import table"""
        try:
            pe = pefile.PE(file_path)
            if not hasattr(pe, 'DIRECTORY_ENTRY_IMPORT'):
                self.add_finding('NO_IMPORTS', 'CRITICAL',
                               'No import table (PEB walk likely used)')
                pe.close()
                return
            import_count = 0
            suspicious_apis = []
            for entry in pe.DIRECTORY_ENTRY_IMPORT:
                dll_name = entry.dll.decode()
                for imp in entry.imports:
                    import_count += 1
                    if imp.name:
                        api_name = imp.name.decode()
                        if api_name in ['VirtualAlloc', 'VirtualProtect', 'WriteProcessMemory',
                                       'CreateRemoteThread', 'NtAllocateVirtualMemory',
                                       'NtProtectVirtualMemory', 'NtQueueApcThread']:
                            suspicious_apis.append(api_name)
            print(f"[*] Imports: {import_count} functions")
            if import_count < 5:
                self.add_finding('FEW_IMPORTS', 'HIGH',
                               f'Very few imports ({import_count}) - possible PEB walk')
            if suspicious_apis:
                self.add_finding('SUSPICIOUS_APIS', 'HIGH',
                               f'Suspicious APIs imported: {", ".join(suspicious_apis)}')
            pe.close()
        except Exception as e:
            print(f"[!] Import analysis failed: {e}")
    def check_sections(self, file_path):
        """Analyze PE sections"""
        try:
            pe = pefile.PE(file_path)
            print(f"\n[*] Sections:")
            for section in pe.sections:
                name = section.Name.decode().rstrip('\x00')
                size = section.SizeOfRawData
                entropy = section.get_entropy()
                print(f"  {name:10s} Size: {size:8d}  Entropy: {entropy:.2f}")
                if entropy > 7.5 and size > 10000:
                    self.add_finding('HIGH_ENTROPY_SECTION', 'HIGH',
                                   f'Section {name} has high entropy ({entropy:.2f})')
                if name not in ['.text', '.data', '.rdata', '.rsrc', '.reloc', '.idata']:
                    self.add_finding('UNUSUAL_SECTION', 'LOW',
                                   f'Unusual section name: {name}')
            pe.close()
        except Exception as e:
            print(f"[!] Section analysis failed: {e}")
    def add_finding(self, finding_type, severity, description):
        """Add a finding to the report"""
        self.findings.append({
            'type': finding_type,
            'severity': severity,
            'description': description
        })
    def report_findings(self):
        """Generate final report"""
        if not self.findings:
            print("\n[+] No suspicious indicators found")
            return
        print(f"\n{'='*70}")
        print(f"DETECTION REPORT - {len(self.findings)} FINDINGS")
        print(f"{'='*70}\n")
        critical = [f for f in self.findings if f['severity'] == 'CRITICAL']
        high = [f for f in self.findings if f['severity'] == 'HIGH']
        medium = [f for f in self.findings if f['severity'] == 'MEDIUM']
        low = [f for f in self.findings if f['severity'] == 'LOW']
        for severity, findings in [('CRITICAL', critical), ('HIGH', high), 
                                   ('MEDIUM', medium), ('LOW', low)]:
            if findings:
                print(f"[{severity}] {len(findings)} findings:")
                for finding in findings:
                    print(f"  - {finding['type']}: {finding['description']}")
                print()
        if critical or len(high) >= 3:
            verdict = "MALICIOUS - High confidence crypter detected"
        elif high or len(medium) >= 5:
            verdict = "SUSPICIOUS - Likely packed/obfuscated"
        else:
            verdict = "POTENTIALLY SUSPICIOUS - Further analysis recommended"
        print(f"{'='*70}")
        print(f"VERDICT: {verdict}")
        print(f"{'='*70}\n")
def main():
    if len(sys.argv) < 2:
        print("Defensive Scanner - Comprehensive Crypter Detection")
        print("\nUsage:")
        print("  python defensive_scanner.py <file>")
        print("  python defensive_scanner.py --batch <directory>")
        print("\nFeatures:")
        print("  - YARA rule matching")
        print("  - Entropy analysis")
        print("  - PE structure analysis")
        print("  - Import table analysis")
        print("  - String extraction")
        print("  - Section analysis")
        return 1
    scanner = DefensiveScanner()
    if sys.argv[1] == '--batch':
        if len(sys.argv) < 3:
            print("[!] Directory path required")
            return 1
        directory = sys.argv[2]
        if not os.path.isdir(directory):
            print(f"[!] Not a directory: {directory}")
            return 1
        print(f"[*] Batch scanning directory: {directory}\n")
        for filename in os.listdir(directory):
            file_path = os.path.join(directory, filename)
            if os.path.isfile(file_path):
                scanner.scan_file(file_path)
                scanner.findings = []  
    else:
        file_path = sys.argv[1]
        scanner.scan_file(file_path)
    return 0
if __name__ == '__main__':
    sys.exit(main())

# Defensive Anti-Crypter System - Installation & Usage Guide

## Quick Start

### 1. Install Dependencies

```bash
# Python dependencies
pip install psutil pefile yara-python

# Sysmon (Windows)
# Download from: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
```

### 2. Run Quick Scan

```bash
# Scan a suspicious file
python defensive\tools\defensive_scanner.py suspicious.exe

# Scan a directory
python defensive\tools\defensive_scanner.py --batch C:\Temp\samples

# Scan process memory
python defensive\tools\memory_scanner.py --pid 1234

# Monitor behavior
python defensive\tools\behavioral_monitor.py --test
```

## Detection Methods

### Static Analysis

**1. YARA Rules**
```bash
# Test YARA rules
yara defensive\yara_rules\crypter_detection.yar suspicious.exe

# Scan directory
yara -r defensive\yara_rules\crypter_detection.yar C:\Temp\samples
```

**2. Entropy Analysis**
- Entropy > 7.5 = Encrypted payload
- Entropy 7.0-7.5 = Packed/compressed
- Entropy < 7.0 = Normal executable

**3. PE Structure**
- Timestamp spoofing (2018)
- Large overlay sections
- Unusual entry point
- High-entropy sections

### Dynamic Analysis

**1. Memory Scanning**
```bash
# Scan specific process
python defensive\tools\memory_scanner.py --pid 1234

# Scan all processes
python defensive\tools\memory_scanner.py --all

# Continuous monitoring
python defensive\tools\memory_scanner.py --watch
```

Detects:
- RWX memory pages
- PE headers in non-file memory
- Hollowed processes
- Shellcode patterns

**2. Behavioral Monitoring**
```bash
# Start monitoring
python defensive\tools\behavioral_monitor.py --watch

# Test with simulated data
python defensive\tools\behavioral_monitor.py --test
```

Detects:
- Process injection sequences
- APC injection
- Memory fluctuation (RW ↔ RX)
- PEB walk patterns

### EDR Integration

**1. Sysmon**
```bash
# Install Sysmon with config
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml

# View events
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100

# Filter by Event ID
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Where-Object {$_.Id -eq 8}
```

**2. Sigma Rules (SIEM)**
```bash
# Convert to Splunk
sigmac -t splunk defensive\edr_integration\sigma_rules.yml

# Convert to Elastic
sigmac -t es-qs defensive\edr_integration\sigma_rules.yml

# Convert to QRadar
sigmac -t qradar defensive\edr_integration\sigma_rules.yml
```

## Detection Techniques by Crypter Feature

### Multi-Layer Encryption (XOR + RC4 + ChaCha20)
**Detection:**
- YARA rule: `Crypter_MultiLayer_Encryption`
- High entropy (>7.5)
- ChaCha20 constants in binary

**Indicators:**
- XOR loop patterns
- RC4 key scheduling
- "expand 32-byte k" string

### PEB Walk API Resolution
**Detection:**
- YARA rule: `Crypter_PEB_Walk_API_Resolution`
- Very few imports (<5)
- PEB access patterns (gs:[0x60])

**Indicators:**
- DJB2 hash constants
- LDR_DATA_TABLE_ENTRY traversal
- Export Address Table parsing

### NtQueueApcThread Injection
**Detection:**
- YARA rule: `Crypter_NtQueueApcThread_Injection`
- Sysmon Event ID 8 (CreateRemoteThread)
- Sigma rule: `APC Injection via NtQueueApcThread`

**Indicators:**
- CREATE_SUSPENDED flag
- NtQueueApcThread call
- NtResumeThread call

### Memory Fluctuation (RW ↔ RX)
**Detection:**
- YARA rule: `Crypter_Memory_Fluctuation`
- Behavioral monitor: RW → RX transitions
- Sigma rule: `Memory Protection Change RW to RX`

**Indicators:**
- Sleep hook patterns
- VirtualProtect calls (PAGE_READWRITE → PAGE_EXECUTE_READ)
- "MEMFLUC" marker string

### Polymorphic Engine
**Detection:**
- YARA rule: `Crypter_Polymorphic_Engine`
- Multiple junk code patterns
- Register randomization

**Indicators:**
- NOP sleds
- Instruction substitution
- Register shuffling

## Real-World Usage Examples

### Example 1: Scan Suspicious Email Attachment
```bash
# Extract attachment
# attachment.exe

# Run comprehensive scan
python defensive\tools\defensive_scanner.py attachment.exe

# If detected, analyze memory
# (if already executed)
python defensive\tools\memory_scanner.py --all
```

### Example 2: Investigate Running Process
```bash
# Find suspicious process
tasklist | findstr "suspicious"

# Scan process memory
python defensive\tools\memory_scanner.py --pid 1234

# Check Sysmon logs
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | 
    Where-Object {$_.Id -eq 10 -and $_.Properties[0].Value -eq 1234}
```

### Example 3: Hunt for Crypters in Network
```bash
# Scan all executables in Downloads
python defensive\tools\defensive_scanner.py --batch C:\Users\*\Downloads

# Monitor for injection attempts
python defensive\tools\behavioral_monitor.py --watch

# Query SIEM for Sigma rule matches
# (use converted Sigma rules)
```

## Performance Tuning

### YARA Rules
- Disable unused rules for faster scanning
- Use `--fast-scan` for quick checks
- Limit file size with `--max-filesize`

### Memory Scanner
- Adjust scan interval (default: 60s)
- Filter by process name
- Skip system processes

### Behavioral Monitor
- Reduce API call history (default: 20)
- Adjust sequence matching threshold
- Filter false positives

## False Positive Handling

### Common False Positives

**1. JIT Compilers (.NET, Java)**
- Legitimate RWX memory
- Frequent VirtualProtect calls
- **Solution:** Whitelist known JIT processes

**2. Legitimate Packers (UPX, ASPack)**
- High entropy
- Unusual entry point
- **Solution:** Check digital signature

**3. Security Software**
- Process injection (legitimate)
- LSASS access
- **Solution:** Whitelist by path (C:\Program Files\)

### Whitelisting
```python
# In defensive_scanner.py
WHITELIST = [
    'C:\\Program Files\\',
    'C:\\Windows\\System32\\',
    'devenv.exe',  # Visual Studio
    'java.exe',    # Java JIT
]
```

## Integration with Existing Security Stack

### SIEM Integration
1. Export Sysmon logs to SIEM
2. Import Sigma rules (converted)
3. Create dashboards for crypter indicators
4. Set up alerting thresholds

### EDR Integration
1. Deploy Sysmon configuration
2. Enable process memory scanning
3. Configure behavioral rules
4. Integrate with SOAR for automated response

### Threat Intelligence
1. Export IOCs (hashes, IPs, domains)
2. Share YARA rules with community
3. Update rules based on new samples
4. Correlate with external threat feeds

## Troubleshooting

### YARA Rules Not Loading
```bash
# Check syntax
yara -w defensive\yara_rules\crypter_detection.yar

# Test individual rules
yara -s defensive\yara_rules\crypter_detection.yar test.exe
```

### Memory Scanner Access Denied
```bash
# Run as Administrator
# Or adjust process permissions
```

### Sysmon Not Logging
```bash
# Check service status
sc query Sysmon64

# Verify configuration
sysmon64.exe -c

# Reinstall if needed
sysmon64.exe -u
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
```

## Advanced Usage

### Custom YARA Rules
```yara
rule Custom_Crypter_Detection
{
    meta:
        description = "Custom rule for specific crypter variant"
        author = "Your Name"
        
    strings:
        $custom1 = { 48 8B 05 ?? ?? ?? ?? }
        $custom2 = "unique_string"
        
    condition:
        uint16(0) == 0x5A4D and
        all of them
}
```

### Custom Behavioral Rules
```python
# In behavioral_monitor.py
CUSTOM_SEQUENCES = {
    'MY_CRYPTER': [
        'CustomAPI1',
        'CustomAPI2',
        'CustomAPI3'
    ]
}
```

## Resources

### Documentation
- MITRE ATT&CK: https://attack.mitre.org/
- YARA Documentation: https://yara.readthedocs.io/
- Sysmon Documentation: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- Sigma Rules: https://github.com/SigmaHQ/sigma

### Tools
- PE-sieve: https://github.com/hasherezade/pe-sieve
- Moneta: https://github.com/forrest-orr/moneta
- Volatility: https://github.com/volatilityfoundation/volatility3
- Velociraptor: https://github.com/Velocidex/velociraptor

### Research Papers
- Memory Fluctuation (2026): https://github.com/Uwmtor/Shellcode-Memory-Fluctuation
- Polymorphic Malware Detection (2025): arXiv:2511.21764
- Process Injection Techniques: https://www.elastic.co/blog/ten-process-injection-techniques

## Support

For issues, questions, or contributions:
- GitHub Issues: [your-repo]/issues
- Email: security@example.com

## License

This defensive system is provided for educational and research purposes only.
Use responsibly and in accordance with applicable laws.

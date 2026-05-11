
"""
Behavioral Monitor - Real-time detection of crypter behavior patterns
Monitors: API sequences, memory protection changes, thread creation, syscalls
"""
import sys
import time
import ctypes
from ctypes import wintypes
import threading
from collections import defaultdict, deque
SUSPICIOUS_SEQUENCES = {
    'PROCESS_INJECTION': [
        'VirtualAllocEx',
        'WriteProcessMemory',
        'CreateRemoteThread'
    ],
    'APC_INJECTION': [
        'NtAllocateVirtualMemory',
        'NtWriteVirtualMemory',
        'NtQueueApcThread'
    ],
    'PROCESS_HOLLOWING': [
        'CreateProcess',  
        'NtUnmapViewOfSection',
        'VirtualAllocEx',
        'WriteProcessMemory',
        'SetThreadContext',
        'ResumeThread'
    ],
    'MEMORY_FLUCTUATION': [
        'VirtualProtect',  
        'Sleep',
        'VirtualProtect',  
    ],
    'PEB_WALK': [
        '__readgsqword',  
        'GetProcAddress',  
    ]
}
PROTECTION_FLAGS = {
    0x01: 'PAGE_NOACCESS',
    0x02: 'PAGE_READONLY',
    0x04: 'PAGE_READWRITE',
    0x08: 'PAGE_WRITECOPY',
    0x10: 'PAGE_EXECUTE',
    0x20: 'PAGE_EXECUTE_READ',
    0x40: 'PAGE_EXECUTE_READWRITE',
    0x80: 'PAGE_EXECUTE_WRITECOPY',
}
class BehavioralMonitor:
    """Monitors process behavior for crypter indicators"""
    def __init__(self):
        self.api_calls = defaultdict(lambda: deque(maxlen=20))  
        self.memory_changes = defaultdict(list)
        self.thread_creations = defaultdict(list)
        self.alerts = []
        self.running = False
    def log_api_call(self, pid, api_name, args=None):
        """Log API call for a process"""
        timestamp = time.time()
        self.api_calls[pid].append({
            'api': api_name,
            'args': args,
            'timestamp': timestamp
        })
        self.check_sequences(pid)
    def log_memory_change(self, pid, address, old_protect, new_protect):
        """Log memory protection change"""
        timestamp = time.time()
        self.memory_changes[pid].append({
            'address': address,
            'old_protect': old_protect,
            'new_protect': new_protect,
            'timestamp': timestamp
        })
        self.check_memory_fluctuation(pid)
    def log_thread_creation(self, pid, tid, start_address):
        """Log thread creation"""
        timestamp = time.time()
        self.thread_creations[pid].append({
            'tid': tid,
            'start_address': start_address,
            'timestamp': timestamp
        })
        if start_address != 0:  
            self.create_alert(pid, 'REMOTE_THREAD', 'HIGH', 
                            f'Remote thread created at {hex(start_address)}')
    def check_sequences(self, pid):
        """Check for suspicious API call sequences"""
        recent_calls = [call['api'] for call in self.api_calls[pid]]
        for sequence_name, sequence in SUSPICIOUS_SEQUENCES.items():
            if self.sequence_matches(recent_calls, sequence):
                self.create_alert(pid, sequence_name, 'CRITICAL',
                                f'Detected {sequence_name} sequence: {" -> ".join(sequence)}')
    def sequence_matches(self, calls, sequence):
        """Check if API calls match a suspicious sequence"""
        if len(calls) < len(sequence):
            return False
        seq_idx = 0
        for call in calls:
            if call == sequence[seq_idx]:
                seq_idx += 1
                if seq_idx == len(sequence):
                    return True
        return False
    def check_memory_fluctuation(self, pid):
        """Check for memory fluctuation patterns (RW ↔ RX)"""
        changes = self.memory_changes[pid]
        if len(changes) < 2:
            return
        for i in range(len(changes) - 1):
            curr = changes[i]
            next_change = changes[i + 1]
            if curr['address'] == next_change['address']:
                if (curr['new_protect'] == 0x04 and  
                    next_change['new_protect'] == 0x20):  
                    time_diff = next_change['timestamp'] - curr['timestamp']
                    self.create_alert(pid, 'MEMORY_FLUCTUATION', 'CRITICAL',
                                    f'RW -> RX transition at {hex(curr["address"])} '
                                    f'(interval: {time_diff:.2f}s)')
    def create_alert(self, pid, alert_type, severity, description):
        """Create a new alert"""
        alert = {
            'pid': pid,
            'type': alert_type,
            'severity': severity,
            'description': description,
            'timestamp': time.time()
        }
        self.alerts.append(alert)
        self.print_alert(alert)
    def print_alert(self, alert):
        """Print alert to console"""
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(alert['timestamp']))
        print(f"\n[{alert['severity']}] {timestamp}")
        print(f"  PID: {alert['pid']}")
        print(f"  Type: {alert['type']}")
        print(f"  Description: {alert['description']}")
    def get_statistics(self):
        """Get monitoring statistics"""
        return {
            'monitored_processes': len(self.api_calls),
            'total_api_calls': sum(len(calls) for calls in self.api_calls.values()),
            'total_memory_changes': sum(len(changes) for changes in self.memory_changes.values()),
            'total_thread_creations': sum(len(threads) for threads in self.thread_creations.values()),
            'total_alerts': len(self.alerts),
            'alerts_by_severity': {
                'CRITICAL': len([a for a in self.alerts if a['severity'] == 'CRITICAL']),
                'HIGH': len([a for a in self.alerts if a['severity'] == 'HIGH']),
                'MEDIUM': len([a for a in self.alerts if a['severity'] == 'MEDIUM']),
            }
        }
monitor = BehavioralMonitor()
def hook_api_calls():
    """Hook Windows API calls (simplified - requires proper hooking library)"""
    print("[*] API hooking not implemented in this demo")
    print("[*] In production, use:")
    print("    - Frida for dynamic instrumentation")
    print("    - Detours for API hooking")
    print("    - ETW (Event Tracing for Windows)")
    print("    - Sysmon for system-wide monitoring")
def simulate_detection():
    """Simulate detection of crypter behavior (for testing)"""
    print("\n[*] Simulating crypter behavior detection...\n")
    pid = 1234
    monitor.log_api_call(pid, 'VirtualAllocEx', {'size': 4096, 'protect': 'PAGE_READWRITE'})
    time.sleep(0.1)
    monitor.log_api_call(pid, 'WriteProcessMemory', {'size': 4096})
    time.sleep(0.1)
    monitor.log_api_call(pid, 'CreateRemoteThread', {'start_address': 0x10000})
    pid = 5678
    monitor.log_memory_change(pid, 0x20000, 0x04, 0x20)  
    time.sleep(1.0)
    monitor.log_memory_change(pid, 0x20000, 0x20, 0x04)  
    pid = 9012
    monitor.log_api_call(pid, 'NtAllocateVirtualMemory')
    time.sleep(0.1)
    monitor.log_api_call(pid, 'NtWriteVirtualMemory')
    time.sleep(0.1)
    monitor.log_api_call(pid, 'NtQueueApcThread')
def print_statistics():
    """Print monitoring statistics"""
    stats = monitor.get_statistics()
    print("\n" + "="*60)
    print("MONITORING STATISTICS")
    print("="*60)
    print(f"Monitored Processes: {stats['monitored_processes']}")
    print(f"Total API Calls: {stats['total_api_calls']}")
    print(f"Total Memory Changes: {stats['total_memory_changes']}")
    print(f"Total Thread Creations: {stats['total_thread_creations']}")
    print(f"\nTotal Alerts: {stats['total_alerts']}")
    print(f"  CRITICAL: {stats['alerts_by_severity']['CRITICAL']}")
    print(f"  HIGH: {stats['alerts_by_severity']['HIGH']}")
    print(f"  MEDIUM: {stats['alerts_by_severity']['MEDIUM']}")
    print("="*60 + "\n")
def main():
    if len(sys.argv) < 2:
        print("Behavioral Monitor - Crypter Detection Tool")
        print("\nUsage:")
        print("  python behavioral_monitor.py --watch      
        print("  python behavioral_monitor.py --test       
        print("\nNote: Real-time API hooking requires additional libraries (Frida, Detours)")
        print("      Use with Sysmon for production monitoring")
        return 1
    if sys.argv[1] == '--watch':
        print("[*] Starting behavioral monitoring...")
        print("[!] Note: This demo uses Sysmon integration")
        print("[*] Install Sysmon with provided config for full monitoring")
        hook_api_calls()
        try:
            while True:
                time.sleep(10)
                print_statistics()
        except KeyboardInterrupt:
            print("\n[*] Monitoring stopped")
            print_statistics()
    elif sys.argv[1] == '--test':
        simulate_detection()
        time.sleep(2)
        print_statistics()
    else:
        print(f"[!] Unknown option: {sys.argv[1]}")
        return 1
    return 0
if __name__ == '__main__':
    sys.exit(main())

